# RO client mockups (goro + rAthena concepts)

Interactive and static UI sketches for custom systems on top of a classic RO client.

## Origin login and character select (redesign)

Same three steps as the current client — launch, credentials, character pick —
restyled after Ragnarok Origin: warm parchment cards, gold frames, a plaza
backdrop, and a visible server list. This is a proposal, not a reproduction of
what goro draws today.

- Launch: [origin-login-launch.html](./origin-login-launch.html) — [origin-login-launch.png](./origin-login-launch.png)
- Credentials: [origin-login-filled.html](./origin-login-filled.html) — [origin-login-filled.png](./origin-login-filled.png)
- Connection failure: [origin-login-error.html](./origin-login-error.html) — [origin-login-error.png](./origin-login-error.png)
- Character select: [origin-char-select.html](./origin-char-select.html) — [origin-char-select.png](./origin-char-select.png)

Shared chrome: [origin-flow.css](./origin-flow.css).

What this changes relative to the current goro screens:

- The login card sits on the right of a full scene instead of a 304×159 dialog
  two thirds down a black window.
- Server is a visible dropdown (`Local rAthena · 127.0.0.1`). The live client
  has no server UI and always uses `Connections[0]`.
- Remember-account is on the form. The live client has no such checkbox.
- Failures use a titled `Cannot Connect` prompt with a useful sentence, not a
  generic `Disconnected` modal.
- Character select is a full-screen plaza: large hero, nameplate, portrait
  slots, and an info card that also shows zeny and last map — both omitted
  today.
- `ENTER WORLD` is the primary gold action; Create stays disabled on an
  occupied slot, same rule as the current `Make` button.

These four images are full Ludo `screenshot` generations, not HTML chrome
composited over a background. Lettering on the character panel can drift
between runs — that is the generator, not the client.

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

Full redraw of the field mob, not the card. Same jelly gloss as Origin. Packed as RGBA `poring.spr` + 40-action `poring.act` (8 dirs × idle / walk / attack / hurt / death). goro already reads both; no engine change.

- Gallery: [origin-poring/index.html](./origin-poring/index.html)
- Drop-in: [origin-poring/data/sprite/monster/poring.spr](./origin-poring/data/sprite/monster/poring.spr) and [poring.act](./origin-poring/data/sprite/monster/poring.act)
- Rebuild: `cd tools/rosprite && go test && go run . ../../docs/ro-client-mockups/origin-poring/frames ../../docs/ro-client-mockups/origin-poring`

Copy those two files over the stock Poring in the goro data tree (or pack them into a GRF).

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
