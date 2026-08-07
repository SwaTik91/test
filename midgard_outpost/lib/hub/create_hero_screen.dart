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
                  child: DecoratedBox(
                    decoration: HubTheme.panelDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DefaultTextStyle(
                        style: const TextStyle(color: HubTheme.textBrown),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Мидгард: Аванпост',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: HubTheme.textBrown,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Выберите класс',
                              style: HubTheme.cardTitleStyle(
                                theme.textTheme,
                              ).copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: ClassesCatalog.all.map((classDef) {
                                final isSelected =
                                    _selectedClass == classDef.id;
                                return _ClassChip(
                                  classDef: classDef,
                                  selected: isSelected,
                                  onTap: () {
                                    setState(
                                      () => _selectedClass = classDef.id,
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              selected.description,
                              style: HubTheme.cardSubtitleStyle(
                                theme.textTheme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      FilledButton(
                        style: HubTheme.goldButtonStyle(height: 52),
                        onPressed: () =>
                            widget.controller.createHero(_selectedClass),
                        child: const Text('Создать героя'),
                      ),
                    ],
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

class _ClassChip extends StatelessWidget {
  const _ClassChip({
    required this.classDef,
    required this.selected,
    required this.onTap,
  });

  final ClassDef classDef;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? HubTheme.goldAccent : HubTheme.cardBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? HubTheme.goldAccentDark : HubTheme.borderBrown,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                ArtAtlas.flutterAsset(ArtAtlas.heroIconPath(classDef.id)),
                width: 24,
                height: 24,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(width: 8),
              Text(
                classDef.name,
                style: TextStyle(
                  color: HubTheme.textBrown,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
