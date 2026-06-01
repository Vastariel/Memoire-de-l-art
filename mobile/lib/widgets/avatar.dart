import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class MdaAvatar extends StatelessWidget {
  final String pigmentKey;
  final String initial;
  final double size;

  const MdaAvatar({
    super.key,
    required this.pigmentKey,
    required this.initial,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final base = MdaColors.pigments[pigmentKey] ?? MdaColors.pigCobalt;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withAlpha(0xCC), base, base.withAlpha(0xD9)],
          stops: const [0, 0.6, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40FFFFFF),
            blurRadius: 0,
            spreadRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: MdaType.serifItalic(color: Colors.white).copyWith(
          fontSize: size * 0.42,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
