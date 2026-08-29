import 'dart:math' as math;

import '../../content/balance.dart';

enum TerrainKind { pit, rock, crate }

class TerrainFeature {
  const TerrainFeature({
    required this.kind,
    required this.startX,
    required this.width,
    required this.height,
  });

  final TerrainKind kind;
  final double startX;
  final double width;
  final double height;

  double get endX => startX + width;
  double get centerX => startX + width / 2;
  bool get isPit => kind == TerrainKind.pit;
  bool get isObstacle => !isPit;

  bool containsX(double x) => x >= startX && x < endX;

  double topY(double groundY) => groundY - height;
}

/// Deterministic pits and obstacles along the run path.
class TerrainSystem {
  static const double safeUntilX = 480;
  static const double spacing = 620;
  static const double pitWidth = 108;
  static const double pitDepth = 150;
  static const double fallRescueDepth = 52;
  static const double rockWidth = 64;
  static const double rockHeight = 54;
  static const double crateWidth = 58;
  static const double crateHeight = 62;
  static const double reservedPad = 96;
  static const double reservedShift = 180;

  final List<TerrainFeature> _features = [];
  double _nextX = safeUntilX;
  int _index = 0;

  List<TerrainFeature> get features => List.unmodifiable(_features);

  static int pitDamage(int maxHp) => math.max(12, (maxHp * 0.16).round());

  static bool isReserved(double startX, double width) {
    final left = startX;
    final right = startX + width;
    return _hitsEvery(left, right, Balance.chestEveryDistancePx) ||
        _hitsEvery(left, right, Balance.bossEveryDistancePx);
  }

  static bool _hitsEvery(double left, double right, int every) {
    if (every <= 0) {
      return false;
    }
    var marker = ((left - reservedPad) / every).floor() * every;
    if (marker < every) {
      marker = every;
    }
    for (var x = marker; x <= right + reservedPad; x += every) {
      if (left < x + reservedPad && right > x - reservedPad) {
        return true;
      }
    }
    return false;
  }

  static double _avoidReserved(double startX, double width) {
    var x = startX;
    for (var i = 0; i < 8; i++) {
      if (!isReserved(x, width)) {
        return x;
      }
      x += reservedShift;
    }
    return x;
  }

  void ensureUntil(double worldRight) {
    while (_nextX < worldRight) {
      final kind = switch (_index % 3) {
        0 => TerrainKind.pit,
        1 => TerrainKind.rock,
        _ => TerrainKind.crate,
      };
      final width = switch (kind) {
        TerrainKind.pit => pitWidth,
        TerrainKind.rock => rockWidth,
        TerrainKind.crate => crateWidth,
      };
      final height = switch (kind) {
        TerrainKind.pit => 0.0,
        TerrainKind.rock => rockHeight,
        TerrainKind.crate => crateHeight,
      };
      final startX = _avoidReserved(_nextX, width);
      _features.add(
        TerrainFeature(
          kind: kind,
          startX: startX,
          width: width,
          height: height,
        ),
      );
      _nextX = startX + width + spacing;
      _index += 1;
    }
  }

  TerrainFeature? pitAt(double x) {
    for (final feature in _features) {
      if (feature.isPit && feature.containsX(x)) {
        return feature;
      }
    }
    return null;
  }

  TerrainFeature? obstacleAt(double x) {
    for (final feature in _features) {
      if (feature.isObstacle && feature.containsX(x)) {
        return feature;
      }
    }
    return null;
  }

  double floorY({
    required double x,
    required double y,
    required double groundY,
  }) {
    for (final feature in _features) {
      if (feature.isObstacle &&
          feature.containsX(x) &&
          y <= feature.topY(groundY) + 10) {
        return feature.topY(groundY);
      }
    }
    if (pitAt(x) != null) {
      return groundY + pitDepth;
    }
    return groundY;
  }

  TerrainFeature? blockingObstacle({
    required double x,
    required double y,
    required double halfWidth,
    required double groundY,
  }) {
    final left = x - halfWidth;
    final right = x + halfWidth;
    for (final feature in _features) {
      if (!feature.isObstacle) {
        continue;
      }
      if (right <= feature.startX || left >= feature.endX) {
        continue;
      }
      if (y > feature.topY(groundY) + 8) {
        return feature;
      }
    }
    return null;
  }

  /// Nudge a spawn X off a pit or obstacle onto solid dirt.
  double solidXNear(double x) {
    ensureUntil(x + 240);
    final pit = pitAt(x);
    if (pit != null) {
      return pit.endX + 36;
    }
    final obstacle = obstacleAt(x);
    if (obstacle != null) {
      return obstacle.endX + 36;
    }
    return x;
  }
}
