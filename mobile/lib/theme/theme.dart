import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'typography.dart';

abstract final class MdaTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    paper: MdaLight.paper,
    surface: MdaLight.surface,
    fg1: MdaLight.fg1,
    fg2: MdaLight.fg2,
    accent: MdaLight.accent,
    line: MdaLight.line,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    paper: MdaDark.paper,
    surface: MdaDark.surface,
    fg1: MdaDark.fg1,
    fg2: MdaDark.fg2,
    accent: MdaDark.accent,
    line: MdaDark.line,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color paper,
    required Color surface,
    required Color fg1,
    required Color fg2,
    required Color accent,
    required Color line,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: isDark ? MdaDark.onAccent : MdaLight.onAccent,
        primaryContainer: MdaColors.clay100,
        onPrimaryContainer: MdaColors.clay600,
        secondary: MdaColors.clay400,
        onSecondary: MdaColors.cream50,
        secondaryContainer: MdaColors.clay100,
        onSecondaryContainer: MdaColors.clay600,
        error: MdaColors.error,
        onError: MdaColors.cream50,
        surface: surface,
        onSurface: fg1,
        onSurfaceVariant: fg2,
        outline: line,
        shadow: const Color(0xFF281E12),
      ),
      fontFamily: MdaFonts.sans,
      textTheme: GoogleFonts.hankenGroteskTextTheme().copyWith(
        displayLarge: MdaType.display(color: fg1),
        headlineLarge: MdaType.h1(color: fg1),
        headlineMedium: MdaType.h2(color: fg1),
        titleLarge: MdaType.title(color: fg1),
        bodyLarge: MdaType.body(color: fg1),
        bodyMedium: MdaType.bodySm(color: fg2),
        bodySmall: MdaType.caption(color: fg2),
        labelSmall: MdaType.overline(color: fg2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: MdaType.h2(color: fg1),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: accent,
        unselectedItemColor: isDark ? MdaDark.fg3 : MdaLight.fg3,
        selectedLabelStyle: MdaType.caption(),
        unselectedLabelStyle: MdaType.caption(),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: line),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? MdaDark.onAccent : MdaLight.onAccent,
          textStyle: MdaType.title(),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          elevation: 1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: MdaType.body(color: isDark ? MdaDark.fg3 : MdaLight.fg3),
      ),
      dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ── Spacing constants (4pt base) ─────────────────────────────
abstract final class MdaSpacing {
  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 16.0;
  static const sp5 = 24.0;
  static const sp6 = 32.0;
  static const sp7 = 48.0;
  static const sp8 = 64.0;
}

// ── Border radii ─────────────────────────────────────────────
abstract final class MdaRadius {
  static const xs   = Radius.circular(6);
  static const sm   = Radius.circular(10);
  static const md   = Radius.circular(16);
  static const lg   = Radius.circular(24);
  static const xl   = Radius.circular(32);
  static const pill = Radius.circular(999);

  static const bXs   = BorderRadius.all(xs);
  static const bSm   = BorderRadius.all(sm);
  static const bMd   = BorderRadius.all(md);
  static const bLg   = BorderRadius.all(lg);
  static const bXl   = BorderRadius.all(xl);
  static const bPill = BorderRadius.all(pill);
}

// ── Motion ───────────────────────────────────────────────────
abstract final class MdaDuration {
  static const fast = Duration(milliseconds: 160);
  static const std  = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 620);
}

abstract final class MdaCurve {
  static const easeOut   = Cubic(0.22, 1, 0.36, 1);
  static const easeInOut = Cubic(0.65, 0, 0.35, 1);
}

// ── Shadows (warm, low, diffuse) ─────────────────────────────
abstract final class MdaShadows {
  static const sm = [
    BoxShadow(color: Color(0x0F281E12), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D281E12), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const md = [
    BoxShadow(color: Color(0x14281E12), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0F281E12), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const lg = [
    BoxShadow(color: Color(0x23281E12), blurRadius: 40, offset: Offset(0, 14)),
    BoxShadow(color: Color(0x11281E12), blurRadius: 10, offset: Offset(0, 4)),
  ];
}
