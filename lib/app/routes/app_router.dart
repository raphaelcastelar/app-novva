import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/create_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_cpf_page.dart';
import '../../features/auth/presentation/pages/login_password_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/cnpjs/presentation/pages/manage_cnpjs_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/documents/presentation/pages/document_details_page.dart';
import '../../features/documents/presentation/pages/document_upload_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/invoices/presentation/pages/invoice_description_page.dart';
import '../../features/invoices/presentation/pages/invoice_request_page.dart';
import '../../features/medical_profile/presentation/pages/medical_profile_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/obligations/presentation/pages/obligation_details_page.dart';
import '../../features/obligations/presentation/pages/obligations_page.dart';
import '../../features/payments/presentation/pages/payments_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/splash_page.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_state.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  refreshListenable: authListenable,
  redirect: (context, state) {
    final loggedIn = authListenable.isAuthenticated;
    final authPath = state.matchedLocation.startsWith('/login');
    if (!loggedIn && !_isPublic(state.matchedLocation)) {
      return RouteNames.loginCpf;
    }
    if (loggedIn && authPath) {
      return RouteNames.dashboard;
    }
    return null;
  },
  routes: [
    _appRoute(RouteNames.splash, (_, __) => const SplashPage()),
    _appRoute(RouteNames.loginCpf, (_, __) => const LoginCpfPage()),
    _appRoute(
      RouteNames.loginPassword,
      (_, state) =>
          LoginPasswordPage(cpf: state.uri.queryParameters['cpf'] ?? ''),
    ),
    _appRoute(
      RouteNames.createPassword,
      (_, state) =>
          CreatePasswordPage(cpf: state.uri.queryParameters['cpf'] ?? ''),
    ),
    _appRoute(RouteNames.forgotPassword, (_, __) => const ForgotPasswordPage()),
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          extendBody: true,
          body: child,
          bottomNavigationBar: const AppBottomNav(),
        );
      },
      routes: [
        _appRoute(RouteNames.dashboard, (_, __) => const DashboardPage()),
        _appRoute(RouteNames.documents, (_, __) => const DocumentsPage()),
        _appRoute(
            RouteNames.documentDetails, (_, __) => const DocumentDetailsPage()),
        _appRoute(
            RouteNames.documentUpload, (_, __) => const DocumentUploadPage()),
        _appRoute(RouteNames.obligations, (_, __) => const ObligationsPage()),
        _appRoute(RouteNames.obligationDetails,
            (_, __) => const ObligationDetailsPage()),
        _appRoute(RouteNames.payments, (_, __) => const PaymentsPage()),
        _appRoute(RouteNames.reports, (_, __) => const ReportsPage()),
        _appRoute(RouteNames.chat, (_, __) => const ChatPage()),
        _appRoute(RouteNames.profile, (_, __) => const MedicalProfilePage()),
        _appRoute(
            RouteNames.notifications, (_, __) => const NotificationsPage()),
        _appRoute(RouteNames.settings, (_, __) => const SettingsPage()),
        _appRoute(RouteNames.cnpjs, (_, __) => const ManageCnpjsPage()),
        _appRoute(RouteNames.invoices, (_, __) => const InvoiceRequestPage()),
        _appRoute(RouteNames.invoiceDescription,
            (_, __) => const InvoiceDescriptionPage()),
        _appRoute(RouteNames.clients, (_, __) => const ClientsPage()),
      ],
    ),
    _appRoute(
      RouteNames.offline,
      (_, __) => const ErrorState(message: 'Sem conexão com a internet.'),
    ),
  ],
);

bool _isPublic(String path) {
  return path == RouteNames.splash || path.startsWith('/login');
}

GoRoute _appRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder,
) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => _SmoothPage(
      key: state.pageKey,
      child: builder(context, state),
    ),
  );
}

class _SmoothPage extends CustomTransitionPage<void> {
  _SmoothPage({
    required super.key,
    required super.child,
  }) : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(curvedAnimation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.018, 0.012),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}
