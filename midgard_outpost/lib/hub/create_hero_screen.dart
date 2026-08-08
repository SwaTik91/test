import 'package:flutter/material.dart';

import '../art/art_atlas.dart';
import '../content/classes.dart';
import '../core/ids.dart';
import 'game_controller.dart';
import 'hub_theme.dart';

class CreateHeroScreen extends StatefulWidget {
  const CreateHeroScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<CreateHeroScreen> createState() => _CreateHeroScreenState();
}

class _CreateHeroScreenState extends State<CreateHeroScreen> {
  HeroClassId _selectedClass = HeroClassId.archer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ClassesCatalog.byId(_selectedClass);
    final heroArt = ArtAtlas.flutterAsset(ArtAtlas.heroPath(_selectedClass));

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
                  child: DecoratedBox(
                    decoration: HubTheme.panelDecoration(),
                    child: Padding(
                      padding: HubTheme.contentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Мидгард: Аванпост',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: HubTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Выберите класс',
                            style: HubTheme.pointsHeaderStyle(theme.textTheme),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children: [
                                for (final classDef in ClassesCatalog.all) ...[
                                  _ClassRow(
                                    classDef: classDef,
                                    selected: _selectedClass == classDef.id,
                                    onTap: () {
                                      setState(() => _selectedClass = classDef.id);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  selected.description,
                                  style: HubTheme.cardSubtitleStyle(theme.textTheme),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: HubTheme.accentButtonStyle(
                              height: HubTheme.ctaHeight,
                            ),
                            onPressed: () =>
                                widget.controller.createHero(_selectedClass),
                            child: const Text(
                              'Создать героя',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.classDef,
    required this.selected,
    required this.onTap,
  });

  final ClassDef classDef;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Material(
      color: selected ? HubTheme.cardBgAlt : HubTheme.cardBg,
      borderRadius: BorderRadius.circular(HubTheme.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HubTheme.cardRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HubTheme.cardRadius),
            border: Border.all(
              color: selected ? HubTheme.accent : HubTheme.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Image.asset(
                  ArtAtlas.flutterAsset(ArtAtlas.heroIconPath(classDef.id)),
                  width: 32,
                  height: 32,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    classDef.name,
                    style: HubTheme.cardTitleStyle(theme).copyWith(
                      color: selected ? HubTheme.textPrimary : HubTheme.textSecondary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: HubTheme.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
