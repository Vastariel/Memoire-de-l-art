"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.segmentArtwork = segmentArtwork;
exports.evocativeName = evocativeName;
const sharp_1 = __importDefault(require("sharp"));
// ── Segmentation ──────────────────────────────────────────────────────────────
// Target cell count for auto block size calculation.
// Aims for ~2000 cells which gives good detail while keeping zones manageable.
const AUTO_TARGET_CELLS = 2000;
async function segmentArtwork(imageBuffer, numZones = 16) {
    const meta = await (0, sharp_1.default)(imageBuffer).metadata();
    const srcW = meta.width ?? 512;
    const srcH = meta.height ?? 512;
    // Auto block size: target ~2000 cells, preserving aspect ratio
    const blockSize = Math.max(4, Math.round(Math.sqrt(srcW * srcH / AUTO_TARGET_CELLS)));
    // Mosaic grid — no hard cap, let the image and target drive dimensions
    const cols = Math.max(4, Math.round(srcW / blockSize));
    const rows = Math.max(4, Math.round(srcH / blockSize));
    // ── High-res colour sampling ───────────────────────────────────────────────
    // Run k-means on a much higher resolution to get good colour centroids,
    // especially when numZones is large (50–120). The grid (cols×rows) may
    // have fewer pixels than zones, so sampling from the original image at a
    // higher resolution gives far more representative colours.
    const sampleSide = Math.max(cols * 4, Math.min(512, numZones * 12));
    const { data: sampleData } = await (0, sharp_1.default)(imageBuffer)
        .resize(sampleSide, sampleSide, { fit: 'fill' })
        .removeAlpha()
        .raw()
        .toBuffer({ resolveWithObject: true });
    const samplePixels = [];
    for (let i = 0; i < sampleData.length; i += 3) {
        samplePixels.push([sampleData[i], sampleData[i + 1], sampleData[i + 2]]);
    }
    // ── K-means on high-res sample ─────────────────────────────────────────────
    const k = Math.min(numZones, samplePixels.length);
    const initCentroids = kMeanspp(samplePixels, k);
    const { centroids } = kMeansIterate(samplePixels, initCentroids, 40);
    // ── Map mosaic grid pixels to centroids ───────────────────────────────────
    const { data: gridData } = await (0, sharp_1.default)(imageBuffer)
        .resize(cols, rows, { fit: 'fill' })
        .removeAlpha()
        .raw()
        .toBuffer({ resolveWithObject: true });
    const gridPixels = [];
    for (let i = 0; i < gridData.length; i += 3) {
        gridPixels.push([gridData[i], gridData[i + 1], gridData[i + 2]]);
    }
    // Assign each grid pixel to the nearest high-res centroid
    const rawAssignments = new Int32Array(gridPixels.length);
    for (let i = 0; i < gridPixels.length; i++) {
        let best = 0, bestDist = Infinity;
        for (let j = 0; j < centroids.length; j++) {
            const d = distSq(gridPixels[i], centroids[j]);
            if (d < bestDist) {
                bestDist = d;
                best = j;
            }
        }
        rawAssignments[i] = best;
    }
    // ── Build zone list — only keep centroids that appear in the grid ──────────
    const centroidCount = new Map();
    for (let i = 0; i < rawAssignments.length; i++) {
        const j = rawAssignments[i];
        centroidCount.set(j, (centroidCount.get(j) ?? 0) + 1);
    }
    // Sort by cell count ascending (small zones first = fine details)
    const occupied = [...centroidCount.entries()]
        .sort((a, b) => a[1] - b[1]);
    const centroidToZone = new Map();
    const zoneList = [];
    for (let rank = 0; rank < occupied.length; rank++) {
        const [centIdx, count] = occupied[rank];
        const [cr, cg, cb] = centroids[centIdx].map(Math.round);
        const id = `zone-${String(rank + 1).padStart(3, '0')}`;
        centroidToZone.set(centIdx, id);
        zoneList.push({
            id,
            pigment: id,
            label: evocativeName(cr, cg, cb),
            cellCount: count,
            targetHex: rgbToHex(cr, cg, cb),
        });
    }
    // ── Build cell list ────────────────────────────────────────────────────────
    const cells = gridPixels.map((_, idx) => ({
        index: idx,
        col: idx % cols,
        row: Math.floor(idx / cols),
        zoneId: centroidToZone.get(rawAssignments[idx]),
    }));
    return { cols, rows, cells, zones: zoneList };
}
// ── K-means++ initialisation ──────────────────────────────────────────────────
function kMeanspp(pixels, k) {
    const centroids = [pixels[Math.floor(Math.random() * pixels.length)]];
    while (centroids.length < k) {
        const dists = pixels.map(p => Math.min(...centroids.map(c => distSq(p, c))));
        const total = dists.reduce((a, b) => a + b, 0);
        let r = Math.random() * total;
        for (let i = 0; i < dists.length; i++) {
            r -= dists[i];
            if (r <= 0) {
                centroids.push(pixels[i]);
                break;
            }
        }
        if (centroids.length < k && r > 0) {
            centroids.push(pixels[pixels.length - 1]);
        }
    }
    return centroids;
}
function kMeansIterate(pixels, centroids, maxIter) {
    const k = centroids.length;
    const assignments = new Int32Array(pixels.length);
    let cents = centroids.map(c => [...c]);
    for (let iter = 0; iter < maxIter; iter++) {
        let changed = false;
        for (let i = 0; i < pixels.length; i++) {
            let best = 0, bestDist = Infinity;
            for (let j = 0; j < k; j++) {
                const d = distSq(pixels[i], cents[j]);
                if (d < bestDist) {
                    bestDist = d;
                    best = j;
                }
            }
            if (assignments[i] !== best) {
                assignments[i] = best;
                changed = true;
            }
        }
        if (!changed)
            break;
        const sums = Array.from({ length: k }, () => [0, 0, 0, 0]);
        for (let i = 0; i < pixels.length; i++) {
            const j = assignments[i];
            sums[j][0] += pixels[i][0];
            sums[j][1] += pixels[i][1];
            sums[j][2] += pixels[i][2];
            sums[j][3]++;
        }
        for (let j = 0; j < k; j++) {
            const [sr, sg, sb, cnt] = sums[j];
            if (cnt > 0)
                cents[j] = [sr / cnt, sg / cnt, sb / cnt];
        }
    }
    return { centroids: cents, assignments };
}
function distSq(a, b) {
    const dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
    return dr * dr + dg * dg + db * db;
}
function rgbToHex(r, g, b) {
    return '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('');
}
const NAME_TABLE = [
    // Achromatic
    { hMin: 0, hMax: 360, sMin: 0, sMax: 0.10, lMin: 0.88, lMax: 1.00, names: ['Craie blanche', 'Lait de chaux', 'Brume d\'hiver'] },
    { hMin: 0, hMax: 360, sMin: 0, sMax: 0.12, lMin: 0.65, lMax: 0.88, names: ['Pierre calcaire', 'Givre matinal', 'Cendre pâle'] },
    { hMin: 0, hMax: 360, sMin: 0, sMax: 0.12, lMin: 0.38, lMax: 0.65, names: ['Cendre froide', 'Granit poli', 'Brume d\'automne'] },
    { hMin: 0, hMax: 360, sMin: 0, sMax: 0.12, lMin: 0.00, lMax: 0.38, names: ['Encre d\'imprimerie', 'Nuit de forge', 'Ombre profonde'] },
    // Red
    { hMin: 350, hMax: 360, sMin: 0.45, sMax: 1.0, lMin: 0.30, lMax: 0.55, names: ['Sang de bœuf', 'Grenade ouverte', 'Laque de garance'] },
    { hMin: 0, hMax: 15, sMin: 0.55, sMax: 1.0, lMin: 0.30, lMax: 0.52, names: ['Vermillon d\'atelier', 'Brique ancienne', 'Feu couvant'] },
    { hMin: 0, hMax: 15, sMin: 0.45, sMax: 1.0, lMin: 0.52, lMax: 0.72, names: ['Pivoine tardive', 'Coquelicot pâle', 'Rose de Damas'] },
    { hMin: 345, hMax: 360, sMin: 0.45, sMax: 1.0, lMin: 0.45, lMax: 0.70, names: ['Cerise tardive', 'Grenadine', 'Garance rosée'] },
    { hMin: 0, hMax: 20, sMin: 0.15, sMax: 0.50, lMin: 0.28, lMax: 0.52, names: ['Terre de Sienne', 'Bois flotté', 'Argile cuite'] },
    // Orange
    { hMin: 15, hMax: 45, sMin: 0.60, sMax: 1.0, lMin: 0.42, lMax: 0.62, names: ['Safran du marché', 'Braise vive', 'Cuivre battu'] },
    { hMin: 15, hMax: 45, sMin: 0.40, sMax: 0.85, lMin: 0.58, lMax: 0.78, names: ['Abricot mûr', 'Aube d\'été', 'Miel d\'acacia'] },
    { hMin: 20, hMax: 42, sMin: 0.25, sMax: 0.65, lMin: 0.28, lMax: 0.50, names: ['Ocre de carrière', 'Terre brûlée', 'Sable chaud'] },
    { hMin: 25, hMax: 45, sMin: 0.10, sMax: 0.35, lMin: 0.55, lMax: 0.78, names: ['Sable fin', 'Lin naturel', 'Écorce claire'] },
    // Yellow
    { hMin: 45, hMax: 72, sMin: 0.60, sMax: 1.0, lMin: 0.52, lMax: 0.78, names: ['Aube dorée', 'Blé mûr', 'Or des champs'] },
    { hMin: 45, hMax: 72, sMin: 0.45, sMax: 1.0, lMin: 0.38, lMax: 0.55, names: ['Ambre ancien', 'Cire d\'abeille', 'Feuille de tabac'] },
    { hMin: 45, hMax: 72, sMin: 0.25, sMax: 0.55, lMin: 0.62, lMax: 0.85, names: ['Parchemin vieilli', 'Ivoire jauni', 'Lin séché'] },
    { hMin: 48, hMax: 70, sMin: 0.50, sMax: 1.0, lMin: 0.78, lMax: 1.00, names: ['Lumière de midi', 'Citron d\'été', 'Paille fraîche'] },
    // Yellow-green
    { hMin: 72, hMax: 105, sMin: 0.40, sMax: 0.90, lMin: 0.32, lMax: 0.58, names: ['Mousse de forêt', 'Lichen sur pierre', 'Verdure d\'avril'] },
    { hMin: 72, hMax: 105, sMin: 0.30, sMax: 0.70, lMin: 0.52, lMax: 0.72, names: ['Prairie au matin', 'Jeune pousse', 'Pistache claire'] },
    { hMin: 72, hMax: 105, sMin: 0.15, sMax: 0.40, lMin: 0.42, lMax: 0.65, names: ['Sauge pâle', 'Vert de gris', 'Fougère sèche'] },
    // Green
    { hMin: 105, hMax: 150, sMin: 0.45, sMax: 1.0, lMin: 0.22, lMax: 0.42, names: ['Forêt profonde', 'Vieux buis', 'Épicéa sombre'] },
    { hMin: 105, hMax: 150, sMin: 0.40, sMax: 0.90, lMin: 0.32, lMax: 0.52, names: ['Vert véronèse', 'Feuille de lierre', 'Herbe des prés'] },
    { hMin: 105, hMax: 150, sMin: 0.18, sMax: 0.48, lMin: 0.38, lMax: 0.58, names: ['Sauge argentée', 'Eucalyptus pâle', 'Feuille morte'] },
    // Teal
    { hMin: 150, hMax: 192, sMin: 0.42, sMax: 0.90, lMin: 0.28, lMax: 0.52, names: ['Mer du Nord', 'Patine de bronze', 'Malachite ancienne'] },
    { hMin: 150, hMax: 192, sMin: 0.38, sMax: 0.85, lMin: 0.42, lMax: 0.62, names: ['Lagon secret', 'Turquoise pâle', 'Glace arctique'] },
    { hMin: 150, hMax: 192, sMin: 0.15, sMax: 0.42, lMin: 0.48, lMax: 0.68, names: ['Brume marine', 'Menthe séchée', 'Eucalyptus bleu'] },
    // Blue
    { hMin: 192, hMax: 240, sMin: 0.50, sMax: 1.0, lMin: 0.25, lMax: 0.48, names: ['Bleu de Prusse', 'Nuit bleue', 'Denim profond'] },
    { hMin: 192, hMax: 240, sMin: 0.50, sMax: 1.0, lMin: 0.42, lMax: 0.62, names: ['Azur d\'été', 'Cobalt profond', 'Ciel de Provence'] },
    { hMin: 192, hMax: 240, sMin: 0.48, sMax: 1.0, lMin: 0.55, lMax: 0.75, names: ['Bleu porcelaine', 'Horizon lointain', 'Lavande bleue'] },
    { hMin: 192, hMax: 245, sMin: 0.18, sMax: 0.48, lMin: 0.38, lMax: 0.62, names: ['Ardoise mouillée', 'Pierre de lune', 'Gris bleuté'] },
    // Indigo
    { hMin: 240, hMax: 268, sMin: 0.42, sMax: 1.0, lMin: 0.18, lMax: 0.42, names: ['Nuit d\'encre', 'Bleu outremer', 'Minuit profond'] },
    { hMin: 240, hMax: 268, sMin: 0.38, sMax: 0.90, lMin: 0.38, lMax: 0.58, names: ['Iris sauvage', 'Velours indigo', 'Bleu de nuit'] },
    // Violet
    { hMin: 268, hMax: 312, sMin: 0.28, sMax: 0.82, lMin: 0.22, lMax: 0.48, names: ['Prune tardive', 'Ombre d\'aubergine', 'Raisin de Bourgogne'] },
    { hMin: 268, hMax: 312, sMin: 0.28, sMax: 0.80, lMin: 0.42, lMax: 0.62, names: ['Lilas du soir', 'Bruyère sauvage', 'Lavande froide'] },
    { hMin: 268, hMax: 312, sMin: 0.12, sMax: 0.38, lMin: 0.48, lMax: 0.70, names: ['Mauve des champs', 'Parme pâle', 'Gris violet'] },
    // Pink
    { hMin: 312, hMax: 345, sMin: 0.35, sMax: 0.85, lMin: 0.42, lMax: 0.68, names: ['Rose de l\'aube', 'Quartz rosé', 'Pétale ancien'] },
    { hMin: 312, hMax: 345, sMin: 0.38, sMax: 0.90, lMin: 0.30, lMax: 0.52, names: ['Cerise confite', 'Framboise sauvage', 'Magenta doux'] },
    { hMin: 312, hMax: 345, sMin: 0.12, sMax: 0.38, lMin: 0.55, lMax: 0.78, names: ['Poudre de nacre', 'Vieux rose', 'Lilas rosé'] },
];
function rgbToHsl(r, g, b) {
    const rn = r / 255, gn = g / 255, bn = b / 255;
    const max = Math.max(rn, gn, bn), min = Math.min(rn, gn, bn);
    const l = (max + min) / 2;
    if (max === min)
        return [0, 0, l];
    const d = max - min;
    const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    let h;
    if (max === rn)
        h = ((gn - bn) / d + (gn < bn ? 6 : 0)) / 6;
    else if (max === gn)
        h = ((bn - rn) / d + 2) / 6;
    else
        h = ((rn - gn) / d + 4) / 6;
    return [h * 360, s, l];
}
function evocativeName(r, g, b) {
    const [h, s, l] = rgbToHsl(r, g, b);
    for (const e of NAME_TABLE) {
        const hueOk = e.hMin > e.hMax
            ? h >= e.hMin || h <= e.hMax
            : h >= e.hMin && h <= e.hMax;
        if (hueOk && s >= e.sMin && s <= e.sMax && l >= e.lMin && l <= e.lMax) {
            const idx = ((r * 31 + g * 17 + b * 7) >>> 0) % e.names.length;
            return e.names[idx];
        }
    }
    if (l < 0.20)
        return 'Ombre ancienne';
    if (l > 0.80)
        return 'Lumière dorée';
    return 'Teinte naturelle';
}
//# sourceMappingURL=segmentation.js.map