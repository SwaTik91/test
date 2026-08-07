import '../core/ids.dart';
import 'skills.dart';

enum RunUpgradeKind {
  general,
  skill,
}

class RunUpgradeDef {
  const RunUpgradeDef({
    required this.id,
    required this.kind,
    this.skillId,
    required this.name,
    required this.description,
  });

  final String id;
  final RunUpgradeKind kind;
  final String? skillId;
  final String name;
  final String description;
}

class RunUpgradesCatalog {
  RunUpgradesCatalog._();

  static const List<RunUpgradeDef> _general = [
    RunUpgradeDef(
      id: 'sharp_tips',
      kind: RunUpgradeKind.general,
      name: 'Острые наконечники',
      description: '+% физического урона.',
    ),
    RunUpgradeDef(
      id: 'hot_magic',
      kind: RunUpgradeKind.general,
      name: 'Раскалённая магия',
      description: '+% магического урона.',
    ),
    RunUpgradeDef(
      id: 'lifesteal',
      kind: RunUpgradeKind.general,
      name: 'Кровожадность',
      description: 'Вампиризм % от нанесённого урона.',
    ),
    RunUpgradeDef(
      id: 'double_cast',
      kind: RunUpgradeKind.general,
      name: 'Двойной выстрел',
      description: 'Шанс повторить атаку или скилл.',
    ),
    RunUpgradeDef(
      id: 'crit_luck',
      kind: RunUpgradeKind.general,
      name: 'Критическая удача',
      description: '+CRIT.',
    ),
    RunUpgradeDef(
      id: 'armor_break',
      kind: RunUpgradeKind.general,
      name: 'Бронебой',
      description: '−защита врагов.',
    ),
    RunUpgradeDef(
      id: 'second_wind',
      kind: RunUpgradeKind.general,
      name: 'Вторая жизнь',
      description: 'Один раз не умереть (до 1 HP).',
    ),
    RunUpgradeDef(
      id: 'stone_shell',
      kind: RunUpgradeKind.general,
      name: 'Каменный панцирь',
      description: '+макс. HP.',
    ),
    RunUpgradeDef(
      id: 'regen',
      kind: RunUpgradeKind.general,
      name: 'Регенерация',
      description: 'Исцеление со временем.',
    ),
    RunUpgradeDef(
      id: 'thorns',
      kind: RunUpgradeKind.general,
      name: 'Шипы',
      description: '% урона атакующим вблизи.',
    ),
    RunUpgradeDef(
      id: 'jump_shield',
      kind: RunUpgradeKind.general,
      name: 'Прыжок-щит',
      description: 'Короткая неуязвимость после прыжка.',
    ),
    RunUpgradeDef(
      id: 'haste',
      kind: RunUpgradeKind.general,
      name: 'Ускорение',
      description: '+скорость бега.',
    ),
    RunUpgradeDef(
      id: 'light_boots',
      kind: RunUpgradeKind.general,
      name: 'Лёгкие сапоги',
      description: 'Выше и дальше прыжок.',
    ),
    RunUpgradeDef(
      id: 'greed',
      kind: RunUpgradeKind.general,
      name: 'Жадность',
      description: '+золото и шанс сундука.',
    ),
    RunUpgradeDef(
      id: 'temp_xp_boost',
      kind: RunUpgradeKind.general,
      name: 'Мудрость новичка',
      description: '+множитель временного опыта.',
    ),
    RunUpgradeDef(
      id: 'ult_charge',
      kind: RunUpgradeKind.general,
      name: 'Заряд ульта',
      description: '−КД ульта.',
    ),
    RunUpgradeDef(
      id: 'totem_of_power',
      kind: RunUpgradeKind.general,
      name: 'Тотем силы',
      description: 'Все статы +N только в забеге.',
    ),
    RunUpgradeDef(
      id: 'boss_mark',
      kind: RunUpgradeKind.general,
      name: 'Знак босса',
      description: 'Следующий босс слабее / больше награды.',
    ),
  ];

  static const List<RunUpgradeDef> _skill = [
    // Лучник — Двойная стрела
    RunUpgradeDef(
      id: 'double_strafe__triple_string',
      kind: RunUpgradeKind.skill,
      skillId: 'double_strafe',
      name: 'Тройная тетива',
      description: 'Шанс выпустить третью стрелу.',
    ),
    RunUpgradeDef(
      id: 'double_strafe__heavy_tips',
      kind: RunUpgradeKind.skill,
      skillId: 'double_strafe',
      name: 'Тяжёлые наконечники',
      description: '+% урона умения.',
    ),
    RunUpgradeDef(
      id: 'double_strafe__rapid_fire',
      kind: RunUpgradeKind.skill,
      skillId: 'double_strafe',
      name: 'Скорострел',
      description: '−КД умения.',
    ),
    // Лучник — Ветряная стрела
    RunUpgradeDef(
      id: 'wind_arrow__gust',
      kind: RunUpgradeKind.skill,
      skillId: 'wind_arrow',
      name: 'Шквал',
      description: '+дальность.',
    ),
    RunUpgradeDef(
      id: 'wind_arrow__knockback_wave',
      kind: RunUpgradeKind.skill,
      skillId: 'wind_arrow',
      name: 'Отбрасывающая волна',
      description: 'Сильнее отбрасывание.',
    ),
    RunUpgradeDef(
      id: 'wind_arrow__cutting_wind',
      kind: RunUpgradeKind.skill,
      skillId: 'wind_arrow',
      name: 'Режущий ветер',
      description: '+% урона и лёгкий DoT.',
    ),
    // Лучник — Ловушка
    RunUpgradeDef(
      id: 'trap__spiked_trap',
      kind: RunUpgradeKind.skill,
      skillId: 'trap',
      name: 'Шипастая ловушка',
      description: '+урон ловушки.',
    ),
    RunUpgradeDef(
      id: 'trap__sticky_resin',
      kind: RunUpgradeKind.skill,
      skillId: 'trap',
      name: 'Клейкая смола',
      description: 'Дольше замедление.',
    ),
    RunUpgradeDef(
      id: 'trap__double_setup',
      kind: RunUpgradeKind.skill,
      skillId: 'trap',
      name: 'Двойная установка',
      description: '2 ловушки за каст.',
    ),
    // Лучник — Глаз орла
    RunUpgradeDef(
      id: 'eagle_eye__hawk_focus',
      kind: RunUpgradeKind.skill,
      skillId: 'eagle_eye',
      name: 'Ястребиный фокус',
      description: '+CRIT.',
    ),
    RunUpgradeDef(
      id: 'eagle_eye__sniper_eye',
      kind: RunUpgradeKind.skill,
      skillId: 'eagle_eye',
      name: 'Снайперский глаз',
      description: '+точность / игнор части защиты.',
    ),
    RunUpgradeDef(
      id: 'eagle_eye__hunting_instinct',
      kind: RunUpgradeKind.skill,
      skillId: 'eagle_eye',
      name: 'Охотничий инстинкт',
      description: '+скорость атаки при HP врага < 50%.',
    ),
    // Лучник — Град стрел
    RunUpgradeDef(
      id: 'arrow_shower__downpour',
      kind: RunUpgradeKind.skill,
      skillId: 'arrow_shower',
      name: 'Ливень',
      description: 'Больше стрел / шире AoE.',
    ),
    RunUpgradeDef(
      id: 'arrow_shower__armor_piercing_hail',
      kind: RunUpgradeKind.skill,
      skillId: 'arrow_shower',
      name: 'Бронебойный град',
      description: '+% урона ульта.',
    ),
    RunUpgradeDef(
      id: 'arrow_shower__quick_quiver',
      kind: RunUpgradeKind.skill,
      skillId: 'arrow_shower',
      name: 'Быстрый колчан',
      description: '−КД ульта.',
    ),
    // Маг — Огненный шар
    RunUpgradeDef(
      id: 'fire_bolt__explosive_ball',
      kind: RunUpgradeKind.skill,
      skillId: 'fire_bolt',
      name: 'Взрывной шар',
      description: 'AoE при попадании.',
    ),
    RunUpgradeDef(
      id: 'fire_bolt__white_heat',
      kind: RunUpgradeKind.skill,
      skillId: 'fire_bolt',
      name: 'Белый жар',
      description: '+% урона умения.',
    ),
    RunUpgradeDef(
      id: 'fire_bolt__chain_heat',
      kind: RunUpgradeKind.skill,
      skillId: 'fire_bolt',
      name: 'Цепной жар',
      description: 'Шанс доп. шара во 2-ю цель.',
    ),
    // Маг — Мороз
    RunUpgradeDef(
      id: 'frost__eternal_frost',
      kind: RunUpgradeKind.skill,
      skillId: 'frost',
      name: 'Вечная мерзлота',
      description: 'Дольше замедление.',
    ),
    RunUpgradeDef(
      id: 'frost__ice_shards',
      kind: RunUpgradeKind.skill,
      skillId: 'frost',
      name: 'Ледяные осколки',
      description: '+урон.',
    ),
    RunUpgradeDef(
      id: 'frost__frost_wave',
      kind: RunUpgradeKind.skill,
      skillId: 'frost',
      name: 'Морозная волна',
      description: 'Шире зона.',
    ),
    // Маг — Молния
    RunUpgradeDef(
      id: 'lightning__storm_sight',
      kind: RunUpgradeKind.skill,
      skillId: 'lightning',
      name: 'Грозовой прицел',
      description: 'Приоритет сильной цели.',
    ),
    RunUpgradeDef(
      id: 'lightning__discharge',
      kind: RunUpgradeKind.skill,
      skillId: 'lightning',
      name: 'Разряд',
      description: 'Шанс второго удара.',
    ),
    RunUpgradeDef(
      id: 'lightning__overload',
      kind: RunUpgradeKind.skill,
      skillId: 'lightning',
      name: 'Перегруз',
      description: '+% урона, выше расход SP.',
    ),
    // Маг — Медитация
    RunUpgradeDef(
      id: 'meditation__deep_trance',
      kind: RunUpgradeKind.skill,
      skillId: 'meditation',
      name: 'Глубокий транс',
      description: '+реген SP.',
    ),
    RunUpgradeDef(
      id: 'meditation__clarity',
      kind: RunUpgradeKind.skill,
      skillId: 'meditation',
      name: 'Ясность',
      description: '+маг. крит.',
    ),
    RunUpgradeDef(
      id: 'meditation__mana_economy',
      kind: RunUpgradeKind.skill,
      skillId: 'meditation',
      name: 'Экономия маны',
      description: '−стоимость авто-скиллов.',
    ),
    // Маг — Метеор
    RunUpgradeDef(
      id: 'meteor__stone_rain',
      kind: RunUpgradeKind.skill,
      skillId: 'meteor',
      name: 'Каменный дождь',
      description: 'Больше метеоритов.',
    ),
    RunUpgradeDef(
      id: 'meteor__melting_strike',
      kind: RunUpgradeKind.skill,
      skillId: 'meteor',
      name: 'Плавящий удар',
      description: '+% урона ульта.',
    ),
    RunUpgradeDef(
      id: 'meteor__quick_ritual',
      kind: RunUpgradeKind.skill,
      skillId: 'meteor',
      name: 'Быстрый ритуал',
      description: '−КД ульта.',
    ),
    // Паладин — Удар щитом
    RunUpgradeDef(
      id: 'shield_bash__stunning_edge',
      kind: RunUpgradeKind.skill,
      skillId: 'shield_bash',
      name: 'Оглушающий край',
      description: 'Дольше стан.',
    ),
    RunUpgradeDef(
      id: 'shield_bash__ram',
      kind: RunUpgradeKind.skill,
      skillId: 'shield_bash',
      name: 'Таран',
      description: 'Сильнее нокбек и +% урона.',
    ),
    RunUpgradeDef(
      id: 'shield_bash__shield_series',
      kind: RunUpgradeKind.skill,
      skillId: 'shield_bash',
      name: 'Серия щитом',
      description: '−КД умения.',
    ),
    // Паладин — Святой удар
    RunUpgradeDef(
      id: 'holy_strike__grace',
      kind: RunUpgradeKind.skill,
      skillId: 'holy_strike',
      name: 'Благодать',
      description: '+heal.',
    ),
    RunUpgradeDef(
      id: 'holy_strike__smite',
      kind: RunUpgradeKind.skill,
      skillId: 'holy_strike',
      name: 'Кара',
      description: '+% урона.',
    ),
    RunUpgradeDef(
      id: 'holy_strike__slashing_light',
      kind: RunUpgradeKind.skill,
      skillId: 'holy_strike',
      name: 'Разящий свет',
      description: 'Шанс holy DoT.',
    ),
    // Паладин — Аура защиты
    RunUpgradeDef(
      id: 'protection_aura__fortress',
      kind: RunUpgradeKind.skill,
      skillId: 'protection_aura',
      name: 'Крепость',
      description: 'Сильнее −входящий урон.',
    ),
    RunUpgradeDef(
      id: 'protection_aura__long_aura',
      kind: RunUpgradeKind.skill,
      skillId: 'protection_aura',
      name: 'Долгая аура',
      description: 'Дольше длительность.',
    ),
    RunUpgradeDef(
      id: 'protection_aura__reflection',
      kind: RunUpgradeKind.skill,
      skillId: 'protection_aura',
      name: 'Отражение',
      description: '% урона врагам в ауре.',
    ),
    // Паладин — Стойкость
    RunUpgradeDef(
      id: 'endurance__iron_will',
      kind: RunUpgradeKind.skill,
      skillId: 'endurance',
      name: 'Железная воля',
      description: '+макс. HP.',
    ),
    RunUpgradeDef(
      id: 'endurance__indestructible',
      kind: RunUpgradeKind.skill,
      skillId: 'endurance',
      name: 'Несокрушимость',
      description: '+защита.',
    ),
    RunUpgradeDef(
      id: 'endurance__second_skin',
      kind: RunUpgradeKind.skill,
      skillId: 'endurance',
      name: 'Вторая кожа',
      description: 'Короткий −урон при получении хита.',
    ),
    // Паладин — Гнев небес
    RunUpgradeDef(
      id: 'heaven_wrath__expanded_wrath',
      kind: RunUpgradeKind.skill,
      skillId: 'heaven_wrath',
      name: 'Расширение кары',
      description: 'Больше радиус.',
    ),
    RunUpgradeDef(
      id: 'heaven_wrath__heavenly_shield',
      kind: RunUpgradeKind.skill,
      skillId: 'heaven_wrath',
      name: 'Небесный щит',
      description: 'Щит крепче и дольше.',
    ),
    RunUpgradeDef(
      id: 'heaven_wrath__swift_wrath',
      kind: RunUpgradeKind.skill,
      skillId: 'heaven_wrath',
      name: 'Скорый гнев',
      description: '−КД ульта.',
    ),
  ];

  static List<RunUpgradeDef> get all => [..._general, ..._skill];

  static List<RunUpgradeDef> forSkill(String skillId) =>
      _skill.where((u) => u.skillId == skillId).toList();

  static List<RunUpgradeDef> forClass(HeroClassId classId) {
    final classSkillIds =
        SkillsCatalog.forClass(classId).map((s) => s.id).toSet();
    return all
        .where(
          (u) =>
              u.kind == RunUpgradeKind.general ||
              (u.skillId != null && classSkillIds.contains(u.skillId)),
        )
        .toList();
  }

  static RunUpgradeDef byId(String id) =>
      all.firstWhere((u) => u.id == id);
}
