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

  static const _railIcons = {
    HubTab.home: Icons.home_outlined,
    HubTab.stats: Icons.bar_chart_outlined,
    HubTab.skills: Icons.auto_awesome_outlined,
    HubTab.shop: Icons.storefront_outlined,
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
    final heroArt = ArtAtlas.flutterAsset(ArtAtlas.heroPreviewPath(hero.classId));

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
                flex: 58,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: constraints.maxWidth * 0.08,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  HubTheme.overlayEdge.withValues(alpha: 0),
                                  HubTheme.overlayEdge.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ListenableBuilder(
                          listenable: widget.controller,
                          builder: (context, _) {
                            final current = widget.controller.hero!;
                            return Positioned(
                              top: 12,
                              left: 12,
                              child: Row(
                                children: [
                                  HubResourceChip(
                                    icon: Icons.monetization_on,
                                    iconColor: HubTheme.gold,
                                    value: '${current.gold}',
                                  ),
                                  const SizedBox(width: 8),
                                  HubResourceChip(
                                    icon: Icons.diamond_outlined,
                                    iconColor: HubTheme.crystal,
                                    value: '${current.crystals}',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            heroArt,
                            filterQuality: FilterQuality.none,
                            fit: BoxFit.contain,
                            height: constraints.maxHeight * 0.55,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                flex: 42,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  child: _HubDockPanel(
                    selected: _tab,
                    onSelect: _selectTab,
                    onRun: _openRun,
                    labels: _railLabels,
                    icons: _railIcons,
                    body: _buildTabBody(),
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

class _HubDockPanel extends StatelessWidget {
  const _HubDockPanel({
    required this.selected,
    required this.onSelect,
    required this.onRun,
    required this.labels,
    required this.icons,
    required this.body,
  });

  final HubTab selected;
  final ValueChanged<HubTab> onSelect;
  final VoidCallback onRun;
  final Map<HubTab, String> labels;
  final Map<HubTab, IconData> icons;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: HubTheme.panelDecoration(),
      child: Padding(
        padding: HubTheme.contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: body,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: HubTheme.railWidth,
                    child: _HubRail(
                      selected: selected,
                      onSelect: onSelect,
                      labels: labels,
                      icons: icons,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: HubTheme.accentButtonStyle(height: HubTheme.ctaHeight),
              onPressed: onRun,
              child: const Text(
                'В поля',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubRail extends StatelessWidget {
  const _HubRail({
    required this.selected,
    required this.onSelect,
    required this.labels,
    required this.icons,
  });

  final HubTab selected;
  final ValueChanged<HubTab> onSelect;
  final Map<HubTab, String> labels;
  final Map<HubTab, IconData> icons;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubTheme.railBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              for (final tab in HubTab.values)
                Expanded(
                  child: _RailButton(
                    label: labels[tab]!,
                    icon: icons[tab]!,
                    selected: selected == tab,
                    onPressed: () => onSelect(tab),
                    maxHeight: constraints.maxHeight / HubTab.values.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    required this.maxHeight,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Material(
        color: selected ? HubTheme.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: maxHeight.clamp(40, 96),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color:
                          selected ? HubTheme.overlayEdge : HubTheme.textSecondary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color:
                            selected ? HubTheme.overlayEdge : HubTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
