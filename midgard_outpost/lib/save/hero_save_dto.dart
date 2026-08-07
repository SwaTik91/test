import '../progress/hero_progress.dart';

/// JSON envelope for persisted hero progress (schema v1).
class HeroSaveDto {
  const HeroSaveDto({required this.hero});

  final HeroProgress hero;

  Map<String, dynamic> toJson() => hero.toJson();

  factory HeroSaveDto.fromJson(Map<String, dynamic> json) {
    return HeroSaveDto(hero: HeroProgress.fromJson(json));
  }
}
