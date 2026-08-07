import '../core/ids.dart';

/// Helpers for hero stat maps.
class Stats {
  Stats._();

  static Map<StatId, int> defaultStats() => {
        for (final stat in StatId.values) stat: 1,
      };

  static Map<String, int> statsToJson(Map<StatId, int> stats) => {
        for (final entry in stats.entries) entry.key.name: entry.value,
      };

  static Map<StatId, int> statsFromJson(Map<String, dynamic> json) => {
        for (final stat in StatId.values)
          stat: (json[stat.name] as num?)?.toInt() ?? 1,
      };
}
