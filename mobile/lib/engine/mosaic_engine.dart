// mosaic_engine.dart — Mémoire de l'art · moteur d'œuvre v2
// ---------------------------------------------------------------------------
// Port Dart de mosaic.jsx. L'œuvre de la semaine est une image PORTRAIT (3:4)
// quantifiée en une multitude de teintes regroupées en 7 FAMILLES (une par jour
// lun→dim). Chaque cellule réfère une VARIANTE (la portion d'un joueur).
//
//   • Vue PLATE (dézoomée) : chaque bloc = sa teinte prédéterminée (fillGradient).
//   • VITRAIL (zoomée)     : les photos brutes apparaissent (photoLayers), une
//     photo se déploie sur les blocs d'une famille, chaque bloc un fragment.
// ---------------------------------------------------------------------------

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

// ── Géométrie portrait 3:4 ──────────────────────────────────────────────────
const int kCols = 12;
const int kRows = 16;

// ── Familles (7) · jour 1 (lundi) → jour 7 (dimanche) ───────────────────────
class FamilyDef {
  final String key;
  final int day;
  final String nameFr;
  final String nameEn;
  final List<String> variants;
  const FamilyDef(this.key, this.day, this.nameFr, this.nameEn, this.variants);
  String name(String lang) => lang == 'en' ? nameEn : nameFr;
}

const Map<String, FamilyDef> kFamilies = {
  'bleus':  FamilyDef('bleus', 1, 'Bleus', 'Blues', ['outremer', 'cobalt', 'azur']),
  'ors':    FamilyDef('ors', 2, 'Ors', 'Golds', ['safran', 'ocre', 'ambre']),
  'verts':  FamilyDef('verts', 3, 'Verts', 'Greens', ['veronese', 'olive', 'sauge']),
  'terres': FamilyDef('terres', 4, 'Terres', 'Earths', ['sienne', 'brulee', 'ombre']),
  'roses':  FamilyDef('roses', 5, 'Roses', 'Roses', ['rose', 'lilas', 'prune']),
  'rouges': FamilyDef('rouges', 6, 'Rouges', 'Reds', ['vermillon', 'garance', 'brique']),
  'gris':   FamilyDef('gris', 7, 'Gris', 'Greys', ['ardoise', 'taupe', 'lin']),
};

// ── Variantes (21) ──────────────────────────────────────────────────────────
class VariantDef {
  final String key;
  final String nameFr;
  final String nameEn;
  final String family;
  const VariantDef(this.key, this.nameFr, this.nameEn, this.family);
  Color get color => MdaColors.pig(key);
  String name(String lang) => lang == 'en' ? nameEn : nameFr;
}

const Map<String, VariantDef> kVariants = {
  'outremer': VariantDef('outremer', 'Outremer', 'Ultramarine', 'bleus'),
  'cobalt': VariantDef('cobalt', 'Cobalt', 'Cobalt', 'bleus'),
  'azur': VariantDef('azur', 'Azur', 'Azure', 'bleus'),
  'safran': VariantDef('safran', 'Safran', 'Saffron', 'ors'),
  'ocre': VariantDef('ocre', 'Ocre', 'Ochre', 'ors'),
  'ambre': VariantDef('ambre', 'Ambre', 'Amber', 'ors'),
  'veronese': VariantDef('veronese', 'Vert véronèse', 'Veronese', 'verts'),
  'olive': VariantDef('olive', 'Olive', 'Olive', 'verts'),
  'sauge': VariantDef('sauge', 'Sauge', 'Sage', 'verts'),
  'sienne': VariantDef('sienne', 'Terre de Sienne', 'Sienna', 'terres'),
  'brulee': VariantDef('brulee', 'Terre brûlée', 'Burnt earth', 'terres'),
  'ombre': VariantDef('ombre', 'Terre d’ombre', 'Umber', 'terres'),
  'rose': VariantDef('rose', 'Rose', 'Rose', 'roses'),
  'lilas': VariantDef('lilas', 'Lilas', 'Lilac', 'roses'),
  'prune': VariantDef('prune', 'Prune', 'Plum', 'roses'),
  'vermillon': VariantDef('vermillon', 'Vermillon', 'Vermilion', 'rouges'),
  'garance': VariantDef('garance', 'Garance', 'Madder', 'rouges'),
  'brique': VariantDef('brique', 'Brique', 'Brick', 'rouges'),
  'ardoise': VariantDef('ardoise', 'Ardoise', 'Slate', 'gris'),
  'taupe': VariantDef('taupe', 'Taupe', 'Taupe', 'gris'),
  'lin': VariantDef('lin', 'Lin', 'Flax', 'gris'),
};

String? familyKeyOfDay(int day) {
  for (final f in kFamilies.values) {
    if (f.day == day) return f.key;
  }
  return null;
}

// ── Cellule + œuvre ─────────────────────────────────────────────────────────
class ArtCell {
  final int i;
  final int col;
  final int row;
  final String family;
  final String variant;
  const ArtCell(this.i, this.col, this.row, this.family, this.variant);
  Color get pig => MdaColors.pig(variant);
}

class ArtworkData {
  final int cols;
  final int rows;
  final List<ArtCell> cells;
  const ArtworkData(this.cols, this.rows, this.cells);

  int countForVariant(String v) => cells.where((c) => c.variant == v).length;
  Iterable<ArtCell> ofVariant(String v) => cells.where((c) => c.variant == v);
}

// ── Maths déterministes (port de mosaic.jsx) ───────────────────────────────
double _frac(double x) => x - x.floorToDouble();
double hash(num i) => _frac(math.sin(i * 127.1) * 43758.5453);

/// pct > 0 → vers le blanc, pct < 0 → vers le noir (port de shade()).
Color shade(Color c, double pct) {
  final t = pct < 0 ? 0.0 : 255.0;
  final p = pct.abs();
  int mix(double v01) {
    final v = v01 * 255.0;
    return ((t - v) * p + v).round().clamp(0, 255);
  }
  return Color.fromARGB(255, mix(c.r), mix(c.g), mix(c.b));
}

// Scène « Le Semeur au soleil couchant ».
const double _sunX = 8.4, _sunY = 4.6;
double _dSun(int col, int row) =>
    math.sqrt(math.pow((col - _sunX) * 0.92, 2) + math.pow((row - _sunY) * 1.12, 2));

String _familyAt(int col, int row) {
  final d = _dSun(col, row);
  if (d < 2.7) return 'ors';
  if (row <= 2) return 'bleus';
  if (row <= 5) return (d < 4.3 && row >= 3) ? 'roses' : 'bleus';
  if (row <= 8) return 'verts';
  if (row <= 11) return hash(col * 3 + row * 7) > 0.5 ? 'terres' : 'verts';
  if (col >= 3 && col <= 6 && row >= 10) return 'gris';
  if (hash(col * 7.3 + row * 3.1) > 0.84) return 'rouges';
  return 'terres';
}

String _variantAt(int col, int row) {
  final fam = _familyAt(col, row);
  final d = _dSun(col, row);
  if (fam == 'ors') return d < 1.5 ? 'safran' : (d < 2.1 ? 'ocre' : 'ambre');
  if (fam == 'bleus') return row <= 1 ? 'outremer' : (row <= 3 ? 'cobalt' : 'azur');
  final vs = kFamilies[fam]!.variants;
  return vs[(hash(col * 5.1 + row * 2.3) * vs.length).floor() % vs.length];
}

ArtworkData buildSemeur() {
  final cells = <ArtCell>[];
  for (var row = 0; row < kRows; row++) {
    for (var col = 0; col < kCols; col++) {
      final v = _variantAt(col, row);
      final f = kVariants[v]!.family;
      cells.add(ArtCell(row * kCols + col, col, row, f, v));
    }
  }
  return ArtworkData(kCols, kRows, cells);
}

/// L'œuvre de référence (mock). Réutilisée partout via [kArtwork].
final ArtworkData kArtwork = buildSemeur();

// ── Rendu plat — gradient pictural avec jitter déterministe ────────────────
LinearGradient fillGradient(Color hex, int i) {
  final j = (hash(i) - 0.5) * 0.20;
  final base = shade(hex, j);
  final hi = shade(hex, j + 0.15);
  final lo = shade(hex, j - 0.13);
  final angle = 130 + (hash(i + 9) * 90).round();
  return _angled([hi, base, lo], const [0.0, 0.55, 1.0], angle.toDouble());
}

LinearGradient _angled(List<Color> colors, List<double> stops, double deg) {
  final rad = deg * math.pi / 180;
  final dx = math.sin(rad), dy = -math.cos(rad);
  return LinearGradient(
    colors: colors,
    stops: stops,
    begin: Alignment(-dx, -dy),
    end: Alignment(dx, dy),
  );
}

// ── Vitrail — fonds « photo » par famille (gradients riches simulés) ────────
// Chaque couche est étalée sur toute l'œuvre ; chaque cellule en révèle un
// fragment via son alignement (cf. MosaicWidget).
const Color _t = Color(0x00000000);

final Map<String, List<Gradient>> _photo = {
  'bleus': [
    _angled(const [Color(0xFFA8CAEE), Color(0xFF5F8FCD), Color(0xFF2F5FA6), Color(0xFF243F7C)],
        const [0.0, 0.38, 0.70, 1.0], 162),
    _radial(0.28, 0.22, 0.62, const [Color(0xD9FFFFFF), _t]),
    _radial(0.78, 0.70, 0.55, const [Color(0x73FFFFFF), _t]),
  ],
  'ors': [
    _angled(const [Color(0xFFF7D885), Color(0xFFE8A93C), Color(0xFFCC7A2C), Color(0xFF9C5A24)],
        const [0.0, 0.46, 0.82, 1.0], 158),
    _radial(0.60, 0.42, 0.50, const [Color(0xFFFFF2BF), _t]),
    _radial(0.30, 0.80, 0.62, const [Color(0x73AA5A1E), _t]),
  ],
  'verts': [
    _angled(const [Color(0xFF86AC4F), Color(0xFF4F7D3A), Color(0xFF2C5527)],
        const [0.0, 0.48, 1.0], 150),
    _radial(0.24, 0.28, 0.48, const [Color(0xBFDEECA0), _t]),
    _radial(0.80, 0.78, 0.55, const [Color(0x80143718), _t]),
  ],
  'terres': [
    _angled(const [Color(0xFFAB7B50), Color(0xFF7A4F2E), Color(0xFF46321F)],
        const [0.0, 0.54, 1.0], 150),
    _radial(0.70, 0.24, 0.50, const [Color(0x8CD6B07C), _t]),
    _radial(0.25, 0.80, 0.58, const [Color(0x80281A10), _t]),
  ],
  'roses': [
    _angled(const [Color(0xFFE6ABC1), Color(0xFFC2738F), Color(0xFF7E4A68)],
        const [0.0, 0.48, 1.0], 158),
    _radial(0.38, 0.32, 0.50, const [Color(0xD9FFE0E9), _t]),
    _radial(0.78, 0.76, 0.55, const [Color(0x665A2846), _t]),
  ],
  'rouges': [
    _angled(const [Color(0xFFE3684C), Color(0xFFC23A2E), Color(0xFF88241F)],
        const [0.0, 0.50, 1.0], 154),
    _radial(0.56, 0.38, 0.48, const [Color(0x99FFBA90), _t]),
    _radial(0.26, 0.82, 0.56, const [Color(0x80501212), _t]),
  ],
  'gris': [
    _angled(const [Color(0xFF9AA1A8), Color(0xFF5D666F), Color(0xFF373D45)],
        const [0.0, 0.54, 1.0], 160),
    _radial(0.50, 0.28, 0.55, const [Color(0x8CFFFFFF), _t]),
    _radial(0.76, 0.80, 0.58, const [Color(0x80141820), _t]),
  ],
};

RadialGradient _radial(double cx, double cy, double radius, List<Color> colors) {
  return RadialGradient(
    center: Alignment(cx * 2 - 1, cy * 2 - 1),
    radius: radius,
    colors: colors,
    stops: const [0.0, 1.0],
  );
}

List<Gradient> photoLayers(String family) => _photo[family] ?? _photo['gris']!;

/// Alignement (-1..1) du fragment vitrail d'une cellule dans le fond famille.
Alignment cellPhotoAlignment(ArtCell c) => Alignment(
      kCols > 1 ? (c.col / (kCols - 1)) * 2 - 1 : 0,
      kRows > 1 ? (c.row / (kRows - 1)) * 2 - 1 : 0,
    );
