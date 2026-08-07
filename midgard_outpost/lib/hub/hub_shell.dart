import 'package:flutter/material.dart';

import '../art/art_atlas.dart';
import 'game_controller.dart';
import 'hub_home_tab.dart';
import 'run_screen.dart';
import 'shop_screen.dart';
import 'skills_screen.dart';
import 'hub_theme.dart';
import 'stats_screen.dart';

enum HubTab { home, stats, skills, shop }

class HubShell extends StatefulWidget {
  const HubShell({super.key, required this.controller});

  final GameController controller;

  @override
  State<HubShell> createState() => _HubShellState();
}

class _HubShellState extends State<HubShell> {
  HubTab _tab = HubTab.home;

  static const _railLabels = {
    HubTab.home: 'Главная',
    HubTab.stats: 'Статы',
    HubTab.skills: 'Умения',
    HubTab.shop: 'Магазин',
  };

  void _selectTab(HubTab tab) {
    setState(() => _tab = tab);
  }

  void _openRun() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RunScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.controller.hero!;
    final heroArt = ArtAtlas.flutterAsset(ArtAtlas.heroPath(hero.classId));

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 62,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        heroArt,
                        filterQuality: FilterQuality.none,
                        fit: BoxFit.contain,
                        height: 280,
                      ),
                    ),
                    Positioned.fill(
                      child: _HubContentPanel(child: _buildTabBody()),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 38,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  child: _HubRailPanel(
                    selected: _tab,
                    onSelect: _selectTab,
                    onRun: _openRun,
                    labels: _railLabels,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBody() {
    return switch (_tab) {
      HubTab.home => HubHomeTab(controller: widget.controller),
      HubTab.stats => StatsScreen(
          controller: widget.controller,
          embedded: true,
        ),
      HubTab.skills => SkillsScreen(
          controller: widget.controller,
          embedded: true,
        ),
      HubTab.shop => ShopScreen(
          controller: widget.controller,
          embedded: true,
        ),
    };
  }
}

class _HubContentPanel extends StatelessWidget {
  const _HubContentPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: DecoratedBox(
        decoration: HubTheme.panelDecoration(radius: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}

class _HubRailPanel extends StatelessWidget {
  const _HubRailPanel({
    required this.selected,
    required this.onSelect,
    required this.onRun,
    required this.labels,
  });

  final HubTab selected;
  final ValueChanged<HubTab> onSelect;
  final VoidCallback onRun;
  final Map<HubTab, String> labels;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final tab in HubTab.values) ...[
              _RailButton(
                label: labels[tab]!,
                selected: selected == tab,
                onPressed: () => onSelect(tab),
              ),
              const SizedBox(height: 8),
            ],
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: onRun,
              child: const Text('В поля'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: Colors.white,
        backgroundColor: selected
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
