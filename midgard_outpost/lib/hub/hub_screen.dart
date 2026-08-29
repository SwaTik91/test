import 'package:flutter/material.dart';

import '../art/art_atlas.dart';
import '../content/classes.dart';
import 'game_controller.dart';
import 'run_screen.dart';
import 'shop_screen.dart';
import 'skills_screen.dart';
import 'stats_screen.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final hero = controller.hero!;
    final className = ClassesCatalog.byId(hero.classId).name;
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(ArtAtlas.flutterAsset(ArtAtlas.townBg)),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Мидгард: Аванпост',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black87),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HubPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              className,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text('Базовый уровень: ${hero.baseLevel}'),
                            Text('Проф. уровень: ${hero.jobLevel}'),
                            Text('Золото: ${hero.gold}'),
                            Text('Кристаллы: ${hero.crystals}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: _HubPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: () => _open(
                            context,
                            StatsScreen(controller: controller),
                          ),
                          child: const Text('Статы'),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => _open(
                            context,
                            SkillsScreen(controller: controller),
                          ),
                          child: const Text('Умения'),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => _open(
                            context,
                            ShopScreen(controller: controller),
                          ),
                          child: const Text('Магазин'),
                        ),
                        const Spacer(),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () => _open(
                            context,
                            RunScreen(controller: controller),
                          ),
                          child: const Text('В поля'),
                        ),
                      ],
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

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _HubPanel extends StatelessWidget {
  const _HubPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}
