# RO client mockups (goro + rAthena concepts)

Interactive and static UI sketches for custom systems on top of a classic RO client.

Note that the first section below is different in kind from the rest: it reproduces
what the goro client draws today, rather than proposing something new.

## Current client flow (reproduction of goro as it exists today)

Every color, size and string here is taken from the client source, so these are
the screens as the client actually paints them, not a redesign. Shared widget
styling lives in [client-flow.css](./client-flow.css); the source of each value
is cited in the comments there and in each page.

- Launch: [client-login-launch.html](./client-login-launch.html) — [client-login-launch.png](./client-login-launch.png)
- Credentials entered: [client-login-filled.html](./client-login-filled.html) — [client-login-filled.png](./client-login-filled.png)
- Connection failure: [client-login-error.html](./client-login-error.html) — [client-login-error.png](./client-login-error.png)
- Character selection: [client-char-select.html](./client-char-select.html) — [client-char-select.png](./client-char-select.png)

Rendered at the default window size of 1280x720 (`config/config.go`).

What the screens reflect about the current implementation:

- The login dialog is 304x159 (`ui/login_window.go`), positioned two thirds down
  the window, and holds exactly two fields labelled `Account` and `Password`
  plus a single `Login` button. There is no remember-me checkbox, no exit
  button, no version text and no visible server list.
- Widgets are drawn by `ui/rotheme`, not from RO interface bitmaps. The palette
  is a light blue-on-white theme (`#D6E8FA` title gradient, `#76A0CE` borders,
  `#FAFCFF` panels) at 11px DejaVu Sans. `login_interface/win_select.bmp` is
  loaded but never drawn.
- The background is `bgi_temp.bmp` from the data directory for a 2008 client
  date. The screenshots show the fallback fill `#0A0D16` that appears when the
  asset is missing, which is also what a first run without a data directory
  looks like.
- The password field masks input as one asterisk per rune, and the focused field
  draws a 1px caret with no blink. Account has focus on start.
- Server selection has no UI at all. A manual login always uses the first entry
  from `clientinfo.xml`, defaulting to `Local rAthena` at `127.0.0.1:6900`.
- Failures surface as a modal titled `Disconnected`; the internal status strings
  such as `CA_LOGIN sent` are never painted on screen. A wrong password is worth
  watching during the first server run: `0x006A` (`AC_REFUSE_LOGIN`) has no
  handler, so the rejection is likely to arrive as a generic disconnect instead
  of a specific message.
- Character selection is 576x373 with three slots of 139x144 per page, a `1 / 3`
  page label, and a 318x105 info table. The table shows name, job, level, exp,
  HP and SP against the six primary stats; zeny and last map are not displayed.
  `Delete` is enabled only for an occupied slot and `Make` only for an empty one.
- The character preview is a cached still frame, not a live animation: idle
  action, front facing, scale 0.92, feet anchored 25px above the slot bottom.
  It needs job sprites from the data directory, and the figure in the screenshot
  is a stand-in for that sprite rather than a real ACT/SPR render.

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
