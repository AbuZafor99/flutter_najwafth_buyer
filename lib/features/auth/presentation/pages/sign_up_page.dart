import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../application/auth_controller.dart';
import '../auth_routes.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          .signUp(
            fullName: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthRoutes.home, (route) => false);
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
            const BrandHeader(topSpacing: 20, bottomSpacing: 16),
            AuthTitleBlock(
              title: l10n.letsGetStarted,
              subtitle: l10n.createAnAccount,
            ),
            AuthFieldLabel(l10n.userName),
            AuthTextField(
              controller: _nameController,
              hintText: l10n.enterYourFirstName,
              validator: (value) =>
                  Validators.required(
                    value,
                    label: l10n.fullNameLabel,
                    l10n: l10n,
                  ),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(height: 18),
            AuthFieldLabel(l10n.yourEmail),
            AuthTextField(
              controller: _emailController,
              hintText: l10n.enterYourEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => Validators.email(value, l10n: l10n),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 18),
            AuthFieldLabel(l10n.phoneNumber),
            AuthTextField(
              controller: _phoneController,
              hintText: l10n.enterYourPhoneNumber,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  Validators.required(
                    value,
                    label: l10n.phoneNumber,
                    l10n: l10n,
                  ),
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: 18),
            AuthFieldLabel(l10n.password),
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
            const SizedBox(height: 18),
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
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF818181),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: l10n.signUp,
              onPressed: _submit,
              isBusy: _isSubmitting,
            ),
            const SizedBox(height: 24),
            Center(
              child: InlineAuthLink(
                leadingText: l10n.alreadyHaveAccount,
                actionText: l10n.signInHere,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
