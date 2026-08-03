import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../core/network/network_providers.dart';
import '../core/providers/theme_mode_provider.dart';
import '../core/session/session_expiry_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_routes.dart';
import '../features/auth/presentation/pages/enter_otp_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/home/application/store_controller.dart';
import '../features/home/domain/store_models.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../core/widgets/splash/presentation/splash_page.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

final class NajwafthBuyerApp extends ConsumerStatefulWidget {
  const NajwafthBuyerApp({super.key});

  @override
  ConsumerState<NajwafthBuyerApp> createState() => _NajwafthBuyerAppState();
}

final class _NajwafthBuyerAppState extends ConsumerState<NajwafthBuyerApp> {
  bool _sessionDialogVisible = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(sessionExpiryProvider, (previous, next) {
      if (previous == null || next <= previous) {
        return;
      }
      _showSessionExpiredDialog();
    });

    final config = ref.watch(appConfigProvider);
    final selectedLanguage = ref.watch(
      storeControllerProvider.select((state) => state.selectedLanguage),
    );
    final locale = switch (selectedLanguage) {
      AppLanguage.french => const Locale('fr'),
      _ => const Locale('en'),
    };

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      title: config.appName,
      debugShowCheckedModeBanner: config.isDevelopment,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeControllerProvider),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AuthRoutes.splash,
      onGenerateRoute: (settings) {
        final page = switch (settings.name) {
          AuthRoutes.splash => const SplashPage(),
          AuthRoutes.onboarding => const OnboardingPage(),
          AuthRoutes.signIn => const SignInPage(),
          AuthRoutes.signUp => const SignUpPage(),
          AuthRoutes.forgotPassword => const ForgotPasswordPage(),
          AuthRoutes.enterOtp => const EnterOtpPage(),
          AuthRoutes.resetPassword => const ResetPasswordPage(),
          AuthRoutes.home => const HomePage(),
          _ => const SplashPage(),
        };

        return MaterialPageRoute<void>(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }

  Future<void> _showSessionExpiredDialog() async {
    if (_sessionDialogVisible) {
      return;
    }

    _sessionDialogVisible = true;
    await ref.read(authControllerProvider.notifier).expireSession();

    final navigator = appNavigatorKey.currentState;
    final dialogContext = appNavigatorKey.currentContext;
    if (navigator == null ||
        dialogContext == null ||
        !mounted ||
        !dialogContext.mounted) {
      _sessionDialogVisible = false;
      return;
    }

    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => const _SessionExpiredDialog(),
    );

    _sessionDialogVisible = false;
    if (!mounted) {
      return;
    }

    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AuthRoutes.signIn,
      (route) => false,
    );
  }
}

class _SessionExpiredDialog extends StatelessWidget {
  const _SessionExpiredDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F8FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_outlined,
                color: Color(0xFF5A91C4),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.sessionExpiredTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF243041),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sessionExpiredMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF687385),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A91C4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  l10n.backToSignIn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
