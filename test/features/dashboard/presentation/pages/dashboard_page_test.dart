import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:novva_app/app/theme/app_theme.dart';
import 'package:novva_app/core/widgets/novva_brand_mark.dart';
import 'package:novva_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:novva_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:novva_app/features/notices/presentation/providers/notices_providers.dart';
import 'package:novva_app/features/notices/domain/entities/notice_item.dart';

void main() {
  for (final longNotice in [false, true]) {
    testWidgets(
        'notice opens above nested navigation with full width (long: $longNotice)',
        (tester) async {
      await initializeDateFormatting('pt_BR');
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final observer = _RouteObserver();
      final notice = NoticeItem(
        id: 'notice-test',
        title: 'Teste',
        description: longNotice
            ? List.filled(80, 'Descrição extensa do comunicado.').join('\n')
            : 'teste descrição',
        createdAt: DateTime(2026, 10, 12),
        isRead: true,
        hasAttachment: longNotice,
        attachmentOriginalName:
            'nome_de_arquivo_muito_longo_para_a_tela_do_iphone.pdf',
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) async =>
              const DashboardSummary(
                  pendingDocuments: 0,
                  dueObligations: 0,
                  monthRevenue: 0,
                  orders: 0,
                  nextObligation: null)),
          noticesProvider.overrideWith((ref) async => [notice]),
        ],
        child: MaterialApp(
            theme: AppTheme.light,
            navigatorObservers: [observer],
            home: Scaffold(
                body: Navigator(
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => const DashboardPage())),
                bottomNavigationBar: const SizedBox(
                    height: 80, child: Text('Menu do aplicativo')))),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Teste'));
      await tester.tap(find.text('Teste'));
      await tester.pumpAndSettle();
      expect(observer.lastRoute, isA<ModalBottomSheetRoute<dynamic>>());
      expect(tester.getSize(find.byType(BottomSheet)).width, 390);
      expect(tester.takeException(), isNull);
      if (longNotice) {
        final scroll = find.descendant(
            of: find.byType(BottomSheet), matching: find.byType(Scrollable));
        await tester.scrollUntilVisible(find.text('Baixar anexo'), 400,
            scrollable: scroll);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.byTooltip('Fechar aviso'), -400,
            scrollable: scroll);
      }
      await tester.tap(find.byTooltip('Fechar aviso'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });
  }
  testWidgets('shows revenue and notices without overflowing on an iPhone',
      (tester) async {
    await initializeDateFormatting('pt_BR');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    const summary = DashboardSummary(
      pendingDocuments: 2,
      dueObligations: 1,
      monthRevenue: 12850.75,
      orders: 4,
      nextObligation: null,
    );
    final data = DashboardSummary(
      pendingDocuments: summary.pendingDocuments,
      dueObligations: summary.dueObligations,
      monthRevenue: summary.monthRevenue,
      orders: summary.orders,
      nextObligation: DashboardObligation(
        name: 'DAS Simples Nacional',
        dueDate: DateTime(now.year, now.month, 20),
        amount: 1280.50,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) async => data),
          noticesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('R\$ 12.850,75'), findsOneWidget);
    expect(find.text('Quadro de avisos'), findsOneWidget);
    expect(find.text('Nenhum aviso publicado'), findsOneWidget);
    expect(find.text('Emitir nota'), findsOneWidget);
    expect(find.byType(NovvaBrandMark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RouteObserver extends NavigatorObserver {
  Route<dynamic>? lastRoute;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastRoute = route;
  }
}
