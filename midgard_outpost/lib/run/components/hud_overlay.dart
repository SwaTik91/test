import 'package:flutter/material.dart';

import '../../art/art_atlas.dart';
import '../midgard_run_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final MidgardRunGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.hudRevision,
      builder: (context, _, __) {
        final rewards = game.currentRewards;
        final ultimateReady = game.ultimateCooldownRemaining <= 0;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HpBar(
                              label:
                                  'HP ${game.player.currentHp}/${game.player.maxHp}',
                              value: game.hpFraction,
                            ),
                            const SizedBox(height: 8),
                            _Bar(
                              label:
                                  'SP ${game.player.currentSp}/${game.player.maxSp}',
                              value: game.spFraction,
                              color: Colors.lightBlueAccent,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Авто: ${game.autoSkillName}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Базовый опыт: ${rewards.baseXp} / Проф. опыт: ${rewards.jobXp} / Золото: ${rewards.gold}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Дистанция: ${game.distance.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Биом: ${game.biomeLabel}',
                              style: const TextStyle(color: Colors.white),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ImageTapButton(
                        assetPath: ArtAtlas.btnJump,
                        onTap: game.jump,
                      ),
                      const SizedBox(width: 12),
                      _ImageTapButton(
                        assetPath: ArtAtlas.btnUlt,
                        label: ultimateReady
                            ? null
                            : game.ultimateCooldownRemaining.ceil().toString(),
                        onTap: game.tryCastUltimate,
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

class _HpBar extends StatelessWidget {
  const _HpBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Image.asset(
              '${ArtAtlas.assetRoot}${ArtAtlas.hpBarFrame}',
              height: 24,
              fit: BoxFit.fitWidth,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1).toDouble(),
                color: Colors.redAccent,
                backgroundColor: Colors.transparent,
                minHeight: 12,
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
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          color: color,
          backgroundColor: Colors.white24,
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
    this.label,
  });

  final String assetPath;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            '${ArtAtlas.assetRoot}$assetPath',
            width: 64,
            height: 64,
            fit: BoxFit.contain,
          ),
          if (label != null)
            Text(
              label!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
        ],
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
        width: 96,
        height: 56,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
