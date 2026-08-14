# Run jump hazards — pits and obstacles

## Goal

The run path has places the player must jump: **pits** (holes in the dirt strip) and **obstacles** (rock / crate). Walking into them without a jump is punished; a running jump clears them.

## Why this size

Player jump: `v = 520`, `g = 1200` → height **≈ 113px**, air time **≈ 0.87s**.  
At base move speed 190, jump distance **≈ 165px**.

| Feature | Size | Why |
|---------|------|-----|
| Pit width | 108px | ~65% of jump distance — must run-jump, standing jump fails |
| Rock | 64×54 | Below jump height, blocks a walk |
| Crate | 58×62 | Same, slightly taller |
| Safe start | x < 480 | No hazards at spawn (x = 120) |
| Spacing | ~620px after each feature | Regular, not spam |

Chests (every 1000) and bosses (every 4000) stay clear: hazards shift +180 if they would overlap ±96px.

## Rules

- **Pit:** no floor. Fall past 52px below the contact line → 16% max HP (min 12), snap back to last solid X.
- **Obstacle:** blocks walking if feet are below its top. Landing on top from a jump is allowed.
- Monsters/chests spawn on solid ground (offset past a feature if needed).
- Visuals are painted in code (no new Higgsfield gens). Pit overlay sits on the ground strip; the tile strip stays contiguous for camera coverage.

## Out of scope

- Multi-lane / floating platform chains
- New jump physics
- Hazard art PNGs
