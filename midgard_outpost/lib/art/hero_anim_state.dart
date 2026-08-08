enum HeroAnimName {
  idle,
  run,
  jump,
  cast,
}

/// Picks the hero animation from grounded state, horizontal velocity, and cast flag.
///
/// Priority: cast > jump (air) > run > idle.
HeroAnimName selectHeroAnim({
  required bool grounded,
  required double vx,
  required bool casting,
  double runSpeedThreshold = 0,
}) {
  if (casting) return HeroAnimName.cast;
  if (!grounded) return HeroAnimName.jump;
  if (vx.abs() > runSpeedThreshold) return HeroAnimName.run;
  return HeroAnimName.idle;
}
