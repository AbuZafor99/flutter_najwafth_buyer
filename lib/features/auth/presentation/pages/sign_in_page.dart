import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../application/auth_controller.dart';
import '../auth_routes.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(AuthRoutes.home);
    } on AuthFlowException catch (error) {
      _showMessage(error.isNetworkError ? l10n.noInternetConnection : error.message);
    } catch (_) {
      _showMessage(l10n.somethingWentWrong);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message, {ToastType type = ToastType.error}) {
    showTopToast(context, title: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandHeader(topSpacing: 48, bottomSpacing: 28),
            AuthFieldLabel(l10n.userEmail),
            AuthTextField(
              controller: _emailController,
              hintText: l10n.enterYourEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => Validators.email(value, l10n: l10n),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 20),
            AuthFieldLabel(l10n.password),
            AuthTextField(
              controller: _passwordController,
              hintText: l10n.enterYourPassword,
              obscureText: _obscurePassword,
              validator: (value) => Validators.minLength(
                value,
                8,
                label: l10n.password,
                l10n: l10n,
              ),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF818181),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.rememberMe,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF808080),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AuthRoutes.forgotPassword);
                    },
                    child: Text(
                      l10n.forgotPassword,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: l10n.signIn,
              onPressed: _submit,
              isBusy: _isSubmitting,
            ),
            const SizedBox(height: 28),
            Center(
              child: InlineAuthLink(
                leadingText: l10n.dontHaveAccount,
                actionText: l10n.signUpHere,
                onTap: () {
                  Navigator.of(context).pushNamed(AuthRoutes.signUp);
                },
              ),
            ),
            const SizedBox(height: 32),
            SocialActionButton(
              icon: Icons.g_mobiledata_rounded,
              iconColor: const Color(0xFFEA4335),
              label: l10n.continueWithGoogle,
              onPressed: () {
                _showMessage(l10n.googleNotConfigured, type: ToastType.info);
              },
            ),
            const SizedBox(height: 12),
            SocialActionButton(
              icon: Icons.facebook_rounded,
              iconColor: const Color(0xFF1877F2),
              label: l10n.continueWithFacebook,
              onPressed: () {
                _showMessage(l10n.facebookNotConfigured, type: ToastType.info);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
