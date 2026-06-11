// Smoke test du moteur d'œuvre v2.

import 'package:flutter_test/flutter_test.dart';
import 'package:memoire_de_lart/engine/mosaic_engine.dart';

void main() {
  test('buildSemeur produit une grille 12x16 (192 cellules)', () {
    expect(kArtwork.cols, 12);
    expect(kArtwork.rows, 16);
    expect(kArtwork.cells.length, 192);
  });

  test('chaque cellule a une famille et une variante connues', () {
    for (final c in kArtwork.cells) {
      expect(kFamilies.containsKey(c.family), isTrue);
      expect(kVariants.containsKey(c.variant), isTrue);
      expect(kVariants[c.variant]!.family, c.family);
    }
  });

  test('7 familles, une par jour lun→dim', () {
    expect(kFamilies.length, 7);
    final days = kFamilies.values.map((f) => f.day).toSet();
    expect(days, {1, 2, 3, 4, 5, 6, 7});
  });
}
