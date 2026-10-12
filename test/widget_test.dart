import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novva_app/app/app.dart';
import 'package:novva_app/core/widgets/novva_brand_mark.dart';

void main() {
  testWidgets('renders login cpf screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NovvaApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Acesse sua área contábil'), findsOneWidget);
    expect(find.text('Informe seu CPF'), findsOneWidget);
    expect(find.byType(NovvaBrandMark), findsNothing);
  });
}
