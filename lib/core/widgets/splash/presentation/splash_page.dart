import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/application/auth_controller.dart';
import '../../../../features/auth/presentation/auth_routes.dart';

final class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const Color backgroundColor = Color(0xFFF8F1E8);
  static const String logoAsset = 'assets/images/app_logo.png';

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _navigateNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateNext() {
    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    final route = authState.isAuthenticated || authState.onboardingCompleted
        ? AuthRoutes.home
        : AuthRoutes.onboarding;

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: SplashPage.backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: SplashPage.backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SplashPage.backgroundColor,
        body: Center(
          child: FractionallySizedBox(
            widthFactor: 0.48,
            child: const Image(
              image: AssetImage(SplashPage.logoAsset),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
