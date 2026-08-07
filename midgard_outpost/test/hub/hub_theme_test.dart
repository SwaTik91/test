import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/hub/hub_theme.dart';

void main() {
  group('HubTheme', () {
    test('defines skills-canon palette tokens', () {
      expect(HubTheme.cardBackground, const Color(0xFFFFF8E7));
      expect(HubTheme.cardBackgroundAlt, const Color(0xFFF5E6C8));
      expect(HubTheme.borderBrown, const Color(0xFFC4A574));
      expect(HubTheme.goldAccent, const Color(0xFFD4A017));
    });

    testWidgets('HubCard renders cream card with brown border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HubCard(
              child: Text('test'),
            ),
          ),
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(HubCard),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = decorated.decoration! as BoxDecoration;
      expect(decoration.color, HubTheme.cardBackground);
      expect(
        (decoration.border as Border).top.color,
        HubTheme.borderBrown,
      );
    });

    testWidgets('HubRankPips shows filled pips for rank', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HubRankPips(rank: 3, maxRank: 10),
          ),
        ),
      );

      final pips = find.byType(Container);
      expect(pips, findsNWidgets(10));
    });
  });
}
