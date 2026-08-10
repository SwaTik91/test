import 'package:flutter/material.dart';

import '../../art/art_atlas.dart';
import '../../content/skills.dart';
import '../midgard_run_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final MidgardRunGame game;

  @visibleForTesting
  static BoxConstraints panelConstraintsFor(Size screenSize) => BoxConstraints(
        maxWidth: screenSize.width * 0.28,
        maxHeight: screenSize.height * 0.30,
      );

  static String shortSkillLabel(SkillDef skill) => switch (skill.id) {
        'double_strafe' => 'ДС',
        'wind_arrow' => 'ВС',
        'trap' => 'Лов',
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

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: hudConstraints,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HpBar(
                              label:
                                  'HP ${game.player.currentHp}/${game.player.maxHp}',
                              value: game.hpFraction,
                              maxWidth: hudConstraints.maxWidth - 16,
                            ),
                            const SizedBox(height: 6),
                            _Bar(
                              label:
                                  'SP ${game.player.currentSp}/${game.player.maxSp}',
                              value: game.spFraction,
                              color: Colors.lightBlueAccent,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'XP ${rewards.baseXp}/${rewards.jobXp} · Золото ${rewards.gold}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Дистанция: ${game.distance.toStringAsFixed(0)} · ${game.biomeLabel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          for (final skill in skills)
                            _SkillButton(
                              label: shortSkillLabel(skill),
                              cooldown: game.skillCooldownRemaining(skill.id),
                              enabled: game.skillRank(skill.id) > 0 &&
                                  game.skillCooldownRemaining(skill.id) <= 0 &&
                                  game.player.currentSp > 0,
                              onTap: () => game.tryCastSkill(skill.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _ImageTapButton(
                        assetPath: ArtAtlas.btnJump,
                        onTap: game.jump,
                      ),
                    ],
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

class _SkillButton extends StatelessWidget {
  const _SkillButton({
    required this.label,
    required this.cooldown,
    required this.enabled,
    required this.onTap,
  });

  final String label;
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
            width: 56,
            height: 56,
            child: Center(
              child: Text(
                cdText ?? label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cdText != null ? Colors.white70 : const Color(0xFFFFF1C2),
                  fontWeight: FontWeight.w800,
                  fontSize: cdText != null ? 16 : 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.label,
    required this.value,
    required this.maxWidth,
  });

  final String label;
  final double value;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final barWidth = maxWidth.clamp(120.0, 220.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Image.asset(
              ArtAtlas.flutterAsset(ArtAtlas.hpBarFrame),
              width: barWidth,
              height: 18,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: SizedBox(
                width: barWidth - 6,
                child: LinearProgressIndicator(
                  value: value.clamp(0, 1).toDouble(),
                  color: Colors.redAccent,
                  backgroundColor: Colors.transparent,
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        const SizedBox(height: 3),
        LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          color: color,
          backgroundColor: Colors.white24,
          minHeight: 8,
        ),
      ],
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
  });

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        ArtAtlas.flutterAsset(assetPath),
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
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
