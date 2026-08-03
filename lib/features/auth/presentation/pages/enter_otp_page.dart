import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../application/auth_controller.dart';
import '../auth_routes.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class EnterOtpPage extends ConsumerStatefulWidget {
  const EnterOtpPage({super.key});

  @override
  ConsumerState<EnterOtpPage> createState() => _EnterOtpPageState();
}

class _EnterOtpPageState extends ConsumerState<EnterOtpPage> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;

  bool _isSubmitting = false;
  bool _isResending = false;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      6,
      (_) => TextEditingController(),
      growable: false,
    );
    _focusNodes = List.generate(6, (_) => FocusNode(), growable: false);
    _syncTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _syncTimer());
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncTimer() {
    final seconds = ref.read(authControllerProvider).secondsUntilResend;
    if (!mounted) {
      return;
    }
    setState(() => _secondsLeft = seconds);
  }

  String get _otpValue =>
      _controllers.map((controller) => controller.text.trim()).join();

  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context);
    if (_otpValue.length != 6) {
      _showMessage(l10n.enterCompleteOtp);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(_otpValue);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AuthRoutes.resetPassword);
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

  Future<void> _resendOtp() async {
    final l10n = AppLocalizations.of(context);
    if (_isResending) {
      return;
    }

    if (_secondsLeft > 0) {
      _showMessage(l10n.waitBeforeResendingOtp(_secondsLeft), type: ToastType.info);
      return;
    }

    setState(() => _isResending = true);
    try {
      await ref.read(authControllerProvider.notifier).resendOtp();
      _showMessage(l10n.newOtpSent, type: ToastType.success);
      _syncTimer();
    } on AuthFlowException catch (error) {
      _showMessage(error.isNetworkError ? l10n.noInternetConnection : error.message);
    } catch (_) {
      _showMessage(l10n.somethingWentWrong);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
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

    if (!authState.hasPendingOtp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AuthRoutes.forgotPassword);
        }
      });
    }

    return AuthScaffold(
        child: Column(
          children: [
            const BrandHeader(topSpacing: 80, bottomSpacing: 20),
            AuthTitleBlock(title: l10n.enterOtp, bottomSpacing: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final boxWidth = ((constraints.maxWidth - (spacing * 5)) / 6)
                  .clamp(42.0, 58.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: boxWidth,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: index == 5
                          ? TextInputAction.done
                          : TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF293C66),
                          ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 24,
                        ),
                        filled: false,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty &&
                            index < _focusNodes.length - 1) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                      onSubmitted: (_) {
                        if (index == 5) {
                          _verifyOtp();
                        }
                      },
                      
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            _isResending
                ? l10n.sendingNewOtp
                : _secondsLeft > 0
                ? l10n.resendCodeIn(_secondsLeft)
                : l10n.canResendOtpNow,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF717171),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          InlineAuthLink(
            leadingText: l10n.didntReceiveOtp,
            actionText: l10n.resendOtp,
            onTap: _isResending ? null : _resendOtp,
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: l10n.verifyNow,
            onPressed: _verifyOtp,
            isBusy: _isSubmitting,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
