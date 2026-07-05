import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../application/auth_controller.dart';
import '../auth_routes.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestOtp(_emailController.text);

      if (!mounted) {
        return;
      }

      showTopToast(
        context,
        title: l10n.otpSentToEmail,
        type: ToastType.success,
      );

      Navigator.of(context).pushNamed(AuthRoutes.enterOtp);
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
            const BrandHeader(topSpacing: 72, bottomSpacing: 24),
            AuthTitleBlock(
              title: l10n.resetPassword,
              subtitle: l10n.enterEmailToReceiveOtp,
            ),
            AuthFieldLabel(l10n.yourEmail),
            AuthTextField(
              controller: _emailController,
              hintText: l10n.enterYourEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => Validators.email(value, l10n: l10n),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: l10n.sendOtp,
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
