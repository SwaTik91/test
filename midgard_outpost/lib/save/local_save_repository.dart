import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../progress/hero_progress.dart';
import 'hero_save_dto.dart';

class LocalSaveRepository {
  static const _storageKey = 'hero_progress_v1';

  Future<HeroProgress?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return null;
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return HeroSaveDto.fromJson(json).hero;
  }

  Future<void> save(HeroProgress hero) async {
    final prefs = await SharedPreferences.getInstance();
    final dto = HeroSaveDto(hero: hero);
    await prefs.setString(_storageKey, jsonEncode(dto.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
