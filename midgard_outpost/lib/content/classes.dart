import '../core/ids.dart';

class ClassDef {
  const ClassDef({
    required this.id,
    required this.name,
    required this.description,
  });

  final HeroClassId id;
  final String name;
  final String description;
}

class ClassesCatalog {
  ClassesCatalog._();

  static const List<ClassDef> all = [
    ClassDef(
      id: HeroClassId.archer,
      name: 'Лучник',
      description: 'Дальний бой, крит и контроль дистанции.',
    ),
    ClassDef(
      id: HeroClassId.mage,
      name: 'Маг',
      description: 'Магический урон, AoE и контроль толпы.',
    ),
    ClassDef(
      id: HeroClassId.paladin,
      name: 'Паладин',
      description: 'Ближний бой, защита и поддержка себя.',
    ),
  ];

  static ClassDef byId(HeroClassId id) =>
      all.firstWhere((c) => c.id == id);
}
