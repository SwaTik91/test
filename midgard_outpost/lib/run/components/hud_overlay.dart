import 'package:flutter/material.dart';

import '../../art/art_atlas.dart';
import '../../content/classes.dart';
import '../../content/skills.dart';
import '../../core/ids.dart';
import '../../hub/hub_theme.dart';
import '../midgard_run_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final MidgardRunGame game;

  /// Variant B combat plate — slightly wider than the old stacked card.
  @visibleForTesting
  static BoxConstraints panelConstraintsFor(Size screenSize) => BoxConstraints(
        maxWidth: screenSize.width * 0.30,
        maxHeight: screenSize.height * 0.22,
      );

  @visibleForTesting
  static List<Offset> skillOffsets(int count) =>
      _ActionCluster.skillOffsets(count);

  @visibleForTesting
  static String shortClassLabel(HeroClassId classId) => switch (classId) {
        HeroClassId.archer => 'лук',
        HeroClassId.mage => 'маг',
        HeroClassId.paladin => 'пал',
      };

  @visibleForTesting
  static String statusMetaLine({
    required int baseXp,
    required int jobXp,
    required int gold,
    required String biomeLabel,
  }) =>
      'XP $baseXp/$jobXp  ·  Золото $gold  ·  $biomeLabel';

  static String shortSkillLabel(SkillDef skill) => switch (skill.id) {
        'double_strafe' => 'ДС',
        'wind_arrow' => 'ВС',
        'concentrate' => 'Конц',
        'arrow_shower' => 'Град',
        'fire_bolt' => 'Огн',
        'frost' => 'Мор',
        'lightning' => 'Мол',
        'meteor' => 'Мет',
        'shield_bash' => 'Щит',
        'holy_strike' => 'Свят',
        'protection_aura' => 'Аура',
        'heaven_wrath' => 'Гнев',
        _ => skill.name.length <= 3
            ? skill.name
            : skill.name.substring(0, 3),
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.hudRevision,
      builder: (context, _, __) {
        if (!game.isRunReady) {
          return const SizedBox.shrink();
        }

        final rewards = game.currentRewards;
        final screen = MediaQuery.sizeOf(context);
        final hudConstraints = HudOverlay.panelConstraintsFor(screen);
        final skills = game.castableSkills;
        final classId = game.hero.classId;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: hudConstraints,
                    child: _StatusPlate(
                      portraitPath: ArtAtlas.heroIconPath(classId),
                      classLabel: shortClassLabel(classId),
                      className: ClassesCatalog.byId(classId).name,
                      hpLabel:
                          'HP  ${game.player.currentHp} / ${game.player.maxHp}',
                      hpValue: game.hpFraction,
                      spLabel:
                          'SP  ${game.player.currentSp} / ${game.player.maxSp}',
                      spValue: game.spFraction,
                      meta: statusMetaLine(
                        baseXp: rewards.baseXp,
                        jobXp: rewards.jobXp,
                        gold: rewards.gold,
                        biomeLabel: game.biomeLabel,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HoldButton(label: '<-', onChanged: game.setLeftPressed),
                      const SizedBox(width: 12),
                      _HoldButton(label: '->', onChanged: game.setRightPressed),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _ActionCluster(
                    skills: [
                      for (final skill in skills)
                        _SkillButton(
                          label: shortSkillLabel(skill),
                          iconPath: ArtAtlas.skillIconPath(skill.id),
                          cooldown: game.skillCooldownRemaining(skill.id),
                          enabled: game.skillRank(skill.id) > 0 &&
                              game.skillCooldownRemaining(skill.id) <= 0 &&
                              game.player.currentSp > 0,
                          onTap: () => game.tryCastSkill(skill.id),
                        ),
                    ],
                    jump: _ImageTapButton(
                      assetPath: ArtAtlas.btnJump,
                      onTap: game.jump,
                      size: 80,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Variant B — RO-lite combat plate: portrait + wide HP/SP + one meta line.
class _StatusPlate extends StatelessWidget {
  const _StatusPlate({
    required this.portraitPath,
    required this.classLabel,
    required this.className,
    required this.hpLabel,
    required this.hpValue,
    required this.spLabel,
    required this.spValue,
    required this.meta,
  });

  final String portraitPath;
  final String classLabel;
  final String className;
  final String hpLabel;
  final double hpValue;
  final String spLabel;
  final double spValue;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('hud-status-plate'),
      decoration: BoxDecoration(
        color: HubTheme.overlayEdge.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HubTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ClassPortrait(
              assetPath: portraitPath,
              label: classLabel,
              tooltip: className,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilledBar(
                    label: hpLabel,
                    value: hpValue,
                    color: HubTheme.hp,
                    height: 22,
                  ),
                  const SizedBox(height: 6),
                  _FilledBar(
                    label: spLabel,
                    value: spValue,
                    color: HubTheme.sp,
                    height: 18,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HubTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassPortrait extends StatelessWidget {
  const _ClassPortrait({
    required this.assetPath,
    required this.label,
    required this.tooltip,
  });

  final String assetPath;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 56,
        height: 64,
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: HubTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HubTheme.accent, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.5),
                  child: Image.asset(
                    ArtAtlas.flutterAsset(assetPath),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: HubTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledBar extends StatelessWidget {
  const _FilledBar({
    required this.label,
    required this.value,
    required this.color,
    required this.height,
  });

  final String label;
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final frac = value.clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: HubTheme.overlayEdge),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: frac,
              child: ColoredBox(color: color),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HubTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Color(0x88000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thumb cluster: large jump at bottom-right, skills in an arc above/left.
class _ActionCluster extends StatelessWidget {
  const _ActionCluster({
    required this.skills,
    required this.jump,
  });

  static const double width = 216;
  static const double height = 196;
  static const double skillSize = 52;

  final List<Widget> skills;
  final Widget jump;

  /// Skill top-left offsets inside the cluster (jump sits bottom-right).
  @visibleForTesting
  static List<Offset> skillOffsets(int count) {
    const slots = <Offset>[
      Offset(68, 132), // left of jump
      Offset(128, 60), // above jump
      Offset(60, 68), // upper-left
      Offset(8, 108), // far-left mid (ult)
    ];
    if (count <= slots.length) {
      return slots.take(count).toList(growable: false);
    }
    return [
      ...slots,
      for (var i = slots.length; i < count; i++)
        Offset(8.0 + ((i - slots.length) % 3) * 56, 8.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final offsets = skillOffsets(skills.length);
    return SizedBox(
      key: const Key('hud-action-cluster'),
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < skills.length; i++)
            Positioned(
              left: offsets[i].dx,
              top: offsets[i].dy,
              width: skillSize,
              height: skillSize,
              child: skills[i],
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: jump,
          ),
        ],
      ),
    );
  }
}

class _SkillButton extends StatelessWidget {
  const _SkillButton({
    required this.label,
    this.iconPath,
    required this.cooldown,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? iconPath;
  final double cooldown;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cdText = cooldown > 0 ? cooldown.ceil().toString() : null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xCC1A2740),
            border: Border.all(
              color: enabled ? const Color(0xFFE8C56A) : Colors.white38,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (iconPath != null)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      ArtAtlas.flutterAsset(iconPath!),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  )
                else
                  Text(
                    cdText ?? label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          cdText != null ? Colors.white70 : const Color(0xFFFFF1C2),
                      fontWeight: FontWeight.w800,
                      fontSize: cdText != null ? 16 : 13,
                    ),
                  ),
                if (iconPath != null && cdText == null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFF1C2),
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                if (iconPath != null && cdText != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Text(
                          cdText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.label, required this.onChanged});

  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: _ControlSurface(label: label),
    );
  }
}

class _ImageTapButton extends StatelessWidget {
  const _ImageTapButton({
    required this.assetPath,
    required this.onTap,
    this.size = 64,
  });

  final String assetPath;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: Image.asset(
          ArtAtlas.flutterAsset(assetPath),
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _ControlSurface extends StatelessWidget {
  const _ControlSurface({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
