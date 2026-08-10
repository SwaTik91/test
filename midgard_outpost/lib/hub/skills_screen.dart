import 'package:flutter/material.dart';

import '../art/art_atlas.dart';
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

  void _showDescription(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HubTheme.cardBg,
        title: Text(skill.name, style: HubTheme.cardTitleStyle(theme)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ур. $rank / $maxRank',
              style: HubTheme.cardSubtitleStyle(theme),
            ),
            const SizedBox(height: 8),
            Text(
              skill.description,
              style: theme.bodyMedium?.copyWith(color: HubTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final atMax = rank >= maxRank;
    final canAdd = canAllocate && !atMax;

    return HubCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => _showDescription(context),
            child: _SkillIcon(skill: skill),
          ),
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
                const SizedBox(height: 4),
                HubRankPips(rank: rank, maxRank: maxRank),
              ],
            ),
          ),
          const SizedBox(width: 8),
          HubIncrementButton(
            enabled: canAdd,
            onPressed: canAdd ? onAllocate : null,
          ),
        ],
      ),
    );
  }
}

class _SkillIcon extends StatelessWidget {
  const _SkillIcon({required this.skill});

  final SkillDef skill;

  @override
  Widget build(BuildContext context) {
    final iconPath = ArtAtlas.skillIconPath(skill.id);
    if (iconPath != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: HubTheme.cardBgAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: HubTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          ArtAtlas.flutterAsset(iconPath),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      );
    }

    final icon = switch (skill.kind) {
      SkillKind.auto => Icons.bolt,
      SkillKind.passive => Icons.shield,
      SkillKind.ultimate => Icons.star,
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: HubTheme.cardBgAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HubTheme.border),
      ),
      child: Icon(icon, size: 20, color: HubTheme.textPrimary),
    );
  }
}
