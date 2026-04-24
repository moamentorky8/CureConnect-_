import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/dashboard/presentation/pages/home_shell_page.dart';
import 'features/shared/data/cureconnect_repository.dart';

class CureConnectApp extends ConsumerStatefulWidget {
  const CureConnectApp({super.key});

  @override
  ConsumerState<CureConnectApp> createState() => _CureConnectAppState();
}

class _CureConnectAppState extends ConsumerState<CureConnectApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CureConnect',
      theme: AppTheme.theme,
      home: _showSplash
          ? const SplashPage()
          : authState.when(
              data: (user) => user == null
                  ? const LoginPage()
                  : HomeShellPage(user: user),
              loading: () => const SplashPage(),
              error: (_, __) => const LoginPage(),
            ),
    );
  }
}
