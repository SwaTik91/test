import 'package:flutter/material.dart';

import '../art/art_atlas.dart';
import '../content/classes.dart';
import '../core/ids.dart';
import 'game_controller.dart';

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
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Мидгард: Аванпост',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Выберите класс',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: ClassesCatalog.all.map((classDef) {
                              final isSelected = _selectedClass == classDef.id;
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      ArtAtlas.flutterAsset(
                                        ArtAtlas.heroIconPath(classDef.id),
                                      ),
                                      width: 24,
                                      height: 24,
                                      filterQuality: FilterQuality.none,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(classDef.name),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _selectedClass = classDef.id);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selected.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
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
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
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
