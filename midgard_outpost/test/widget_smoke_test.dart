// test/widget_smoke_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';

void main() {
  testWidgets('app shows hub title', (tester) async {
    await tester.pumpWidget(const MidgardApp());
    expect(find.text('Мидгард: Аванпост'), findsOneWidget);
  });
}
