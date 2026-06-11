"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.hexToRgb = hexToRgb;
exports.colorDelta = colorDelta;
exports.analyzePhoto = analyzePhoto;
const sharp_1 = __importDefault(require("sharp"));
const env_1 = require("../config/env");
// Dominant colour (k-means, 2 clusters → larger) + luminance variance, in one
// pass over a 64×64 thumbnail.
async function analyzeThumb(imageBuffer) {
    const { data, info } = await (0, sharp_1.default)(imageBuffer)
        .resize(64, 64, { fit: 'cover' })
        .removeAlpha()
        .raw()
        .toBuffer({ resolveWithObject: true });
    const pixels = info.width * info.height;
    // 2-cluster k-means to isolate the dominant subject colour.
    let r1 = data[0], g1 = data[1], b1 = data[2];
    let r2 = data[data.length - 3], g2 = data[data.length - 2], b2 = data[data.length - 1];
    for (let iter = 0; iter < 8; iter++) {
        let sr1 = 0, sg1 = 0, sb1 = 0, n1 = 0;
        let sr2 = 0, sg2 = 0, sb2 = 0, n2 = 0;
        for (let i = 0; i < data.length; i += 3) {
            const r = data[i], g = data[i + 1], b = data[i + 2];
            const d1 = (r - r1) ** 2 + (g - g1) ** 2 + (b - b1) ** 2;
            const d2 = (r - r2) ** 2 + (g - g2) ** 2 + (b - b2) ** 2;
            if (d1 <= d2) {
                sr1 += r;
                sg1 += g;
                sb1 += b;
                n1++;
            }
            else {
                sr2 += r;
                sg2 += g;
                sb2 += b;
                n2++;
            }
        }
        if (n1 > 0) {
            r1 = sr1 / n1;
            g1 = sg1 / n1;
            b1 = sb1 / n1;
        }
        if (n2 > 0) {
            r2 = sr2 / n2;
            g2 = sg2 / n2;
            b2 = sb2 / n2;
        }
    }
    // Larger cluster = dominant subject; plus luminance variance for "richness".
    let n1 = 0, lumSum = 0, lumSq = 0;
    for (let i = 0; i < data.length; i += 3) {
        const r = data[i], g = data[i + 1], b = data[i + 2];
        const d1 = (r - r1) ** 2 + (g - g1) ** 2 + (b - b1) ** 2;
        const d2 = (r - r2) ** 2 + (g - g2) ** 2 + (b - b2) ** 2;
        if (d1 <= d2)
            n1++;
        const lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
        lumSum += lum;
        lumSq += lum * lum;
    }
    const mean = lumSum / pixels;
    const variance = Math.max(0, lumSq / pixels - mean * mean); // 0..~0.25
    const rgb = n1 >= pixels / 2 ? [r1, g1, b1] : [r2, g2, b2];
    return { rgb: [Math.round(rgb[0]), Math.round(rgb[1]), Math.round(rgb[2])], variance };
}
function hexToRgb(hex) {
    const n = parseInt(hex.replace('#', ''), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
function rgbToHex([r, g, b]) {
    const h = (v) => v.toString(16).padStart(2, '0');
    return `#${h(r)}${h(g)}${h(b)}`;
}
// Perceptual colour distance (redmean — approximates CIE76).
function colorDelta(a, b) {
    const rmean = (a[0] + b[0]) / 2;
    const dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
    return Math.sqrt((2 + rmean / 256) * dr * dr +
        4 * dg * dg +
        (2 + (255 - rmean) / 256) * db * db);
}
// Matching laxiste — a photo is NEVER refused; the score only feeds ranking.
async function analyzePhoto(imageBuffer, targetHex) {
    const { rgb, variance } = await analyzeThumb(imageBuffer);
    const deltaE = Math.round(colorDelta(rgb, hexToRgb(targetHex)));
    const verdict = deltaE <= env_1.env.COLOR_DELTA_PERFECT ? 'parfait'
        : deltaE <= env_1.env.COLOR_DELTA_ACCEPT ? 'correct'
            : 'libre';
    // Hue bonus 0..15, then gently dampened for flat "aplat" images (low variance).
    const hueBonus = Math.round(15 * Math.max(0, Math.min(1, (env_1.env.COLOR_DELTA_ACCEPT - deltaE) / env_1.env.COLOR_DELTA_ACCEPT)));
    const flat = variance < 0.012; // empirical threshold for an aplat
    const matchBonus = flat ? Math.round(hueBonus * 0.5) : hueBonus;
    return { dominantHex: rgbToHex(rgb), deltaE, variance: Math.round(variance * 1000) / 1000, verdict, matchBonus };
}
//# sourceMappingURL=color-match.js.map