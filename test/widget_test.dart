import 'dart:ui' show Size;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novva_app/app/app.dart';
import 'package:novva_app/app/routes/app_router.dart';
import 'package:novva_app/app/routes/route_names.dart';
import 'package:novva_app/core/widgets/novva_brand_mark.dart';

void main() {
  testWidgets('renders login cpf screen', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    appRouter.go(RouteNames.loginCpf);
    addTearDown(() => appRouter.go(RouteNames.splash));
    await tester.pumpWidget(const ProviderScope(child: NovvaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Gestão médica,'), findsOneWidget);
    expect(find.text('CPF'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Entrar com Face ID'), findsNothing);
    expect(find.byType(NovvaBrandMark), findsNothing);
  });

  testWidgets('shows the saved account without filling the CPF field',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access-token',
      'refresh_token': 'refresh-token',
      'cpf': '12831146747',
      'user_name': 'Dr. Matheus',
      'face_id_enabled': 'true',
    });
    appRouter.go(RouteNames.loginCpf);
    addTearDown(() => appRouter.go(RouteNames.splash));
    await tester.pumpWidget(const ProviderScope(child: NovvaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Continuar como'), findsOneWidget);
    expect(find.text('Dr. Matheus'), findsOneWidget);
    expect(find.text('CPF: 128.311.467-47'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Alterar conta'), findsOneWidget);
    expect(find.text('CPF'), findsNothing);

    await tester.tap(find.text('Alterar conta'));
    await tester.pumpAndSettle();

    expect(find.text('CPF'), findsOneWidget);
  });

  testWidgets('compacts the authentication header when the keyboard opens',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    appRouter.go(RouteNames.loginCpf);
    addTearDown(() => appRouter.go(RouteNames.splash));

    await tester.pumpWidget(const ProviderScope(child: NovvaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Médica sorrindo no consultório'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    expect(find.text('Médica sorrindo no consultório'), findsNothing);
    expect(find.text('Novva'), findsOneWidget);
    expect(find.text('CPF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
