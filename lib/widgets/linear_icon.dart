import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;

  const SvgIcon(
    this.iconName, {
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Se passares uma cor, usa-a. Se não, usa a cor do tema (do BottomNav)
    final Color effectiveColor = color ?? IconTheme.of(context).color ?? Colors.black;

    return SvgPicture.asset(
      'lib/assets/icons/$iconName.svg', // Garante que os ficheiros estão nesta pasta
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}