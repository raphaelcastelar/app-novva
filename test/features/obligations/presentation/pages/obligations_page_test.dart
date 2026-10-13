import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:novva_app/app/theme/app_theme.dart';
import 'package:novva_app/features/obligations/domain/entities/obligation.dart';
import 'package:novva_app/features/obligations/presentation/pages/obligations_page.dart';
import 'package:novva_app/features/obligations/presentation/providers/obligations_providers.dart';

void main() {
  testWidgets('shows monthly guide actions without overflowing on an iPhone',
      (tester) async {
    await initializeDateFormatting('pt_BR');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final guide = Obligation(
      id: 'guide-1',
      name: 'DAS Simples Nacional',
      dueDate: DateTime(now.year, now.month, 20),
      amount: 1280.50,
      status: ObligationStatus.dueSoon,
      hasFile: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          obligationListProvider.overrideWith((ref) async => [guide]),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ObligationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Central de guias'), findsOneWidget);
    expect(find.text('Baixar guia'), findsOneWidget);
    expect(find.text('Recalcular guia'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Recalcular guia'),
          )
          .onPressed,
      isNotNull,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Baixar guia'), findsOneWidget);
    expect(find.text('Gerar guia'), findsOneWidget);
    expect(find.text('Recalcular guia'), findsNWidgets(2));
    final recalculationButtons = tester.widgetList<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Recalcular guia'),
    );
    expect(recalculationButtons.where((button) => button.onPressed == null),
        hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
