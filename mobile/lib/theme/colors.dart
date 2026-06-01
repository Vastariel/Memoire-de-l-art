import 'package:flutter/material.dart';

abstract final class MdaColors {
  // ── Warm neutral ramp ("the paper") ──────────────────────────
  static const cream50  = Color(0xFFFBF8F1);
  static const cream100 = Color(0xFFF4EEE1);
  static const cream200 = Color(0xFFEBE3D2);
  static const cream300 = Color(0xFFDCD2BC);
  static const cream400 = Color(0xFFC7BBA0);

  static const ink900 = Color(0xFF1C1813);
  static const ink700 = Color(0xFF3B342A);
  static const ink500 = Color(0xFF6C6354);
  static const ink400 = Color(0xFF8B8273);
  static const ink300 = Color(0xFFA89E8C);

  // ── Brand accent (terracotta/sienna) ─────────────────────────
  static const clay600 = Color(0xFFA84B27);
  static const clay500 = Color(0xFFBC5A2E);
  static const clay400 = Color(0xFFCE7551);
  static const clay100 = Color(0xFFF0DACD);

  // ── Pigment palette — the "couleur du jour" set ──────────────
  static const pigVermillion  = Color(0xFFD7472F);
  static const pigSienna      = Color(0xFF9C5A33);
  static const pigOchre       = Color(0xFFD69A3C);
  static const pigSaffron     = Color(0xFFE8B53C);
  static const pigOlive       = Color(0xFF7E8B3F);
  static const pigViridian    = Color(0xFF2E7D5B);
  static const pigTeal        = Color(0xFF2A8C8A);
  static const pigCobalt      = Color(0xFF2D5FA6);
  static const pigUltramarine = Color(0xFF34408C);
  static const pigAubergine   = Color(0xFF6E3A6B);
  static const pigRose        = Color(0xFFC45B7C);
  static const pigSlate       = Color(0xFF4A5763);

  static const Map<String, Color> pigments = {
    'vermillion' : pigVermillion,
    'sienna'     : pigSienna,
    'ochre'      : pigOchre,
    'saffron'    : pigSaffron,
    'olive'      : pigOlive,
    'viridian'   : pigViridian,
    'teal'       : pigTeal,
    'cobalt'     : pigCobalt,
    'ultramarine': pigUltramarine,
    'aubergine'  : pigAubergine,
    'rose'       : pigRose,
    'slate'      : pigSlate,
  };

  // ── Semantic / status ─────────────────────────────────────────
  static const ok    = Color(0xFF3F8E5C);
  static const warn  = Color(0xFFC98A2E);
  static const error = Color(0xFFC0432C);
}

// ── Light theme semantic tokens ───────────────────────────────
abstract final class MdaLight {
  static const paper       = MdaColors.cream50;
  static const surface     = Color(0xFFFFFEFB);
  static const surfaceSunk = MdaColors.cream100;
  static const fg1         = MdaColors.ink900;
  static const fg2         = MdaColors.ink500;
  static const fg3         = MdaColors.ink300;
  static const onAccent    = MdaColors.cream50;
  static const line        = Color(0x1F1C1813);
  static const lineStrong  = Color(0x381C1813);
  static const accent      = MdaColors.clay500;
  static const accentPress = MdaColors.clay600;
  static const mosaicEmpty = MdaColors.cream200;
}

// ── Dark theme semantic tokens ────────────────────────────────
abstract final class MdaDark {
  static const paper       = Color(0xFF161310);
  static const surface     = Color(0xFF211C17);
  static const surfaceSunk = Color(0xFF110E0B);
  static const fg1         = Color(0xFFF0E9DB);
  static const fg2         = Color(0xFFB3A892);
  static const fg3         = Color(0xFF7C7363);
  static const onAccent    = MdaColors.ink900;
  static const line        = Color(0x1FF0E9DB);
  static const lineStrong  = Color(0x38F0E9DB);
  static const accent      = MdaColors.clay400;
  static const accentPress = MdaColors.clay500;
  static const mosaicEmpty = Color(0xFF2A241D);
}

extension ColorBrightness on Color {
  Color lighten(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
