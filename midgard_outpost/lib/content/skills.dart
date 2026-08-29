import '../core/ids.dart';

enum SkillKind {
  auto,
  passive,
  ultimate,
}

class SkillDef {
  const SkillDef({
    required this.id,
    required this.classId,
    required this.kind,
    required this.name,
    required this.description,
  });

  final String id;
  final HeroClassId classId;
  final SkillKind kind;
  final String name;
  final String description;
}

class SkillsCatalog {
  SkillsCatalog._();

  static const List<SkillDef> all = [
    // Лучник
    SkillDef(
      id: 'double_strafe',
      classId: HeroClassId.archer,
      kind: SkillKind.auto,
      name: 'Двойная стрела',
      description: 'Две стрелы; урон от DEX/STR.',
    ),
    SkillDef(
      id: 'wind_arrow',
      classId: HeroClassId.archer,
      kind: SkillKind.auto,
      name: 'Ветряная стрела',
      description: 'Дальняя стрела с небольшим отбрасыванием.',
    ),
    SkillDef(
      id: 'concentrate',
      classId: HeroClassId.archer,
      kind: SkillKind.auto,
      name: 'Сосредоточиться',
      description:
          'На 20 с: +2/+3/+4… ко всем статам по рангу умения (ранг+1).',
    ),
    SkillDef(
      id: 'eagle_eye',
      classId: HeroClassId.archer,
      kind: SkillKind.passive,
      name: 'Глаз орла',
      description: '+CRIT и точность от LUK/DEX.',
    ),
    SkillDef(
      id: 'arrow_shower',
      classId: HeroClassId.archer,
      kind: SkillKind.ultimate,
      name: 'Град стрел',
      description: 'Залп по площади впереди.',
    ),
    // Маг
    SkillDef(
      id: 'fire_bolt',
      classId: HeroClassId.mage,
      kind: SkillKind.auto,
      name: 'Огненный шар',
      description: 'Базовый магический снаряд (INT).',
    ),
    SkillDef(
      id: 'frost',
      classId: HeroClassId.mage,
      kind: SkillKind.auto,
      name: 'Мороз',
      description: 'Замедляет группу врагов.',
    ),
    SkillDef(
      id: 'lightning',
      classId: HeroClassId.mage,
      kind: SkillKind.auto,
      name: 'Молния',
      description: 'Бьёт приоритетную или дальнюю цель.',
    ),
    SkillDef(
      id: 'meditation',
      classId: HeroClassId.mage,
      kind: SkillKind.passive,
      name: 'Медитация',
      description: 'Реген SP и сила магического крита.',
    ),
    SkillDef(
      id: 'meteor',
      classId: HeroClassId.mage,
      kind: SkillKind.ultimate,
      name: 'Метеор',
      description: 'Большой AoE, долгий кулдаун.',
    ),
    // Паладин
    SkillDef(
      id: 'shield_bash',
      classId: HeroClassId.paladin,
      kind: SkillKind.auto,
      name: 'Удар щитом',
      description: 'Ближний стан и нокбек.',
    ),
    SkillDef(
      id: 'holy_strike',
      classId: HeroClassId.paladin,
      kind: SkillKind.auto,
      name: 'Святой удар',
      description: 'Урон и небольшое исцеление себя.',
    ),
    SkillDef(
      id: 'protection_aura',
      classId: HeroClassId.paladin,
      kind: SkillKind.auto,
      name: 'Аура защиты',
      description: 'Временно снижает входящий урон.',
    ),
    SkillDef(
      id: 'endurance',
      classId: HeroClassId.paladin,
      kind: SkillKind.passive,
      name: 'Стойкость',
      description: '+HP и защита от VIT.',
    ),
    SkillDef(
      id: 'heaven_wrath',
      classId: HeroClassId.paladin,
      kind: SkillKind.ultimate,
      name: 'Гнев небес',
      description: 'Удар вокруг и щит на короткое время.',
    ),
  ];

  static List<SkillDef> forClass(HeroClassId classId) =>
      all.where((s) => s.classId == classId).toList();

  static SkillDef byId(String id) => all.firstWhere((s) => s.id == id);
}
