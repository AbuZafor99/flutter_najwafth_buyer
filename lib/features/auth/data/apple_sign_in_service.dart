import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appleSignInServiceProvider = Provider<AppleSignInService>(
  (_) => FirebaseAppleSignInService(FirebaseAuth.instance),
);

final class AppleIdentity {
  const AppleIdentity({required this.idToken, this.name});

  final String idToken;
  final String? name;
}

abstract interface class AppleSignInService {
  Future<AppleIdentity> signIn();
  Future<void> revokeAuthorizationIfNeeded();
  Future<void> signOut();
}

final class FirebaseAppleSignInService implements AppleSignInService {
  const FirebaseAppleSignInService(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<AppleIdentity> signIn() async {
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final credential = await _auth.signInWithProvider(provider);
      final user = credential.user;
      final idToken = await user?.getIdToken(true);

      if (user == null || idToken == null || idToken.isEmpty) {
        throw const AppleSignInException(
          'Apple sign-in did not return a valid account.',
        );
      }

      return AppleIdentity(idToken: idToken, name: user.displayName);
    } on FirebaseAuthException catch (error) {
      throw AppleSignInException.fromFirebase(error);
    }
  }

  @override
  Future<void> revokeAuthorizationIfNeeded() async {
    final user = _auth.currentUser;
    final usesApple = user?.providerData.any(
      (provider) => provider.providerId == 'apple.com',
    );
    if (user == null || usesApple != true) return;

    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final credential = await user.reauthenticateWithProvider(provider);
      final authorizationCode =
          credential.additionalUserInfo?.authorizationCode;
      if (authorizationCode == null || authorizationCode.isEmpty) {
        throw const AppleSignInException(
          'Apple did not return an authorization code. Please try again.',
        );
      }
      await _auth.revokeTokenWithAuthorizationCode(authorizationCode);
    } on FirebaseAuthException catch (error) {
      throw AppleSignInException.fromFirebase(error);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

final class AppleSignInException implements Exception {
  const AppleSignInException(this.message, {this.isCancelled = false});

  factory AppleSignInException.fromFirebase(FirebaseAuthException error) {
    const cancelledCodes = {
      'canceled',
      'cancelled',
      'web-context-cancelled',
      'popup-closed-by-user',
    };
    if (cancelledCodes.contains(error.code)) {
      return const AppleSignInException(
        'Apple sign-in was cancelled.',
        isCancelled: true,
      );
    }

    return AppleSignInException(
      error.message ?? 'Apple sign-in could not be completed.',
    );
  }

  final String message;
  final bool isCancelled;
}
