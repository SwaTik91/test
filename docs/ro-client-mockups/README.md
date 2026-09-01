# RO client mockups (goro + rAthena concepts)

Interactive and static UI sketches for custom systems on top of a classic RO client.

## Web panel (registration and account)

Official site mock for Midgard Outpost — parchment, gold, plaza, same language as
the Origin login. This is where players **register**, sign in on the web, read
news, and browse ranking. Character creation still happens in the client; the
live panel would write the rAthena `login` row (userid, user_pass, email, sex).

| Page | HTML | Preview |
| --- | --- | --- |
| Home / news / status | [web-panel/index.html](./web-panel/index.html) | [web-panel-home.png](./web-panel-home.png) |
| Create account | [web-panel/register.html](./web-panel/register.html) | [web-panel-register.png](./web-panel-register.png) |
| Sign in | [web-panel/login.html](./web-panel/login.html) | [web-panel-login.png](./web-panel-login.png) |
| My account | [web-panel/account.html](./web-panel/account.html) | [web-panel-account.png](./web-panel-account.png) |
| Daily MVP ranking | [web-panel/ranking.html](./web-panel/ranking.html) | [web-panel-ranking.png](./web-panel-ranking.png) |
| Download / goro.ini | [web-panel/download.html](./web-panel/download.html) | [web-panel-download.png](./web-panel-download.png) |

Filled sample: account `testaccount`, email `player@midgard.local`, password
masked. Sex and birthdate are stored for the later `0x0064` login packet.

Not in this cut: VIP shop, battle pass, storage viewer. Those belong after
the account table exists.

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
