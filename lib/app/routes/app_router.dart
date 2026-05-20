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
    GoRoute(path: RouteNames.splash, builder: (_, __) => const SplashPage()),
    GoRoute(
        path: RouteNames.loginCpf, builder: (_, __) => const LoginCpfPage()),
    GoRoute(
      path: RouteNames.loginPassword,
      builder: (_, state) =>
          LoginPasswordPage(cpf: state.uri.queryParameters['cpf'] ?? ''),
    ),
    GoRoute(
      path: RouteNames.createPassword,
      builder: (_, state) =>
          CreatePasswordPage(cpf: state.uri.queryParameters['cpf'] ?? ''),
    ),
    GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage()),
    GoRoute(
        path: RouteNames.dashboard, builder: (_, __) => const DashboardPage()),
    GoRoute(
        path: RouteNames.documents, builder: (_, __) => const DocumentsPage()),
    GoRoute(
        path: RouteNames.documentDetails,
        builder: (_, __) => const DocumentDetailsPage()),
    GoRoute(
        path: RouteNames.documentUpload,
        builder: (_, __) => const DocumentUploadPage()),
    GoRoute(
        path: RouteNames.obligations,
        builder: (_, __) => const ObligationsPage()),
    GoRoute(
        path: RouteNames.obligationDetails,
        builder: (_, __) => const ObligationDetailsPage()),
    GoRoute(
        path: RouteNames.payments, builder: (_, __) => const PaymentsPage()),
    GoRoute(path: RouteNames.reports, builder: (_, __) => const ReportsPage()),
    GoRoute(path: RouteNames.chat, builder: (_, __) => const ChatPage()),
    GoRoute(
        path: RouteNames.profile,
        builder: (_, __) => const MedicalProfilePage()),
    GoRoute(
        path: RouteNames.notifications,
        builder: (_, __) => const NotificationsPage()),
    GoRoute(
        path: RouteNames.settings, builder: (_, __) => const SettingsPage()),
    GoRoute(
        path: RouteNames.cnpjs, builder: (_, __) => const ManageCnpjsPage()),
    GoRoute(
        path: RouteNames.invoices,
        builder: (_, __) => const InvoiceRequestPage()),
    GoRoute(
        path: RouteNames.invoiceDescription,
        builder: (_, __) => const InvoiceDescriptionPage()),
    GoRoute(path: RouteNames.clients, builder: (_, __) => const ClientsPage()),
    GoRoute(
        path: RouteNames.offline,
        builder: (_, __) =>
            const ErrorState(message: 'Sem conexão com a internet.')),
  ],
);

bool _isPublic(String path) {
  return path == RouteNames.splash || path.startsWith('/login');
}
