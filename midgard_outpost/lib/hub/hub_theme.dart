import 'package:flutter/material.dart';

/// Dark dock hub palette — Living Stage + Side Command Dock (art direction canon).
abstract final class HubTheme {
  // §2 locked tokens
  static const overlayEdge = Color(0xFF0F172A);
  static const panelBg = Color(0xFF1E293B);
  static const panelBgSolid = Color(0xFF1E293B);
  static const railBg = Color(0xFF0F172A);
  static const cardBg = Color(0xFF334155);
  static const cardBgAlt = Color(0xFF475569);
  static const border = Color(0xFF475569);
  static const accent = Color(0xFFE69526);
  static const accentPressed = Color(0xFFC47A1A);
  static const accentMuted = Color(0x40E69526);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFCBD5E1);
  static const textMuted = Color(0xFF94A3B8);
  static const danger = Color(0xFFDC2626);
  static const hp = Color(0xFF22C55E);
  static const sp = Color(0xFF38BDF8);
  static const gold = Color(0xFFFBBF24);
  static const crystal = Color(0xFF67E8F9);

  // Legacy API aliases — keep tab code working until Task 2 restyle
  static const cardBackground = cardBg;
  static const cardBackgroundAlt = cardBgAlt;
  static const panelBackground = panelBg;
  static const borderBrown = border;
  static const borderBrownDark = cardBgAlt;
  static const textBrown = textPrimary;
  static const goldAccent = accent;
  static const goldAccentDark = accentPressed;
  static const pipFilled = accent;
  static const pipEmpty = cardBgAlt;
  static const ultRed = danger;

  static const cardRadius = 12.0;
  static const dockRadius = 16.0;
  static const railWidth = 72.0;
  static const ctaHeight = 56.0;
  static const contentPadding = EdgeInsets.all(12);

  static BoxDecoration panelDecoration({double radius = dockRadius}) => BoxDecoration(
        color: panelBg.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(radius),
      );

  static BoxDecoration cardDecoration() => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: border, width: 1),
      );

  static BoxDecoration chipDecoration() => BoxDecoration(
        color: overlayEdge.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      );

  static TextStyle pointsHeaderStyle(TextTheme theme) =>
      theme.titleMedium?.copyWith(
        color: accent,
        fontWeight: FontWeight.bold,
      ) ??
      const TextStyle(
        color: accent,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      );

  static TextStyle cardTitleStyle(TextTheme theme) =>
      theme.titleSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ) ??
      const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      );

  static TextStyle cardSubtitleStyle(TextTheme theme) =>
      theme.bodySmall?.copyWith(color: textSecondary) ??
      const TextStyle(color: textSecondary, fontSize: 12);

  static ButtonStyle goldButtonStyle({double? height}) => accentButtonStyle(height: height);

  static ButtonStyle accentButtonStyle({double? height}) => FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: overlayEdge,
        minimumSize: height != null ? Size.fromHeight(height) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
        style: const TextStyle(color: HubTheme.textPrimary),
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
                  color: HubTheme.border.withValues(alpha: 0.5),
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
      color: enabled ? HubTheme.accent : HubTheme.accentMuted,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.add, size: 18, color: HubTheme.overlayEdge),
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
        color: HubTheme.danger,
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

class HubResourceChip extends StatelessWidget {
  const HubResourceChip({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: HubTheme.chipDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: HubTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
