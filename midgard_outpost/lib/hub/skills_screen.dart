import 'package:flutter/material.dart';

import '../content/balance.dart';
import '../content/skills.dart';
import 'game_controller.dart';
import 'hub_theme.dart';

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
        final theme = Theme.of(context).textTheme;

        final body = HubTabBody(
          child: ListView(
            children: [
              if (canAllocate)
                HubPointsHeader(
                  label: 'Очков умений: ${hero.unspentSkillPoints}',
                ),
              for (final skill in skills) ...[
                _SkillCard(
                  skill: skill,
                  rank: hero.skillRanks[skill.id] ?? 0,
                  maxRank: Balance.maxSkillRank,
                  canAllocate: canAllocate,
                  onAllocate: () => controller.allocateSkill(skill.id),
                  theme: theme,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
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

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.rank,
    required this.maxRank,
    required this.canAllocate,
    required this.onAllocate,
    required this.theme,
  });

  final SkillDef skill;
  final int rank;
  final int maxRank;
  final bool canAllocate;
  final VoidCallback onAllocate;
  final TextTheme theme;

  @override
  Widget build(BuildContext context) {
    final atMax = rank >= maxRank;
    final canAdd = canAllocate && !atMax;

    return HubCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkillIcon(kind: skill.kind),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        skill.name,
                        style: HubTheme.cardTitleStyle(theme),
                      ),
                    ),
                    if (skill.kind == SkillKind.ultimate) ...[
                      const SizedBox(width: 6),
                      const HubUltBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Ур. $rank / $maxRank',
                  style: HubTheme.cardSubtitleStyle(theme),
                ),
                const SizedBox(height: 6),
                HubRankPips(rank: rank, maxRank: maxRank),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '$rank',
                style: HubTheme.cardTitleStyle(theme),
              ),
              const SizedBox(height: 4),
              HubIncrementButton(
                enabled: canAdd,
                onPressed: canAdd ? onAllocate : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillIcon extends StatelessWidget {
  const _SkillIcon({required this.kind});

  final SkillKind kind;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      SkillKind.auto => Icons.bolt,
      SkillKind.passive => Icons.shield,
      SkillKind.ultimate => Icons.star,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: HubTheme.cardBackgroundAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HubTheme.borderBrown),
      ),
      child: Icon(icon, size: 22, color: HubTheme.textBrown),
    );
  }
}
