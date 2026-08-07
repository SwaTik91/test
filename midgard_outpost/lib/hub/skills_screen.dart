import 'package:flutter/material.dart';

import '../content/skills.dart';
import 'game_controller.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final GameController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hero = controller.hero!;
        final skills = SkillsCatalog.forClass(hero.classId);
        final canAllocate = hero.unspentSkillPoints > 0;

        final body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (canAllocate)
              Text('Очков умений: ${hero.unspentSkillPoints}'),
            ...skills.map((skill) {
              final rank = hero.skillRanks[skill.id] ?? 0;
              return ListTile(
                title: Text(skill.name),
                subtitle: Text(skill.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ранг $rank'),
                    if (canAllocate)
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => controller.allocateSkill(skill.id),
                      ),
                  ],
                ),
              );
            }),
          ],
        );

        if (embedded) {
          return body;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Умения'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: body,
        );
      },
    );
  }
}
