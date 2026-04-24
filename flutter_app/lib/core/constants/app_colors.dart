import 'package:flutter/material.dart';

class AppColors {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const medicalBlue = Color(0xFF007BFF);
  static const logoCyan = Color(0xFF20C4D8);
  static const logoTeal = Color(0xFF0D8AA8);
  static const logoMint = Color(0xFF7AD97A);
  static const surface = Color(0xFF0A0F18);
  static const card = Color(0xCC121A26);
  static const cardBorder = Color(0x66FFFFFF);
  static const danger = Color(0xFFFF6363);

  static const brandGradient = LinearGradient(
    colors: [logoCyan, logoTeal, logoMint],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const shellGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF07111E), Color(0xFF041A2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
