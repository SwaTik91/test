# Midgard Outpost — UI / Art Direction Spec (LOCKED)

**Status:** Decisive implementable canon. No further layout A/B questions.  
**Supersedes:** cream/parchment hub restyle; any hub that covers town/hero with a content panel.  
**Keeps:** RO art for characters/monsters/backgrounds; modern flat mobile UI chrome.  
**Related:** Mario+RO run composition (`bg-fields` / `bg-forest` + ground strip).

Design reference games for this pattern: **AFK Arena / AFK Journey home**, **Epic Seven lobby**, **Idle Heroes-class landscape hubs**, **Raid-style command dock** — living world stage + compact dark command UI, one primary CTA.

---

## 0. One-line rule

**Town and hero are the product shot. UI is a dark glass dock on the right. Nothing cream, nothing opaque over the stage.**

---

## 1. Hub menu pattern (LOCKED)

### Pattern name

**Living Stage + Side Command Dock**

### Why this (not cream card, not full RO chrome, not bottom-only dock)

| Pattern | Verdict for Midgard |
|---------|---------------------|
| Cream/parchment card over town | **Rejected** — hides hero/town, feels random |
| Classic RO window chrome | **Rejected** — not modern mobile |
| Portrait phone bottom tab bar only | Weak for landscape; wastes stage width |
| **Living stage + right command dock** | **Chosen** — matches successful landscape idle/RPG hubs and existing skills-canon frame E |

### What the player sees

1. **Full-bleed town art** as the entire screen background (`BoxFit.cover`).
2. **Hero sprite** standing in the open stage (left), feet on implied ground — never inside a card.
3. **Right command dock** — one dark flat panel: tab body + icon rail + primary CTA.
4. **Top resource chips** — thin, over stage top-left (gold / crystals), not a panel.
5. **One primary CTA:** «В поля» — amber, sticky bottom of the dock.

### Exact landscape layout recipe (% of SafeArea)

Target aspect: **16:9** (reference viewport **1280×720**). All % = SafeArea after notches.

```
┌──────────────────────────────────────────────────────────────┐
│ STAGE 58%                         │ DOCK 42%                 │
│                                   │ ┌──────────────────────┐ │
│  [gold] [crystal]   ← chips       │ │ BODY  (flex)         │ │
│                                   │ │ tab content only     │ │ rail
│                                   │ │                      │ │ 72dp
│         HERO                      │ │                      │ │
│      (bottom-center               │ ├──────────────────────┤ │
│       of STAGE)                   │ │ «В поля»  CTA 56dp   │ │
│                                   │ └──────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

| Zone | Width % | Height % | Rules |
|------|---------|----------|-------|
| **Stage** | **58%** | 100% | Town bg visible; hero only; resource chips top-left |
| **Dock** | **42%** | 100% | Single dark panel; margin from SafeArea edge |
| Dock outer inset | — | — | `12dp` top/right/bottom; `0` left (flush to stage split) |
| Dock corner radius | — | — | `16` on all corners of dock panel |
| **Rail** | **72dp** fixed (inside dock) | stretch above CTA | Icon + 1-line RU label; active = accent fill |
| **Body** | `dock − 72dp − 8dp gap` | flex | Tab content **only here** — never over stage |
| **CTA row** | 100% of dock inner | **56dp** button + `12dp` pad | «В поля» full width of body+rail or body-aligned; accent fill |

**Flex shorthand (Flutter):** `Row( Expanded(flex: 58, stage), Expanded(flex: 42, dock) )`  
Inside dock: `Column( Expanded( Row(Expanded(body), SizedBox(width:72, rail)) ), CTA )`

### Hub content placement (critical)

| Content | Where |
|---------|--------|
| Class name, Base/Job, gold summary, crystals | **Home tab body** (inside dock) **and/or** thin chips on stage top-left |
| Stats STR…LUK | Dock body only |
| Skills list | Dock body only (visual reference tab) |
| Shop IAP | Dock body only |
| Hero portrait / full sprite | **Stage only** — never duplicated as a big card covering town |
| «В поля» | Dock CTA only — one instance |

### Overlay darkness over town (stage side only)

Do **not** dim the whole screen. Optional: soft vertical gradient on the **right edge of stage** only, so dock edge reads clean:

- Gradient strip: last **8%** of stage width  
- `transparent → rgba(15,23,42,0.55)` left→right  
- No full-screen cream/black veil

---

## 2. Color system (LOCKED hex)

Works over bright RO town art; feels gamey (amber CTA), not parchment, not purple glow.

### Tokens

| Token | Hex | Usage |
|-------|-----|--------|
| `overlayEdge` | `#0F172A` @ **0.55** | Stage→dock edge gradient only |
| `panelBg` | `#1E293B` @ **0.94** | Dock panel fill |
| `panelBgSolid` | `#1E293B` | Prefer solid if alpha fights RO art readability |
| `railBg` | `#0F172A` | Rail column behind icons |
| `cardBg` | `#334155` | Rows / list cards inside dock |
| `cardBgAlt` | `#475569` | Selected/hover row, nested chip |
| `border` | `#475569` | 1px hairline on cards; optional dock edge |
| `accent` | `#E69526` | Active tab, «В поля», `+` allocate, primary CTA |
| `accentPressed` | `#C47A1A` | Pressed CTA |
| `accentMuted` | `#E69526` @ **0.25** | Disabled `+` / CTA wash |
| `textPrimary` | `#F8FAFC` | Titles, values |
| `textSecondary` | `#CBD5E1` | Labels, descriptions |
| `textMuted` | `#94A3B8` | Hints, empty states |
| `danger` | `#DC2626` | Ult badge, destructive |
| `hp` | `#22C55E` | Run HP bar |
| `sp` | `#38BDF8` | Run SP bar |
| `gold` | `#FBBF24` | Currency chip icon/value |
| `crystal` | `#67E8F9` | Premium currency chip |

### Forbidden colors (hub)

| Hex / family | Why |
|--------------|-----|
| `#FFF8E7`, `#F5E6C8`, cream/parchment | Rejected look |
| `#5C4033` brown text as primary | Pairs with cream; wrong on dark |
| Purple / indigo neon gradients | Generic AI mobile look |
| Pure white `#FFFFFF` panels | Washes RO art; use slate cards |

### Chip style (stage top-left)

- Height `28–32dp`, radius `8`, fill `#0F172A` @ `0.72`, padding `H8 V4`
- Icon `16` + value text `12–13` semibold `textPrimary`
- Max **2 chips** in hub (gold, crystals). No third chip without removing one.

---

## 3. HUD / level (run) recipe (LOCKED)

### Layer order (back → front)

1. **Sky/biome backdrop** — full viewport, `BoxFit.cover`, nearest-neighbor  
2. **Parallax props** (optional later) — behind actors  
3. **Ground strip** — tiled floor  
4. **Actors** — player, monsters, chests, projectiles, VFX  
5. **Flutter HUD overlay** — bars, distance, jump/ult buttons  

Never put opaque full-width panels behind actors in world space.

### Ground strip rules

| Rule | Value |
|------|--------|
| Ground top Y | **72%** of logical game height (feet contact line) |
| Ground tile visual height | **28%** of screen height (fills below contact to bottom) |
| Tile width | Match art tile; scroll horizontally with camera/world |
| No floating platforms in MVP | Single continuous strip |
| Actor feet | Snap to ground top Y (minus sprite foot padding) |

Reference for current code: migrate hardcoded `groundY = 330` → `% of size.y` so 16:9 and other landscape sizes stay consistent.

### Character / monster scale vs screen height

| Entity | Height as % of screen H | Notes |
|--------|-------------------------|--------|
| Player | **28–32%** | Readable RO silhouette; not tiny Mario |
| Common mob | **18–24%** | Smaller than player |
| Elite / mid | **24–28%** | |
| Boss | **40–48%** | Dominates lane; still leaves HUD clear |
| Chest | **12–16%** | |

Use nearest-neighbor; do not soft-filter RO sprites.

### Safe margins (HUD)

| Region | Reserve |
|--------|---------|
| Top | `12dp` + SafeArea; HUD cluster **≤ 30%** screen height |
| Bottom | `12dp` + SafeArea; action buttons sit here |
| Left | Top-left info cluster max width **28%** screen W |
| Right | Jump + Ult buttons; each touch target **≥ 56×56dp**, gap `12dp` |
| Center playfield | Keep clear of opaque UI |

### Run HUD chrome

- Bars: dark pill `#0F172A` @ `0.72`, radius `10`, padding `10`
- HP/SP track height `10–12dp`, radius `6`
- Jump / Ult: use canon art buttons; circular or rounded-square `64dp` preferred on phone landscape
- No cream cards in run HUD
- No RO status window / hotbar 1–0 in MVP

---

## 4. Typography & spacing (LOCKED)

### Type

**Lock UI font: Manrope** (Regular 400 / Medium 500 / SemiBold 600 / Bold 700).  
Bundle under `assets/fonts/` and set as `ThemeData` `fontFamily: 'Manrope'`.  
Do not use Inter, Roboto, or system default as the hub identity face.

| Role | Size | Weight | Color |
|------|------|--------|-------|
| Dock section title | 18 | Bold (700) | `textPrimary` |
| Tab / row title | 14 | Semibold (600) | `textPrimary` |
| Body / description | 12–13 | Regular (400) | `textSecondary` |
| Chip / badge | 10–11 | Bold | white on accent/danger |
| CTA «В поля» | 16 | Bold | `#0F172A` on `accent` |
| Rail label | 10 | Medium | `textSecondary`; active `textPrimary` |
| Run HUD numbers | 12–13 | Semibold | `textPrimary` |

Line height: **1.25** titles, **1.35** body. Max **2 lines** for row subtitles.

### Radii

| Element | Radius |
|---------|--------|
| Dock panel | **16** |
| Cards / skill rows | **12** |
| Chips / small badges | **8** |
| `+` allocate button | **8** |
| CTA | **12** |
| Rail active item | **10** |
| Rank pips | **2** (square-ish) |

### Padding / gaps

| Token | Value |
|-------|--------|
| Dock inner padding | `12` |
| Card padding | `12` |
| Gap between cards | `8` |
| Gap title → list | `10` |
| Rail item padding | `8` vertical, icon centered |
| CTA height | `56` |
| Touch min | `44×44` (prefer `48+`) |
| Stage chip gap | `8` |

### Density cap

Inside dock body: **one scrollable list**, not nested card-in-card-in-card.  
Max visual layers per row: `cardBg` → icon → text → `+` button.

---

## 5. Do / Don't (anti-clutter)

### DO

- Keep stage (town + hero) visible at all times on every hub tab.
- Put **all** tab content inside the right dock body.
- Use **one** accent color for active + primary CTA.
- Limit hub chrome to: chips, dock, rail, CTA.
- Match skills-canon hierarchy: list rows + allocate, not wallpaper collage.
- Keep Russian copy short (1 title + 1 supporting line per section).
- Run: Mario horizon + ground strip; RO sprites; compact dark HUD.

### DON'T

- **Don't** put `Positioned.fill` / semi-opaque cream panels over the stage.
- **Don't** cover the hero with Home/Stats/Skills content.
- **Don't** mix cream parchment + dark slate in the same shell.
- **Don't** add Material `AppBar` on embedded hub tabs.
- **Don't** clone RO window chrome, status window, or hotbar in hub MVP.
- **Don't** stack stats strips + schedule-like widgets + promo badges on stage.
- **Don't** use more than **one** primary CTA on hub.
- **Don't** float stickers/badges on the hero sprite.
- **Don't** use cards in the hero/stage area.
- **Don't** exceed ~30% screen height with run HUD blocks.
- **Don't** invent a third visual language for Create Hero — same dock/stage rules.

---

## 6. Implementation mapping (for engineers)

| Spec piece | Code target |
|------------|-------------|
| Stage 58 / Dock 42 | `HubShell` `Row` flex; **remove** stage `Positioned.fill` content overlay |
| Tab bodies | Only inside dock `Expanded` body |
| Tokens | Replace cream API in `HubTheme` with §2 tokens |
| Create hero | Same shell proportions + dark dock |
| Run ground % | `MidgardRunGame` groundY from `size.y * 0.72` |
| Scales | Player/monster sizes from §3 table vs `size.y` |
| HUD | Keep dark pills; align colors to §2 |

### Acceptance checklist

1. Landscape 1280×720: town **and** hero fully visible; dock does not cover hero.
2. Switching tabs never paints content onto stage.
3. No cream/`#FFF8E7`/`#F5E6C8` in hub shell or tabs.
4. Accent `#E69526` on active rail + «В поля».
5. Run: ground ~72% H; player ~30% H; HUD ≤30% H; buttons ≥56dp.
6. `flutter test` green after theme/layout swap.

---

## 7. Explicit non-goals

- Full RO UI clone  
- New biomes / classes  
- Wave-2 animation redraw (static RO art OK)  
- Portrait layout redesign (adapt later; landscape is source of truth)
