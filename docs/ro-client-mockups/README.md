# RO client mockups (goro + rAthena concepts)

Interactive and static UI sketches for custom systems on top of a classic RO client.

## Auto Battle

- Interactive: [autobattle.html](./autobattle.html)
- Static preview: [autobattle-ui-mockup.png](./autobattle-ui-mockup.png)

## Passive Skill Tree

- Interactive: [passive-skill-tree.html](./passive-skill-tree.html)
- Static preview: [passive-skill-tree-mockup.png](./passive-skill-tree-mockup.png)

## Battle Pass

- Interactive: [battle-pass.html](./battle-pass.html)
- Static preview: [battle-pass-mockup.png](./battle-pass-mockup.png)

## Card Seal Gacha

- Interactive: [card-seal-gacha.html](./card-seal-gacha.html)
- Static preview: [card-seal-gacha-mockup.png](./card-seal-gacha-mockup.png)

Origin-style card summons with **Seals** currency, ×1/×10 pulls, pity to SSR, featured banner card, rates, recent pulls, result reveal.

## Card art (client replacement samples)

- [poring-card.png](./poring-card.png) — Poring Card illustration mock for client replacement (export/convert to RO card asset format as needed)

## Origin-gloss Poring sprite (goro replacement sample)

Full redraw of the field mob, not the card. Same jelly gloss as Origin. goro can load these as RGBA frames in `poring.spr` without engine changes.

- Idle cutout: [origin-poring/origin-poring-idle.png](./origin-poring/origin-poring-idle.png)
- Walk hop: [origin-poring/origin-poring-walk.png](./origin-poring/origin-poring-walk.png)
- Turnaround: [origin-poring/origin-poring-turnaround.png](./origin-poring/origin-poring-turnaround.png)
- In-field preview: [origin-poring/origin-poring-ingame.jpg](./origin-poring/origin-poring-ingame.jpg)

Next: cut white, pack RGBA `.spr` + `.act` (8 dirs × idle/walk/hit/die).

## Dungeon Instance

- Interactive: [dungeon-instance.html](./dungeon-instance.html)
- Static preview: [dungeon-instance-mockup.png](./dungeon-instance-mockup.png)

Party memorial dungeon entry: difficulty tabs, party ready checks, private instance create/warp.

## MVP Boss Spawn

- Interactive: [mvp-spawn.html](./mvp-spawn.html)
- Static preview: [mvp-spawn-mockup.png](./mvp-spawn-mockup.png)

Origin-style MVP tracker: Alive/Dead/Soon filters, respawn timers, locate/teleport actions.

## Character Status & Inventory (goro-faithful)

- Interactive: [character-inventory.html](./character-inventory.html)
- Static preview: [character-inventory-mockup.png](./character-inventory-mockup.png)

Basic Info + basic menu, Status window (STR/AGI… + derived ATK/DEF), Inventory bag with Item/Equip/Etc tabs — aligned with existing goro UI packages.

## Character Status & Inventory (modern redesign)

- Interactive: [character-inventory-modern.html](./character-inventory-modern.html)
- Static preview: [character-inventory-modern-mockup.png](./character-inventory-modern-mockup.png)

Dark frosted panels, rose-gold accents, modern stat chips and inventory grid — same data as classic RO windows, new visual language for goro.
