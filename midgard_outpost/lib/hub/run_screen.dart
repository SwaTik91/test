import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../run/components/hud_overlay.dart';
import '../run/midgard_run_game.dart';
import '../run/run_rewards.dart';
import 'game_controller.dart';
import 'run_summary_screen.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  bool _deathHandled = false;

  @override
  Widget build(BuildContext context) {
    final hero = widget.controller.hero!;
    return Scaffold(
      body: ClipRect(
        child: GameWidget<MidgardRunGame>.controlled(
          gameFactory: () => MidgardRunGame(hero: hero, onDeath: _openSummary),
          overlayBuilderMap: {
            MidgardRunGame.hudOverlayKey: (context, game) =>
                HudOverlay(game: game),
          },
          initialActiveOverlays: const [MidgardRunGame.hudOverlayKey],
        ),
      ),
    );
  }

  void _openSummary(RunRewards rewards) {
    if (_deathHandled) {
      return;
    }
    _deathHandled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RunSummaryScreen(
            rewards: rewards,
            onContinue: () => widget.controller.onRunFinished(rewards),
          ),
        ),
      );
    });
  }
}
