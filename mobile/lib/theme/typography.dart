import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Resolved font family names — use these for inline fontFamily: properties.
abstract final class MdaFonts {
  static String get serif => GoogleFonts.spectral().fontFamily!;
  static String get sans  => GoogleFonts.hankenGrotesk().fontFamily!;
}

abstract final class MdaType {
  // ── t-display ─────────────────────────────────────────────
  static TextStyle display({Color? color}) => GoogleFonts.spectral(
    fontWeight: FontWeight.w500, fontSize: 40, height: 1.06,
    letterSpacing: -0.4, color: color,
  );

  // ── t-h1 ──────────────────────────────────────────────────
  static TextStyle h1({Color? color}) => GoogleFonts.spectral(
    fontWeight: FontWeight.w500, fontSize: 28, height: 1.14,
    letterSpacing: -0.14, color: color,
  );

  // ── t-h2 ──────────────────────────────────────────────────
  static TextStyle h2({Color? color}) => GoogleFonts.spectral(
    fontWeight: FontWeight.w500, fontSize: 22, height: 1.2, color: color,
  );

  // ── t-serif-italic — gallery voice ────────────────────────
  static TextStyle serifItalic({Color? color}) => GoogleFonts.spectral(
    fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: color,
  );

  // ── t-title ───────────────────────────────────────────────
  static TextStyle title({Color? color}) => GoogleFonts.hankenGrotesk(
    fontWeight: FontWeight.w600, fontSize: 17, height: 1.3,
    letterSpacing: -0.17, color: color,
  );

  // ── t-body ────────────────────────────────────────────────
  static TextStyle body({Color? color}) => GoogleFonts.hankenGrotesk(
    fontWeight: FontWeight.w400, fontSize: 16, height: 1.5, color: color,
  );

  // ── t-body-sm ─────────────────────────────────────────────
  static TextStyle bodySm({Color? color}) => GoogleFonts.hankenGrotesk(
    fontWeight: FontWeight.w400, fontSize: 14, height: 1.45, color: color,
  );

  // ── t-caption ─────────────────────────────────────────────
  static TextStyle caption({Color? color}) => GoogleFonts.hankenGrotesk(
    fontWeight: FontWeight.w500, fontSize: 13, height: 1.35, color: color,
  );

  // ── t-overline ────────────────────────────────────────────
  static TextStyle overline({Color? color}) => GoogleFonts.hankenGrotesk(
    fontWeight: FontWeight.w600, fontSize: 12, height: 1.2,
    letterSpacing: 1.68, color: color,
  );

  // ── t-num ─────────────────────────────────────────────────
  static TextStyle num({Color? color}) => GoogleFonts.spectral(
    fontWeight: FontWeight.w400,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );

  // ── pig name ──────────────────────────────────────────────
  static TextStyle pigName({Color? color}) => GoogleFonts.spectral(
    fontSize: 24, height: 1.1, color: color,
  );

  // ── generic helpers (free size) ───────────────────────────
  static TextStyle serif({
    required double size,
    FontWeight weight = FontWeight.w400,
    bool italic = false,
    double height = 1.1,
    Color? color,
  }) => GoogleFonts.spectral(
    fontSize: size, fontWeight: weight, height: height,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal, color: color,
  );

  static TextStyle sans({
    required double size,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
    double? letterSpacing,
    Color? color,
  }) => GoogleFonts.hankenGrotesk(
    fontSize: size, fontWeight: weight, height: height,
    letterSpacing: letterSpacing, color: color,
  );
}
