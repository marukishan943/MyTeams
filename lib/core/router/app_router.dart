import 'package:go_router/go_router.dart';
import '../../screens/splash_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/signup_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/otp_verification_screen.dart';
import '../../screens/reset_password_screen.dart';
import '../../screens/change_password_screen.dart';
import '../../screens/success_screen.dart';

/// Declarative routing configuration using GoRouter.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/otp',
      name: 'otp',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return OtpVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/change-password',
      name: 'change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/success',
      name: 'success',
      builder: (context, state) {
        final message = state.uri.queryParameters['message'] ?? '';
        final buttonText = state.uri.queryParameters['buttonText'] ?? '';
        final isLoginFlow = state.uri.queryParameters['isLoginFlow'] == 'true';
        final showChangePassword = state.uri.queryParameters['showChangePassword'] == 'true';
        return SuccessScreen(
          message: message,
          buttonText: buttonText,
          isLoginFlow: isLoginFlow,
          showChangePassword: showChangePassword,
        );
      },
    ),
  ],
);


