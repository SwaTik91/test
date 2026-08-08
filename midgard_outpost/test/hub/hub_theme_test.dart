import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/hub/hub_theme.dart';

void main() {
  group('HubTheme', () {
    test('uses locked dark tokens, not cream parchment', () {
      expect(HubTheme.cardBackground, const Color(0xFF334155));
      expect(HubTheme.cardBackgroundAlt, const Color(0xFF475569));
      expect(HubTheme.panelBackground, const Color(0xFF1E293B));
      expect(HubTheme.accent, const Color(0xFFE69526));
      expect(HubTheme.textPrimary, const Color(0xFFF8FAFC));

      const forbidden = [
        Color(0xFFFFF8E7),
        Color(0xFFF5E6C8),
        Color(0xFF5C4033),
      ];
      for (final color in forbidden) {
        expect(HubTheme.cardBackground, isNot(color));
        expect(HubTheme.panelBackground, isNot(color));
        expect(HubTheme.textBrown, isNot(color));
      }
    });

    testWidgets('HubCard renders dark card with slate border', (tester) async {
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
      expect(decoration.color, HubTheme.cardBg);
      expect(
        (decoration.border as Border).top.color,
        HubTheme.border,
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

    testWidgets('HubResourceChip uses dark chip fill', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HubResourceChip(
              icon: Icons.monetization_on,
              iconColor: HubTheme.gold,
              value: '100',
            ),
          ),
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(HubResourceChip),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = decorated.decoration! as BoxDecoration;
      expect(decoration.color, HubTheme.overlayEdge.withValues(alpha: 0.72));
    });
  });
}
