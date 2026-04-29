import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CureConnectLogo extends StatelessWidget {
  const CureConnectLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.brandGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.logoCyan.withOpacity(0.35),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'CC',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
          ),
        ),
      ),
    );
  }
}
