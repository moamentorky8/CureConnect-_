import 'package:flutter/material.dart';
import 'package:cureconnect/core/widgets/cure_connect_logo.dart';
import 'package:cureconnect/core/widgets/hexagon_background.dart';
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HexagonBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CureConnectLogo(size: 150),
            const SizedBox(height: 24),
            Text(
              'Smart Medication Organizer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
