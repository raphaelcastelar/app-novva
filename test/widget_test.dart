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

    expect(find.text('Acesse sua área contábil'), findsOneWidget);
    expect(find.text('Informe seu CPF'), findsOneWidget);
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

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('Dr. Matheus'), findsOneWidget);
    expect(find.text('128.311.467-47'), findsOneWidget);
    expect(find.text('Acessar'), findsOneWidget);
    expect(find.text('Acessar com outra conta'), findsOneWidget);
    expect(find.text('Informe seu CPF'), findsNothing);

    await tester.tap(find.text('Acessar com outra conta'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu CPF'), findsOneWidget);
  });
}
