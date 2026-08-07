import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Мидгард: Аванпост')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите класс',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: ClassesCatalog.all.map((classDef) {
                final isSelected = _selectedClass == classDef.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(classDef.name),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedClass = classDef.id);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              ClassesCatalog.byId(_selectedClass).description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => widget.controller.createHero(_selectedClass),
              child: const Text('Создать героя'),
            ),
          ],
        ),
      ),
    );
  }
}
