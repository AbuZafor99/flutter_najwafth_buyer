final class AuthRoutes {
  const AuthRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const enterOtp = '/enter-otp';
  static const resetPassword = '/reset-password';
  static const home = '/home';

  static String bookDetails(String id) => '/books/$id';
}
