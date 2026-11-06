import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:novva_app/main.dart' as app;

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('review account logs in from a clean installation',
      (tester) async {
    const password = String.fromEnvironment('APPLE_REVIEW_PASSWORD');
    expect(password, isNotEmpty, reason: 'Provide APPLE_REVIEW_PASSWORD.');

    await app.main();
    await waitFor(tester, find.text('CPF'));

    expect(find.text('CPF'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, '52998224725');
    await tester.tap(find.text('Continuar'));
    await waitFor(tester, find.text('Senha'));

    expect(find.text('Senha'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).first, password);
    await tester.tap(find.text('Entrar'));
    await waitFor(tester, find.textContaining('Olá'));

    expect(find.textContaining('Olá'), findsWidgets);
    expect(find.text('Início'), findsOneWidget);
  });
}
