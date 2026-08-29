import 'package:flutter/material.dart';

/// Flat mobile hub palette — skills-canon reference.
abstract final class HubTheme {
  static const cardBackground = Color(0xFFFFF8E7);
  static const cardBackgroundAlt = Color(0xFFF5E6C8);
  static const panelBackground = Color(0xFFF5E6C8);
  static const borderBrown = Color(0xFFC4A574);
  static const borderBrownDark = Color(0xFF8B6914);
  static const textBrown = Color(0xFF5C4033);
  static const textMuted = Color(0xFF8B7355);
  static const goldAccent = Color(0xFFD4A017);
  static const goldAccentDark = Color(0xFFB8860B);
  static const pipFilled = Color(0xFFE6A23C);
  static const pipEmpty = Color(0xFFD4C4A8);
  static const ultRed = Color(0xFFC0392B);

  static const cardRadius = 12.0;
  static const contentPadding = EdgeInsets.all(12);

  static BoxDecoration panelDecoration({double radius = 16}) => BoxDecoration(
        color: panelBackground.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderBrown, width: 1.5),
      );

  static BoxDecoration cardDecoration() => BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: borderBrown, width: 1),
      );

  static TextStyle pointsHeaderStyle(TextTheme theme) =>
      theme.titleMedium?.copyWith(
        color: goldAccentDark,
        fontWeight: FontWeight.bold,
      ) ??
      const TextStyle(
        color: goldAccentDark,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      );

  static TextStyle cardTitleStyle(TextTheme theme) =>
      theme.titleSmall?.copyWith(
        color: textBrown,
        fontWeight: FontWeight.bold,
      ) ??
      const TextStyle(
        color: textBrown,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );

  static TextStyle cardSubtitleStyle(TextTheme theme) =>
      theme.bodySmall?.copyWith(color: textMuted) ??
      const TextStyle(color: textMuted, fontSize: 12);

  static ButtonStyle goldButtonStyle({double? height}) =>
      FilledButton.styleFrom(
        backgroundColor: goldAccent,
        foregroundColor: textBrown,
        minimumSize: height != null ? Size.fromHeight(height) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

class HubTabBody extends StatelessWidget {
  const HubTabBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: HubTheme.contentPadding,
      child: DefaultTextStyle(
        style: const TextStyle(color: HubTheme.textBrown),
        child: child,
      ),
    );
  }
}

class HubCard extends StatelessWidget {
  const HubCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: HubTheme.cardDecoration(),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class HubPointsHeader extends StatelessWidget {
  const HubPointsHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: HubTheme.pointsHeaderStyle(Theme.of(context).textTheme),
      ),
    );
  }
}

class HubRankPips extends StatelessWidget {
  const HubRankPips({
    super.key,
    required this.rank,
    required this.maxRank,
  });

  final int rank;
  final int maxRank;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < maxRank; i++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: i < rank ? HubTheme.pipFilled : HubTheme.pipEmpty,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: HubTheme.borderBrown.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class HubIncrementButton extends StatelessWidget {
  const HubIncrementButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? HubTheme.goldAccent : HubTheme.pipEmpty,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.add, size: 18, color: HubTheme.textBrown),
        ),
      ),
    );
  }
}

class HubUltBadge extends StatelessWidget {
  const HubUltBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: HubTheme.ultRed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Ульт',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
