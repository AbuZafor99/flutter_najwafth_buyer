import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../application/auth_controller.dart';
import '../auth_routes.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _allowOtpGuardRedirect = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    _allowOtpGuardRedirect = false;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(
            newPassword: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) {
        return;
      }

      showTopToast(
        context,
        title: l10n.passwordResetSuccessfully,
        type: ToastType.success,
      );

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthRoutes.signIn, (route) => false);
    } on AuthFlowException catch (error) {
      _allowOtpGuardRedirect = true;
      _showMessage(error.isNetworkError ? l10n.noInternetConnection : error.message);
    } catch (_) {
      _allowOtpGuardRedirect = true;
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
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);

    if (_allowOtpGuardRedirect && !authState.otpVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AuthRoutes.forgotPassword);
        }
      });
    }

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandHeader(topSpacing: 72, bottomSpacing: 24),
            AuthTitleBlock(
              title: l10n.resetPasswordTitle,
              subtitle: l10n.enterAndConfirmNewPassword,
            ),
            AuthFieldLabel(l10n.newPassword),
            AuthTextField(
              controller: _passwordController,
              hintText: l10n.enterYourPassword,
              obscureText: _obscurePassword,
              validator: (value) =>
                  Validators.minLength(
                    value,
                    8,
                    label: l10n.password,
                    l10n: l10n,
                  ),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AuthFieldLabel(l10n.confirmPassword),
            AuthTextField(
              controller: _confirmPasswordController,
              hintText: l10n.enterConfirmPassword,
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                final message = Validators.minLength(
                  value,
                  8,
                  label: l10n.confirmPasswordLabel,
                  l10n: l10n,
                );
                if (message != null) {
                  return message;
                }
                if (value != _passwordController.text) {
                  return l10n.passwordsDoNotMatch;
                }
                return null;
              },
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: l10n.continueLabel,
              onPressed: _submit,
              isBusy: _isSubmitting,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
