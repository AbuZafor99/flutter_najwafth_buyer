import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/storage/key_value_storage.dart';
import '../../../core/storage/storage_providers.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

const _appRole = 'buyer';

final class AuthState {
  const AuthState({
    required this.onboardingCompleted,
    required this.isAuthenticated,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.rememberMe,
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
    required this.pendingResetEmail,
    required this.otpRequestedAt,
    required this.otpVerified,
    required this.verifiedResetOtp,
  });

  factory AuthState.initial(KeyValueStorage storage) {
    return AuthState(
      onboardingCompleted:
          storage.readBool(_AuthStorageKeys.onboarding) ?? false,
      isAuthenticated:
          storage.readBool(_AuthStorageKeys.isAuthenticated) ?? false,
      fullName: storage.readString(_AuthStorageKeys.fullName) ?? '',
      email: storage.readString(_AuthStorageKeys.email) ?? '',
      phone: storage.readString(_AuthStorageKeys.phone) ?? '',
      password: storage.readString(_AuthStorageKeys.password) ?? '',
      rememberMe: storage.readBool(_AuthStorageKeys.rememberMe) ?? false,
      accessToken: storage.readString(_AuthStorageKeys.accessToken),
      refreshToken: storage.readString(_AuthStorageKeys.refreshToken),
      userId: storage.readString(_AuthStorageKeys.userId),
      role: storage.readString(_AuthStorageKeys.role),
      pendingResetEmail: storage.readString(_AuthStorageKeys.pendingResetEmail),
      otpRequestedAt: _parseDateTime(
        storage.readString(_AuthStorageKeys.otpRequestedAt),
      ),
      otpVerified: storage.readBool(_AuthStorageKeys.otpVerified) ?? false,
      verifiedResetOtp: storage.readString(_AuthStorageKeys.verifiedResetOtp),
    );
  }

  final bool onboardingCompleted;
  final bool isAuthenticated;
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final bool rememberMe;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? role;
  final String? pendingResetEmail;
  final DateTime? otpRequestedAt;
  final bool otpVerified;
  final String? verifiedResetOtp;

  bool get hasPendingOtp => pendingResetEmail != null && otpRequestedAt != null;

  int get secondsUntilResend {
    if (otpRequestedAt == null) {
      return 0;
    }

    final remaining =
        60 - DateTime.now().difference(otpRequestedAt!).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  AuthState copyWith({
    bool? onboardingCompleted,
    bool? isAuthenticated,
    String? fullName,
    String? email,
    String? phone,
    String? password,
    bool? rememberMe,
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? role,
    String? pendingResetEmail,
    DateTime? otpRequestedAt,
    bool? otpVerified,
    String? verifiedResetOtp,
    bool clearPendingResetEmail = false,
    bool clearOtpRequestedAt = false,
    bool clearVerifiedResetOtp = false,
    bool clearTokens = false,
  }) {
    return AuthState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      accessToken: clearTokens ? null : accessToken ?? this.accessToken,
      refreshToken: clearTokens ? null : refreshToken ?? this.refreshToken,
      userId: clearTokens ? null : userId ?? this.userId,
      role: clearTokens ? null : role ?? this.role,
      pendingResetEmail: clearPendingResetEmail
          ? null
          : pendingResetEmail ?? this.pendingResetEmail,
      otpRequestedAt: clearOtpRequestedAt
          ? null
          : otpRequestedAt ?? this.otpRequestedAt,
      otpVerified: otpVerified ?? this.otpVerified,
      verifiedResetOtp: clearVerifiedResetOtp
          ? null
          : verifiedResetOtp ?? this.verifiedResetOtp,
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}

final class AuthController extends Notifier<AuthState> {
  KeyValueStorage? _storage;

  @override
  AuthState build() {
    _storage ??= ref.watch(keyValueStorageProvider);

    final initial = AuthState.initial(_storage!);

    if (initial.isAuthenticated && initial.role != _appRole) {
      Future<void>.microtask(_clearSession);

      final sanitized = initial.copyWith(
        isAuthenticated: false,
        clearTokens: true,
      );

      _log('init:sanitized-non-buyer-session', sanitized);
      return sanitized;
    }

    if (initial.isAuthenticated) {
      // Returning user with a stored session — register for push on launch.
      Future<void>.microtask(
        () => ref.read(pushNotificationServiceProvider).start(),
      );
    }

    _log('init', initial);
    return initial;
  }

  Future<void> completeOnboarding() async {
    _logStep('completeOnboarding:start');

    state = state.copyWith(onboardingCompleted: true);
    await _storage!.writeBool(_AuthStorageKeys.onboarding, true);

    _log('completeOnboarding:done', state);
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    _logStep('signIn:start email=$normalizedEmail');

    final result = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': normalizedEmail, 'password': password},
          parser: _extractDataMap,
        );

    final data = _unwrap(result);
    final accessToken = (data['accessToken'] ?? '').toString();
    final refreshToken = (data['refreshToken'] ?? '').toString();

    final user = data['user'];
    final userMap = user is Map<String, dynamic> ? user : <String, dynamic>{};

    final name = (userMap['name'] ??
            userMap['fullName'] ??
            state.fullName)
        .toString();

    final role = (data['role'] ?? userMap['role'] ?? '').toString();
    final userId = (data['_id'] ?? userMap['_id'] ?? '').toString();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      _logStep('signIn:error missing tokens in response');
      throw const AuthFlowException(
        'Authentication failed. Please try again.',
      );
    }

    if (role.isNotEmpty && role != _appRole) {
      _logStep('signIn:error invalid role=$role');
      throw const AuthFlowException(
        'This account is not authorized for the buyer application.',
      );
    }

    state = state.copyWith(
      isAuthenticated: true,
      rememberMe: rememberMe,
      onboardingCompleted: true,
      email: normalizedEmail,
      fullName: name,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId.isEmpty ? null : userId,
      role: role.isEmpty ? null : role,
    );

    await _persistSession(rememberMe: rememberMe);

    // Register this device for push now that we have a valid session.
    unawaited(ref.read(pushNotificationServiceProvider).start());

    _log('signIn:done', state);
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    _logStep('signUp:start email=$normalizedEmail');

    if (password != confirmPassword) {
      throw const AuthFlowException('Passwords do not match.');
    }

    final payload = {
      'name': fullName.trim(),
      'fullName': fullName.trim(),
      'email': normalizedEmail,
      'phone': phone.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
      'role': _appRole,
    };

    final result = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
          '/auth/register',
          data: payload,
          parser: _extractDataMap,
        );

    final data = _unwrap(result);
    final accessToken = (data['accessToken'] ?? '').toString();
    final refreshToken = (data['refreshToken'] ?? '').toString();

    final user = data['user'];
    final userMap = user is Map<String, dynamic> ? user : <String, dynamic>{};

    final userId = (data['_id'] ?? userMap['_id'] ?? '').toString();
    final role = (data['role'] ?? userMap['role'] ?? _appRole).toString();

    state = state.copyWith(
      fullName: (userMap['fullName'] ?? userMap['name'] ?? fullName.trim())
          .toString(),
      email: (userMap['email'] ?? normalizedEmail).toString(),
      phone: (userMap['phone'] ?? phone.trim()).toString(),
      password: password,
      rememberMe: true,
      isAuthenticated: true,
      onboardingCompleted: true,
      accessToken: accessToken.isEmpty ? null : accessToken,
      refreshToken: refreshToken.isEmpty ? null : refreshToken,
      userId: userId.isEmpty ? null : userId,
      role: role.isEmpty ? null : role,
    );

    await _persistSession(rememberMe: true);
    await _storage!.writeString(_AuthStorageKeys.password, password);

    _log('signUp:done', state);
  }

  Future<void> requestOtp(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    _logStep('requestOtp:start email=$normalizedEmail');

    final result = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
          '/auth/forgot-password',
          data: {'email': normalizedEmail},
          parser: _extractDataMap,
        );

    _unwrap(result);

    final now = DateTime.now();

    state = state.copyWith(
      pendingResetEmail: normalizedEmail,
      otpRequestedAt: now,
      otpVerified: false,
      clearVerifiedResetOtp: true,
    );

    await _storage!.writeString(
      _AuthStorageKeys.pendingResetEmail,
      normalizedEmail,
    );
    await _storage!.writeString(
      _AuthStorageKeys.otpRequestedAt,
      now.toIso8601String(),
    );
    await _storage!.writeBool(_AuthStorageKeys.otpVerified, false);
    await _storage!.remove(_AuthStorageKeys.verifiedResetOtp);

    _log('requestOtp:done', state);
  }

  Future<void> resendOtp() async {
    _logStep('resendOtp:start');

    if (state.pendingResetEmail == null) {
      _logStep('resendOtp:error no pending email');
      throw const AuthFlowException('Start the password reset flow again.');
    }

    if (state.secondsUntilResend > 0) {
      _logStep('resendOtp:error wait=${state.secondsUntilResend}s');
      throw AuthFlowException(
        'Resend available in ${state.secondsUntilResend}s.',
      );
    }

    await requestOtp(state.pendingResetEmail!);
    _log('resendOtp:done', state);
  }

  Future<void> verifyOtp(String otp) async {
    final enteredOtp = otp.trim();
    _logStep('verifyOtp:start otpLength=${enteredOtp.length}');

    if (!state.hasPendingOtp) {
      _logStep('verifyOtp:error no pending otp context');
      throw const AuthFlowException('Start the password reset flow again.');
    }

    final result = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
          '/auth/verify-otp',
          data: {'email': state.pendingResetEmail, 'otp': enteredOtp},
          parser: _extractDataMap,
        );

    _unwrap(result);

    state = state.copyWith(
      otpVerified: true,
      verifiedResetOtp: enteredOtp,
    );

    await _storage!.writeBool(_AuthStorageKeys.otpVerified, true);
    await _storage!.writeString(_AuthStorageKeys.verifiedResetOtp, enteredOtp);

    _log('verifyOtp:done', state);
  }

  Future<void> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    _logStep('resetPassword:start');

    if (!state.otpVerified ||
        state.pendingResetEmail == null ||
        state.verifiedResetOtp == null) {
      _logStep('resetPassword:error otp not verified');
      throw const AuthFlowException(
        'Verify the OTP before resetting password.',
      );
    }

    if (newPassword != confirmPassword) {
      _logStep('resetPassword:error password mismatch');
      throw const AuthFlowException('Passwords do not match.');
    }

    final result = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
          '/auth/reset-password',
          data: {
            'email': state.pendingResetEmail,
            'otp': state.verifiedResetOtp,
            'password': newPassword,
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
          },
          parser: _extractDataMap,
        );

    _unwrap(result);

    state = state.copyWith(
      password: newPassword,
      isAuthenticated: false,
      otpVerified: false,
      clearPendingResetEmail: true,
      clearOtpRequestedAt: true,
      clearVerifiedResetOtp: true,
      clearTokens: true,
    );

    await _storage!.writeString(_AuthStorageKeys.password, newPassword);
    await _storage!.writeBool(_AuthStorageKeys.isAuthenticated, false);
    await _storage!.writeBool(_AuthStorageKeys.otpVerified, false);
    await _storage!.remove(_AuthStorageKeys.pendingResetEmail);
    await _storage!.remove(_AuthStorageKeys.otpRequestedAt);
    await _storage!.remove(_AuthStorageKeys.verifiedResetOtp);
    await _storage!.remove(_AuthStorageKeys.accessToken);
    await _storage!.remove(_AuthStorageKeys.refreshToken);
    await _storage!.remove(_AuthStorageKeys.userId);
    await _storage!.remove(_AuthStorageKeys.role);

    _log('resetPassword:done', state);
  }

  Future<void> logout() async {
    _logStep('logout:start');

    // Drop this device's push token while we still hold a valid session.
    try {
      await ref.read(pushNotificationServiceProvider).unregister();
    } catch (e) {
      _logStep('logout:push-unregister-failed $e');
    }

    if (state.accessToken != null && state.accessToken!.isNotEmpty) {
      await ref.read(apiClientProvider).post<dynamic>(
            '/auth/logout',
            options: Options(
              headers: {'Authorization': 'Bearer ${state.accessToken!}'},
            ),
          );
    }

    await _clearSession();
    _log('logout:done', state);
  }

  Future<void> updateProfileBasics({
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(
      fullName: fullName.trim().isEmpty ? state.fullName : fullName.trim(),
      phone: phone == null ? state.phone : phone.trim(),
    );

    await _storage!.writeString(_AuthStorageKeys.fullName, state.fullName);
    await _storage!.writeString(_AuthStorageKeys.phone, state.phone);

    _log('updateProfileBasics:done', state);
  }

  Future<void> _persistSession({required bool rememberMe}) async {
    await _storage!.writeBool(_AuthStorageKeys.isAuthenticated, true);
    await _storage!.writeBool(_AuthStorageKeys.rememberMe, rememberMe);
    await _storage!.writeBool(_AuthStorageKeys.onboarding, true);
    await _storage!.writeString(_AuthStorageKeys.fullName, state.fullName);
    await _storage!.writeString(_AuthStorageKeys.email, state.email);
    await _storage!.writeString(_AuthStorageKeys.phone, state.phone);

    if (state.userId != null) {
      await _storage!.writeString(_AuthStorageKeys.userId, state.userId!);
    }

    if (state.role != null) {
      await _storage!.writeString(_AuthStorageKeys.role, state.role!);
    }

    if (state.accessToken != null) {
      await _storage!.writeString(
        _AuthStorageKeys.accessToken,
        state.accessToken!,
      );
    }

    if (state.refreshToken != null) {
      await _storage!.writeString(
        _AuthStorageKeys.refreshToken,
        state.refreshToken!,
      );
    }
  }

  Future<void> _clearSession() async {
    state = state.copyWith(
      isAuthenticated: false,
      clearTokens: true,
    );

    await _storage!.writeBool(_AuthStorageKeys.isAuthenticated, false);
    await _storage!.remove(_AuthStorageKeys.accessToken);
    await _storage!.remove(_AuthStorageKeys.refreshToken);
    await _storage!.remove(_AuthStorageKeys.userId);
    await _storage!.remove(_AuthStorageKeys.role);
  }

  void _logStep(String message) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[AUTH] $message\n');
  }

  void _log(String label, AuthState current) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[AUTH][STATE][$label] ${_snapshot(current)}\n');
  }

  String _snapshot(AuthState s) {
    return '{isAuthenticated:${s.isAuthenticated}, '
        'onboardingCompleted:${s.onboardingCompleted}, '
        'email:${s.email}, '
        'fullName:${s.fullName}, '
        'userId:${s.userId}, '
        'role:${s.role}, '
        'hasAccessToken:${(s.accessToken ?? '').isNotEmpty}, '
        'hasRefreshToken:${(s.refreshToken ?? '').isNotEmpty}, '
        'rememberMe:${s.rememberMe}, '
        'pendingResetEmail:${s.pendingResetEmail}, '
        'otpRequestedAt:${s.otpRequestedAt}, '
        'otpVerified:${s.otpVerified}, '
        'hasVerifiedResetOtp:${(s.verifiedResetOtp ?? '').isNotEmpty}}';
  }
}

Map<String, dynamic> _extractDataMap(dynamic raw) {
  if (raw is! Map<String, dynamic>) {
    throw const AuthFlowException('Unexpected server response.');
  }

  if (raw['success'] == false) {
    final message =
        (raw['message'] ?? 'Request could not be completed.').toString();
    throw AuthFlowException(message);
  }

  final data = raw['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }

  return <String, dynamic>{};
}

Map<String, dynamic> _unwrap(Result<Map<String, dynamic>> result) {
  return switch (result) {
    Success(data: final data) => data,
    ResultFailure(error: final error) => throw AuthFlowException(
        error.message,
        isNetworkError: error.isNetworkError,
      ),
  };
}

final class AuthFlowException implements Exception {
  const AuthFlowException(this.message, {this.isNetworkError = false});

  final String message;

  /// True when the failure was caused by the device being offline / unable to
  /// reach the server, as opposed to a validation or backend error.
  final bool isNetworkError;

  @override
  String toString() => message;
}

final class _AuthStorageKeys {
  const _AuthStorageKeys._();

  static const onboarding = 'buyer_onboarding_completed';
  static const isAuthenticated = 'buyer_is_authenticated';
  static const fullName = 'buyer_full_name';
  static const email = 'buyer_email';
  static const phone = 'buyer_phone';
  static const password = 'buyer_password';
  static const rememberMe = 'buyer_remember_me';
  static const accessToken = 'buyer_access_token';
  static const refreshToken = 'buyer_refresh_token';
  static const userId = 'buyer_user_id';
  static const role = 'buyer_role';
  static const pendingResetEmail = 'buyer_pending_reset_email';
  static const otpRequestedAt = 'buyer_otp_requested_at';
  static const otpVerified = 'buyer_otp_verified';
  static const verifiedResetOtp = 'buyer_verified_reset_otp';
}