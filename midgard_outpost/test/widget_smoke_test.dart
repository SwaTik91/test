import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app shows hub title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MidgardApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Мидгард: Аванпост'), findsOneWidget);
  });
}
