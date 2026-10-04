import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../features/crm/presentation/screens/leads_screen.dart';
import '../../features/crm/presentation/screens/add_lead_screen.dart';
import '../../features/crm/presentation/screens/dashboard_screen.dart';
import '../../features/crm/presentation/screens/lead_detail_screen.dart';
import '../../features/crm/presentation/screens/sales_screen.dart';
import '../../features/crm/presentation/screens/add_proforma_invoice_screen.dart';
import '../../features/crm/presentation/screens/customers_screen.dart';
import '../../features/crm/presentation/screens/add_customer_screen.dart';
import '../../features/crm/presentation/bloc/lead_bloc.dart';
import '../../features/crm/presentation/bloc/lead_event.dart';
import '../../features/crm/presentation/bloc/lead_detail_bloc.dart';
import '../../features/crm/presentation/bloc/sales_bloc.dart';
import '../../features/crm/presentation/bloc/customer_bloc.dart';
import '../../features/crm/presentation/bloc/customer_event.dart';
import '../di/injection_container.dart';

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
        final showChangePassword =
            state.uri.queryParameters['showChangePassword'] == 'true';
        return SuccessScreen(
          message: message,
          buttonText: buttonText,
          isLoginFlow: isLoginFlow,
          showChangePassword: showChangePassword,
        );
      },
    ),

    // ─── CRM Routes ──────────────────────────────────────────────────
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/leads',
      name: 'leads',
      builder: (context, state) => BlocProvider.value(
        value: sl<LeadBloc>()..add(const LoadLeads()),
        child: const LeadsScreen(),
      ),
    ),
    GoRoute(
      path: '/leads/add',
      name: 'add-lead',
      builder: (context, state) => BlocProvider.value(
        value: sl<LeadBloc>(),
        child: const AddLeadScreen(),
      ),
    ),
    GoRoute(
      path: '/leads/:id',
      name: 'lead-detail',
      builder: (context, state) {
        final leadId = state.pathParameters['id']!;
        final leadBloc = sl<LeadBloc>();
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: leadBloc),
            BlocProvider(
              create: (_) => LeadDetailBloc(
                leadRepository: sl(),
                leadBloc: leadBloc,
              ),
            ),
          ],
          child: LeadDetailScreen(leadId: leadId),
        );
      },
    ),
    GoRoute(
      path: '/sales',
      name: 'sales',
      builder: (context, state) => BlocProvider(
        create: (_) => SalesBloc()..add(LoadSales()),
        child: const SalesScreen(),
      ),
    ),
    GoRoute(
      path: '/sales/add-proforma',
      name: 'add-proforma-invoice',
      builder: (context, state) => const AddProformaInvoiceScreen(),
    ),
    GoRoute(
      path: '/customers',
      name: 'customers',
      builder: (context, state) => BlocProvider.value(
        value: sl<CustomerBloc>()..add(const LoadCustomers()),
        child: const CustomersScreen(),
      ),
    ),
    GoRoute(
      path: '/customers/add',
      name: 'add-customer',
      builder: (context, state) => BlocProvider.value(
        value: sl<CustomerBloc>(),
        child: const AddCustomerScreen(),
      ),
    ),
  ],
);
