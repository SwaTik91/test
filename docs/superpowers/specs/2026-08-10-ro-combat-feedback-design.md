# RO combat feedback + manual archer skills

## Goals
- Ragnarok-style floating damage numbers on hit.
- Disable automatic skill casting.
- Manual buttons for all castable archer skills: Double Strafe, Wind Arrow, Trap, Arrow Shower.
- Skill visuals are large and travel hero → enemy; damage applies on impact for projectile skills.

## Non-goals
- Ground art changes.
- Mage/paladin skill buttons (system supports them later).
- New Higgsfield skill icon set (use compact labeled HUD controls to avoid expensive gens).

## Design
### Damage numbers
- Spawn above target when HP is reduced (player or monster).
- Style: bold outlined digits, yellow for normal, red for crit; float up ~0.7s and fade.
- Crit flag comes from combat roll when available; skills use same multiplier path when crit is rolled.

### Skill casting
- `AutoSkillSystem.tick` only ticks CD + SP regen (no casts).
- `tryCastSkill(skillId)` casts one ready skill (auto or ultimate) if SP/CD/targets allow.
- Archer HUD: Jump + 4 skill buttons (short names / CD overlay). Ult button becomes Arrow Shower among them (or keep Ult slot mapped to `arrow_shower`).

### Visuals
- Projectile skills: large projectile flies hero→target; on arrival apply damage + small impact VFX + damage number.
- Non-projectile (trap / AoE shower): large VFX at target(s); short windup then damage + numbers.
- Prefer scaling existing arrow/slash assets; no new generative art required for v1.

## Success
- No auto skill casts in a run.
- Each ranked archer skill can be pressed from HUD.
- Numbers visible on every damaging hit.
- Projectile skill damage is not applied before the projectile reaches the target.
