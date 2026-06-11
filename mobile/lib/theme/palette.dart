// palette.dart — accès pratique aux tokens dépendants du thème (clair/sombre).

import 'package:flutter/material.dart';
import 'colors.dart';

extension MdaPalette on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get paper => isDark ? MdaDark.paper : MdaLight.paper;
  Color get surface => isDark ? MdaDark.surface : MdaLight.surface;
  Color get surfaceSunk => isDark ? MdaDark.surfaceSunk : MdaLight.surfaceSunk;
  Color get fg1 => isDark ? MdaDark.fg1 : MdaLight.fg1;
  Color get fg2 => isDark ? MdaDark.fg2 : MdaLight.fg2;
  Color get fg3 => isDark ? MdaDark.fg3 : MdaLight.fg3;
  Color get line => isDark ? MdaDark.line : MdaLight.line;
  Color get lineStrong => isDark ? MdaDark.lineStrong : MdaLight.lineStrong;
  Color get accent => isDark ? MdaDark.accent : MdaLight.accent;
  Color get onAccent => isDark ? MdaDark.onAccent : MdaLight.onAccent;
  Color get mosaicEmpty => isDark ? MdaDark.mosaicEmpty : MdaLight.mosaicEmpty;
}
