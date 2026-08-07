# Мидгард: Аванпост MVP — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Собрать playable MVP «Мидгард: Аванпост»: город на Flutter, забег на Flame, Base/Job прогресс, авто-бой с ультом, временные улучшения, локальный + облачный сейв-слой, заготовки IAP под App Gallery и RuStore.

**Architecture:** Город/мета — Flutter UI + domain/services. Забег — Flame `GameWidget`. Контент (умения, улучшения, мобы) — data tables. Прогресс героя сохраняется через `SaveRepository` (local + cloud sync port). IAP скрыт за `IapService` с store-specific реализациями.

**Tech Stack:** Flutter 3.22+, Flame 1.18+, flame_forge2d optional (MVP: чистый Flame без Forge2D), shared_preferences или hive для локального сейва, flutter_test / flame_test.

## Global Constraints

- Язык UI MVP: **только русский**
- Ориентация: **альбомная (landscape)**
- Сторы: **Huawei App Gallery + RuStore**
- Стиль: **пиксель-арт**, светлое фэнтези (RO)
- Классы MVP: **лучник / маг / паладин**
- Один слот героя; класс выбирается при создании
- Забег завершается **смертью**; temp upgrades сгорают
- Level Up ≠ выбор run-upgrade; upgrades из сундуков/дропа + редкий temp XP
- Мультиплеер / квесты / крафт / скины — **не делать** в этом плане
- Числа баланса (урон, XP curve) можно стартовать с placeholder constants из Task 2; менять только в `content/`

## Scope note

Спека большая. Этот план = **полный MVP vertical product**. Если нужно резать поставку: после Task 7 уже есть играбельный цикл (1 класс → забег → смерть → прокачка). Tasks 8–11 — полный контент, сейв, IAP.

## File Structure

```
midgard_outpost/
  pubspec.yaml
  lib/
    main.dart
    app.dart
    core/
      ids.dart
      result.dart
    content/
      classes.dart
      skills.dart
      run_upgrades.dart
      monsters.dart
      balance.dart
    progress/
      stats.dart
      hero_progress.dart
      progress_service.dart
    run/
      run_state.dart
      run_rewards.dart
      upgrade_offer_service.dart
      midgard_run_game.dart
      components/
        player_component.dart
        monster_component.dart
        projectile_component.dart
        chest_component.dart
        hud_overlay.dart
        upgrade_picker_overlay.dart
      systems/
        auto_skill_system.dart
        spawn_system.dart
    hub/
      hub_screen.dart
      create_hero_screen.dart
      stats_screen.dart
      skills_screen.dart
      shop_screen.dart
      run_summary_screen.dart
    save/
      hero_save_dto.dart
      local_save_repository.dart
      cloud_save_port.dart
      save_service.dart
    iap/
      iap_product.dart
      iap_service.dart
      fake_iap_service.dart
  test/
    progress/
      hero_progress_test.dart
      progress_service_test.dart
    run/
      upgrade_offer_service_test.dart
      run_rewards_test.dart
    save/
      save_service_test.dart
    content/
      content_tables_test.dart
```

---

### Task 1: Scaffold Flutter + Flame project

**Files:**
- Create: `midgard_outpost/pubspec.yaml`
- Create: `midgard_outpost/lib/main.dart`
- Create: `midgard_outpost/lib/app.dart`
- Create: `midgard_outpost/analysis_options.yaml`
- Test: `midgard_outpost/test/widget_smoke_test.dart`

**Interfaces:**
- Consumes: none
- Produces: runnable app entry `MidgardApp`, landscape lock, Russian MaterialApp title `Мидгард: Аванпост`

- [ ] **Step 1: Create project**

```bash
cd /workspace
flutter create --org com.midgard.outpost --project-name midgard_outpost midgard_outpost
cd midgard_outpost
flutter pub add flame shared_preferences uuid
flutter pub add --dev flame_test
```

Expected: project created, packages resolved.

- [ ] **Step 2: Write failing smoke test**

```dart
// test/widget_smoke_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/app.dart';

void main() {
  testWidgets('app shows hub title', (tester) async {
    await tester.pumpWidget(const MidgardApp());
    expect(find.text('Мидгард: Аванпост'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
cd midgard_outpost && flutter test test/widget_smoke_test.dart
```

Expected: FAIL — `MidgardApp` not found.

- [ ] **Step 4: Minimal app implementation**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MidgardApp extends StatelessWidget {
  const MidgardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мидгард: Аванпост',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Мидгард: Аванпост')),
      ),
    );
  }
}

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MidgardApp());
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd midgard_outpost && flutter test test/widget_smoke_test.dart
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add midgard_outpost
git commit -m "chore: scaffold Flutter Flame project for Midgard Outpost"
```

---

### Task 2: Content IDs, balance constants, class/skill tables

**Files:**
- Create: `midgard_outpost/lib/core/ids.dart`
- Create: `midgard_outpost/lib/content/balance.dart`
- Create: `midgard_outpost/lib/content/classes.dart`
- Create: `midgard_outpost/lib/content/skills.dart`
- Create: `midgard_outpost/lib/content/run_upgrades.dart`
- Test: `midgard_outpost/test/content/content_tables_test.dart`

**Interfaces:**
- Consumes: none
- Produces:
  - `enum HeroClassId { archer, mage, paladin }`
  - `enum StatId { str, agi, vit, intStat, dex, luk }` (`intStat` — INT, т.к. `int` reserved)
  - `class SkillDef { final String id; final HeroClassId classId; final SkillKind kind; ... }`
  - `class RunUpgradeDef { final String id; final RunUpgradeKind kind; final String? skillId; ... }`
  - `SkillsCatalog.all`, `RunUpgradesCatalog.all`, `RunUpgradesCatalog.forClass(HeroClassId)`

- [ ] **Step 1: Write failing content tests**

```dart
// test/content/content_tables_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/classes.dart';
import 'package:midgard_outpost/content/skills.dart';
import 'package:midgard_outpost/content/run_upgrades.dart';
import 'package:midgard_outpost/core/ids.dart';

void main() {
  test('each class has exactly 5 skills including one ultimate', () {
    for (final c in HeroClassId.values) {
      final skills = SkillsCatalog.forClass(c);
      expect(skills, hasLength(5));
      expect(skills.where((s) => s.kind == SkillKind.ultimate), hasLength(1));
    }
  });

  test('each skill has exactly 3 run upgrades', () {
    for (final skill in SkillsCatalog.all) {
      final ups = RunUpgradesCatalog.forSkill(skill.id);
      expect(ups, hasLength(3), reason: skill.id);
    }
  });

  test('general run upgrades pool has 18 entries', () {
    expect(
      RunUpgradesCatalog.all.where((u) => u.kind == RunUpgradeKind.general),
      hasLength(18),
    );
  });

  test('forClass returns only general + that class skill upgrades', () {
    final archerPool = RunUpgradesCatalog.forClass(HeroClassId.archer);
    expect(
      archerPool.every(
        (u) =>
            u.kind == RunUpgradeKind.general ||
            (u.skillId != null &&
                SkillsCatalog.byId(u.skillId!).classId == HeroClassId.archer),
      ),
      isTrue,
    );
    expect(archerPool.where((u) => u.kind == RunUpgradeKind.skill), hasLength(15));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd midgard_outpost && flutter test test/content/content_tables_test.dart
```

Expected: FAIL — catalogs missing.

- [ ] **Step 3: Implement IDs + catalogs**

Создай enums и таблицы строго по спеке разделы 5–7:

- Лучник: `double_strafe`, `wind_arrow`, `trap`, `eagle_eye`, `arrow_shower`
- Маг: `fire_bolt`, `frost`, `lightning`, `meditation`, `meteor`
- Паладин: `shield_bash`, `holy_strike`, `protection_aura`, `endurance`, `heaven_wrath`
- General upgrades ids: `sharp_tips`, `hot_magic`, `lifesteal`, `double_cast`, `crit_luck`, `armor_break`, `second_wind`, `stone_shell`, `regen`, `thorns`, `jump_shield`, `haste`, `light_boots`, `greed`, `temp_xp_boost`, `ult_charge`, `totem_of_power`, `boss_mark`
- Skill upgrades: ids вида `{skillId}__{suffix}` например `double_strafe__triple_string`

Каждый `SkillDef` / `RunUpgradeDef` содержит русские `name` и `description` для UI.

`balance.dart` стартовые константы:

```dart
class Balance {
  static const int maxSkillRank = 10;
  static const int baseStatPointsPerLevel = 1; // выдаётся при base level up
  static const int jobSkillPointsPerLevel = 1;
  static const int upgradeOfferCount = 3;
  static const double monsterUpgradeDropChance = 0.08;
  static const double bossUpgradeDropChance = 1.0;
  static const int tempXpPerUpgrade = 100;
  static const int chestEveryDistancePx = 1200;
  static const int bossEveryDistancePx = 4000;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd midgard_outpost && flutter test test/content/content_tables_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/core midgard_outpost/lib/content midgard_outpost/test/content
git commit -m "feat: add class, skill, and run-upgrade content tables"
```

---

### Task 3: Hero progress domain (Base/Job/stats/skills)

**Files:**
- Create: `midgard_outpost/lib/progress/stats.dart`
- Create: `midgard_outpost/lib/progress/hero_progress.dart`
- Create: `midgard_outpost/lib/progress/progress_service.dart`
- Test: `midgard_outpost/test/progress/hero_progress_test.dart`
- Test: `midgard_outpost/test/progress/progress_service_test.dart`

**Interfaces:**
- Consumes: `HeroClassId`, `StatId`, `SkillsCatalog`, `Balance`
- Produces:
  - `class HeroProgress` with fields: `classId`, `baseLevel`, `jobLevel`, `baseXp`, `jobXp`, `unspentStatPoints`, `unspentSkillPoints`, `Map<StatId,int> stats`, `Map<String,int> skillRanks`, `gold`, `crystals`
  - `HeroProgress.createNew(HeroClassId classId)`
  - `ProgressService.applyRunRewards(HeroProgress hero, RunRewards rewards) -> HeroProgress`
  - `ProgressService.allocateStat(HeroProgress, StatId) -> HeroProgress`
  - `ProgressService.allocateSkill(HeroProgress, String skillId) -> HeroProgress`
  - XP thresholds: `xpToNextBase(level)`, `xpToNextJob(level)` in `ProgressService`

- [ ] **Step 1: Write failing progress tests**

```dart
// test/progress/hero_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/progress/progress_service.dart';
import 'package:midgard_outpost/progress/stats.dart';
import 'package:midgard_outpost/run/run_rewards.dart';

void main() {
  test('new hero starts at base/job 1 with zero unspent points', () {
    final hero = HeroProgress.createNew(HeroClassId.archer);
    expect(hero.baseLevel, 1);
    expect(hero.jobLevel, 1);
    expect(hero.unspentStatPoints, 0);
    expect(hero.unspentSkillPoints, 0);
    expect(hero.stats[StatId.str], 1);
  });

  test('run rewards can level base and grant stat points', () {
    var hero = HeroProgress.createNew(HeroClassId.mage);
    final need = ProgressService.xpToNextBase(hero.baseLevel);
    hero = ProgressService.applyRunRewards(
      hero,
      RunRewards(baseXp: need, jobXp: 0, gold: 10),
    );
    expect(hero.baseLevel, 2);
    expect(hero.unspentStatPoints, 1);
    expect(hero.gold, 10);
  });

  test('allocateStat spends one point', () {
    var hero = HeroProgress.createNew(HeroClassId.paladin)
        .copyWith(unspentStatPoints: 1);
    hero = ProgressService.allocateStat(hero, StatId.vit);
    expect(hero.unspentStatPoints, 0);
    expect(hero.stats[StatId.vit], 2);
  });

  test('allocateSkill increases rank and spends job point', () {
    var hero = HeroProgress.createNew(HeroClassId.archer)
        .copyWith(unspentSkillPoints: 1);
    hero = ProgressService.allocateSkill(hero, 'double_strafe');
    expect(hero.unspentSkillPoints, 0);
    expect(hero.skillRanks['double_strafe'], 1);
  });

  test('temp run upgrades are not stored on HeroProgress', () {
    final hero = HeroProgress.createNew(HeroClassId.archer);
    // compile-time / API check: no field for run upgrades on meta hero
    expect(hero.toJson().containsKey('activeRunUpgrades'), isFalse);
  });
}
```

Также создай минимальный `RunRewards` в этом таске (файл `lib/run/run_rewards.dart`):

```dart
class RunRewards {
  const RunRewards({
    required this.baseXp,
    required this.jobXp,
    required this.gold,
  });
  final int baseXp;
  final int jobXp;
  final int gold;
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd midgard_outpost && flutter test test/progress/
```

- [ ] **Step 3: Implement domain**

`HeroProgress` — immutable + `copyWith` + `toJson`/`fromJson`.  
`ProgressService` — pure functions, без I/O.  
Кривые XP (стартовые):

```dart
static int xpToNextBase(int level) => 20 + (level * 15);
static int xpToNextJob(int level) => 15 + (level * 12);
```

При level-up в цикле `while` списывать XP и копить unspent points (возможны несколько уровней за один забег).

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd midgard_outpost && flutter test test/progress/
```

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/progress midgard_outpost/lib/run/run_rewards.dart midgard_outpost/test/progress
git commit -m "feat: add Base/Job hero progress and allocation services"
```

---

### Task 4: Upgrade offer service (chests / drop / temp XP)

**Files:**
- Create: `midgard_outpost/lib/run/run_state.dart`
- Create: `midgard_outpost/lib/run/upgrade_offer_service.dart`
- Test: `midgard_outpost/test/run/upgrade_offer_service_test.dart`

**Interfaces:**
- Consumes: `RunUpgradesCatalog`, `Balance`, `HeroClassId`
- Produces:
  - `class RunState` — `tempXp`, `Set<String> ownedUpgradeIds`, `distancePx`, helpers
  - `UpgradeOfferService.rollOffer({required HeroClassId classId, required Set<String> owned, required Random rng}) -> List<RunUpgradeDef>` length 3
  - `UpgradeOfferService.shouldDropFromMonster(Random rng) -> bool`
  - `UpgradeOfferService.addTempXp(RunState state, int amount) -> ({RunState state, bool offerReady})`

- [ ] **Step 1: Write failing tests**

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/run/upgrade_offer_service.dart';
import 'package:midgard_outpost/run/run_state.dart';
import 'package:midgard_outpost/content/balance.dart';

void main() {
  test('rollOffer returns 3 unique upgrades not already owned', () {
    final owned = {'sharp_tips'};
    final offer = UpgradeOfferService.rollOffer(
      classId: HeroClassId.archer,
      owned: owned,
      rng: Random(1),
    );
    expect(offer, hasLength(3));
    expect(offer.map((e) => e.id).toSet(), hasLength(3));
    expect(offer.any((e) => e.id == 'sharp_tips'), isFalse);
  });

  test('temp xp reaches threshold and flags offer', () {
    var state = RunState.initial();
    var ready = false;
    while (!ready) {
      final result = UpgradeOfferService.addTempXp(state, 40);
      state = result.state;
      ready = result.offerReady;
    }
    expect(state.tempXp, lessThan(Balance.tempXpPerUpgrade));
    expect(ready, isTrue);
  });

  test('monster drop uses configured chance', () {
    final rng = _FakeChanceRng(true);
    expect(UpgradeOfferService.shouldDropFromMonster(rng), isTrue);
  });
}

class _FakeChanceRng implements Random {
  _FakeChanceRng(this.value);
  final bool value;
  @override
  double nextDouble() => value ? 0.0 : 0.99;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => value;
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd midgard_outpost && flutter test test/run/upgrade_offer_service_test.dart
```

- [ ] **Step 3: Implement**

Веса: general common вес 10, general 3; skill upgrades вес 8. Не предлагать уже owned. Если пул < 3 — добивать из remaining без owned (допускается меньше 3 только если контент исчерпан — в MVP контента достаточно).

`addTempXp`: `tempXp += amount`; while `tempXp >= Balance.tempXpPerUpgrade` → `tempXp -= threshold`, `offerReady = true` (один флаг за вызов; лишний XP остаётся).

- [ ] **Step 4: Run — expect PASS**

```bash
cd midgard_outpost && flutter test test/run/upgrade_offer_service_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/run midgard_outpost/test/run
git commit -m "feat: add run upgrade offer rolling and temp XP gates"
```

---

### Task 5: Local save + save service

**Files:**
- Create: `midgard_outpost/lib/save/hero_save_dto.dart`
- Create: `midgard_outpost/lib/save/local_save_repository.dart`
- Create: `midgard_outpost/lib/save/cloud_save_port.dart`
- Create: `midgard_outpost/lib/save/save_service.dart`
- Test: `midgard_outpost/test/save/save_service_test.dart`

**Interfaces:**
- Consumes: `HeroProgress`
- Produces:
  - `abstract class CloudSavePort { Future<HeroProgress?> pull(); Future<void> push(HeroProgress hero); }`
  - `class NoopCloudSavePort implements CloudSavePort`
  - `class LocalSaveRepository { Future<HeroProgress?> load(); Future<void> save(HeroProgress); Future<void> clear(); }`
  - `class SaveService { Future<HeroProgress?> loadForLaunch(); Future<void> persist(HeroProgress); }` — load local, optionally merge/push cloud later

- [ ] **Step 1: Write failing tests with in-memory prefs fake**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persist and load roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalSaveRepository();
    final save = SaveService(local: local, cloud: NoopCloudSavePort());
    final hero = HeroProgress.createNew(HeroClassId.mage).copyWith(gold: 42);
    await save.persist(hero);
    final loaded = await save.loadForLaunch();
    expect(loaded!.gold, 42);
    expect(loaded.classId, HeroClassId.mage);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd midgard_outpost && flutter test test/save/save_service_test.dart
```

- [ ] **Step 3: Implement JSON save under key `hero_progress_v1`**

`NoopCloudSavePort.pull` → `null`; `push` → no-op.  
`SaveService.persist`: write local then `cloud.push`.  
`loadForLaunch`: local first; if null try `cloud.pull` and cache local.

- [ ] **Step 4: Run — expect PASS**

```bash
cd midgard_outpost && flutter test test/save/save_service_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/save midgard_outpost/test/save
git commit -m "feat: add local hero save with cloud save port"
```

---

### Task 6: Hub Flutter screens (create hero, stats, skills, shop stub, start run)

**Files:**
- Create: `midgard_outpost/lib/hub/create_hero_screen.dart`
- Create: `midgard_outpost/lib/hub/hub_screen.dart`
- Create: `midgard_outpost/lib/hub/stats_screen.dart`
- Create: `midgard_outpost/lib/hub/skills_screen.dart`
- Create: `midgard_outpost/lib/hub/shop_screen.dart`
- Create: `midgard_outpost/lib/hub/run_summary_screen.dart`
- Create: `midgard_outpost/lib/hub/game_controller.dart`
- Modify: `midgard_outpost/lib/app.dart`
- Test: `midgard_outpost/test/hub/hub_flow_test.dart`

**Interfaces:**
- Consumes: `SaveService`, `ProgressService`, `HeroProgress`
- Produces: `GameController` (`ChangeNotifier`) with `hero`, `createHero`, `allocateStat`, `allocateSkill`, `onRunFinished(RunRewards)`
- Navigation: no hero → `CreateHeroScreen`; else `HubScreen` with buttons: Статы, Умения, Магазин, В поля

- [ ] **Step 1: Write failing hub flow test**

```dart
testWidgets('create archer and see hub actions', (tester) async {
  SharedPreferences.setMockInitialValues({});
  final controller = GameController(
    save: SaveService(local: LocalSaveRepository(), cloud: NoopCloudSavePort()),
  );
  await controller.bootstrap();
  await tester.pumpWidget(MidgardApp(controller: controller));
  await tester.pumpAndSettle();

  expect(find.text('Выберите класс'), findsOneWidget);
  await tester.tap(find.text('Лучник'));
  await tester.tap(find.text('Создать героя'));
  await tester.pumpAndSettle();

  expect(find.text('В поля'), findsOneWidget);
  expect(find.text('Статы'), findsOneWidget);
  expect(find.text('Умения'), findsOneWidget);
  expect(find.text('Магазин'), findsOneWidget);
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd midgard_outpost && flutter test test/hub/hub_flow_test.dart
```

- [ ] **Step 3: Implement screens (русский UI)**

`CreateHeroScreen`: три кнопки классов + «Создать героя».  
`HubScreen`: показывает Base/Job level, gold/crystals, навигация.  
`StatsScreen`: список STR..LUK + кнопка «+» если `unspentStatPoints > 0`.  
`SkillsScreen`: умения текущего класса + «+» на ранг.  
`ShopScreen`: список продуктов из `IapService.listProducts()` (пока fake — Task 10). Для компиляции временно захардкодь 2 карточки «Скоро» ИЛИ сразу подключи `FakeIapService` из Task 10 раньше — предпочтительно вынести пустой `FakeIapService` уже здесь:

```dart
class FakeIapService implements IapService {
  @override
  Future<List<IapProduct>> listProducts() async => const [
        IapProduct(id: 'crystals_100', title: '100 кристаллов', crystals: 100, priceLabel: '99 ₽'),
        IapProduct(id: 'xp_boost', title: 'Буст опыта', crystals: 0, priceLabel: '149 ₽'),
      ];
  @override
  Future<bool> purchase(String productId) async => true;
}
```

Wiring в `app.dart`: `AnimatedBuilder`/`ListenableBuilder` на `GameController`.

- [ ] **Step 4: Run — expect PASS**

```bash
cd midgard_outpost && flutter test test/hub/
```

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/hub midgard_outpost/lib/app.dart midgard_outpost/lib/iap midgard_outpost/test/hub
git commit -m "feat: add Russian hub screens for hero, stats, skills, shop"
```

---

### Task 7: Flame run vertical slice (move, jump, auto-attack, death → summary)

**Files:**
- Create: `midgard_outpost/lib/run/midgard_run_game.dart`
- Create: `midgard_outpost/lib/run/components/player_component.dart`
- Create: `midgard_outpost/lib/run/components/monster_component.dart`
- Create: `midgard_outpost/lib/run/components/hud_overlay.dart`
- Create: `midgard_outpost/lib/hub/run_screen.dart`
- Modify: `midgard_outpost/lib/hub/hub_screen.dart` — navigate to `RunScreen`
- Test: `midgard_outpost/test/run/run_rewards_test.dart`
- Test: `midgard_outpost/test/run/player_combat_math_test.dart`

**Interfaces:**
- Consumes: `HeroProgress`, `SkillsCatalog`, `Balance`
- Produces:
  - `MidgardRunGame({required HeroProgress hero, required void Function(RunRewards) onDeath})`
  - Derived combat stats pure functions in `lib/run/combat_math.dart`:
    - `int maxHp(HeroProgress h)`
    - `int maxSp(HeroProgress h)`
    - `double moveSpeed(HeroProgress h)`
    - `int basicAttackDamage(HeroProgress h)`
  - On player HP ≤ 0 → pause game → `onDeath(RunRewards(...))` with xp/gold earned during run

- [ ] **Step 1: Write failing combat math + rewards tests**

```dart
test('vit increases max hp', () {
  final weak = HeroProgress.createNew(HeroClassId.paladin);
  final tank = ProgressService.allocateStat(
    weak.copyWith(unspentStatPoints: 5),
    StatId.vit,
  );
  // allocate 5 times in test setup...
  expect(CombatMath.maxHp(tank), greaterThan(CombatMath.maxHp(weak)));
});

test('run rewards accumulate gold and xp counters', () {
  final r = RunRewardsAccumulator()
    ..addKill(baseXp: 5, jobXp: 3, gold: 2)
    ..addKill(baseXp: 5, jobXp: 3, gold: 2);
  expect(r.toRewards().gold, 4);
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd midgard_outpost && flutter test test/run/player_combat_math_test.dart test/run/run_rewards_test.dart
```

- [ ] **Step 3: Implement Flame slice**

Минимальный визуал MVP (цветные прямоугольники ok, пиксель-ассеты позже):

- Мир скроллится вправо (`camera` follow + ground tiles recycling)
- Player: A/D или экранные кнопки «← →», «Прыжок», «Ульт» (ульт в Task 8 можно stub-кнопкой с КД)
- Монстры спавнятся впереди, идут к игроку / стоят на пути
- Авто-атака ближняя/дальняя по классу раз в `attackInterval`
- Коллизия player↔monster: игрок получает урон; monster умирает от атак
- HUD: HP/SP bars, Base/Job xp gained this run, distance
- Death → `Navigator` на `RunSummaryScreen` → `GameController.onRunFinished` → persist → Hub

Формулы старт:

```dart
maxHp = 100 + vit * 12;
maxSp = 50 + intStat * 8;
physDamage = 5 + str * 2 + dex;
magicDamage = 5 + intStat * 3;
```

- [ ] **Step 4: Manual + automated verification**

```bash
cd midgard_outpost && flutter test
flutter run -d linux # or android device if available
```

Expected: создать героя → В поля → прыгать/бить мобов → умереть → увидеть итоги → статы в городе выросли при достаточном XP.

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/run midgard_outpost/lib/hub midgard_outpost/test/run
git commit -m "feat: add Flame run slice with auto-combat and death summary"
```

---

### Task 8: Auto-skills + ultimate per class

**Files:**
- Create: `midgard_outpost/lib/run/systems/auto_skill_system.dart`
- Create: `midgard_outpost/lib/run/components/projectile_component.dart`
- Modify: `midgard_outpost/lib/run/midgard_run_game.dart`
- Modify: `midgard_outpost/lib/run/components/player_component.dart`
- Test: `midgard_outpost/test/run/auto_skill_system_test.dart`

**Interfaces:**
- Consumes: `HeroProgress.skillRanks`, `SkillsCatalog`, active run upgrades affecting skills
- Produces: `AutoSkillSystem.update(dt, world)` — ticks cooldowns, spends SP, spawns projectiles/effects; `tryCastUltimate()`

- [ ] **Step 1: Write failing tests for cooldown gating**

```dart
test('skill does not cast without enough SP', () {
  final sys = AutoSkillSystem(
    classId: HeroClassId.mage,
    ranks: {'fire_bolt': 1},
    upgrades: {},
  );
  sys.sp = 0;
  final events = sys.tick(1.0, enemiesInRange: 1);
  expect(events, isEmpty);
});

test('ultimate respects cooldown', () {
  final sys = AutoSkillSystem(
    classId: HeroClassId.archer,
    ranks: {'arrow_shower': 1},
    upgrades: {},
  );
  expect(sys.tryUltimate(), isTrue);
  expect(sys.tryUltimate(), isFalse);
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd midgard_outpost && flutter test test/run/auto_skill_system_test.dart
```

- [ ] **Step 3: Implement per-skill behaviors (MVP simplified)**

Каждое умение из каталога: `cooldown`, `spCost`, `baseDamage`, scaling `+ rank * k`.  
Ульт кнопка в HUD вызывает `tryCastUltimate()`.  
Пассивки модифицируют `CombatMath` / crit chance.

Wire upgrades from Task 4: if owned `fire_bolt__white_heat` → multiply skill damage.

- [ ] **Step 4: Run tests PASS + short manual check all 3 classes**

```bash
cd midgard_outpost && flutter test test/run/auto_skill_system_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/run midgard_outpost/test/run
git commit -m "feat: implement auto skills and ultimate casting"
```

---

### Task 9: Chests, monster drop offers, bosses, biomes, upgrade picker UI

**Files:**
- Create: `midgard_outpost/lib/run/components/chest_component.dart`
- Create: `midgard_outpost/lib/run/components/upgrade_picker_overlay.dart`
- Create: `midgard_outpost/lib/run/systems/spawn_system.dart`
- Create: `midgard_outpost/lib/content/monsters.dart`
- Modify: `midgard_outpost/lib/run/midgard_run_game.dart`
- Test: `midgard_outpost/test/run/spawn_system_test.dart`

**Interfaces:**
- Consumes: `UpgradeOfferService`, `Balance`, `RunState`
- Produces: pause-on-offer flow; boss every `bossEveryDistancePx`; chest every `chestEveryDistancePx`; biome label by distance (`Поля` < 8000, else `Лес`)

- [ ] **Step 1: Write failing spawn/distance tests**

```dart
test('boss due at interval', () {
  expect(SpawnSystem.shouldSpawnBoss(0), isFalse);
  expect(SpawnSystem.shouldSpawnBoss(Balance.bossEveryDistancePx), isTrue);
});

test('biome switches to forest', () {
  expect(SpawnSystem.biomeAt(0), Biome.fields);
  expect(SpawnSystem.biomeAt(8000), Biome.forest);
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd midgard_outpost && flutter test test/run/spawn_system_test.dart
```

- [ ] **Step 3: Implement**

При сундуке / удачном дропе / temp XP gate: `game.pauseEngine()` + показать `UpgradePickerOverlay` с 3 картами (русские имена). Выбор → добавить id в `RunState.ownedUpgradeIds` → resume.

Босс: больше HP, гарантированный upgrade drop, больше rewards.

- [ ] **Step 4: Run all tests**

```bash
cd midgard_outpost && flutter test
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib midgard_outpost/test
git commit -m "feat: add chests, bosses, biomes, and upgrade picker"
```

---

### Task 10: IAP service for App Gallery + RuStore (portable)

**Files:**
- Modify: `midgard_outpost/lib/iap/iap_service.dart`
- Modify: `midgard_outpost/lib/iap/iap_product.dart`
- Create: `midgard_outpost/lib/iap/store_iap_service.dart`
- Modify: `midgard_outpost/lib/hub/shop_screen.dart`
- Modify: `midgard_outpost/lib/hub/game_controller.dart`
- Test: `midgard_outpost/test/iap/iap_service_test.dart`

**Interfaces:**
- Consumes: `HeroProgress`
- Produces:
  - `IapService.listProducts() / purchase(productId)`
  - Products: `crystals_100`, `crystals_550`, `boost_base_job_xp`, `boost_drop`, `boost_run_start`
  - `GameController.purchaseProduct(id)` — on success add crystals or set timed boost flags on hero JSON (`activeBoosts`)

- [ ] **Step 1: Write failing purchase test with FakeIapService**

```dart
test('buying crystals increases balance', () async {
  final controller = /* boot with fake iap */;
  await controller.createHero(HeroClassId.archer);
  final ok = await controller.purchaseProduct('crystals_100');
  expect(ok, isTrue);
  expect(controller.hero!.crystals, 100);
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd midgard_outpost && flutter test test/iap/iap_service_test.dart
```

- [ ] **Step 3: Implement**

`StoreIapService` выбирает провайдера по стору:

```dart
enum StoreTarget { appGallery, ruStore, fake }

abstract class StoreBillingPort {
  Future<bool> buy(String productId);
}
```

В MVP без ключей магазинов: default `fake`. Реальные SDK (Huawei IAP / RuStore Billing) подключаются за `StoreBillingPort` отдельными адаптерами в `lib/iap/adapters/` когда появятся credentials — адаптеры могут бросать `UnimplementedError` пока не настроены, но интерфейс и wiring магазина должны работать на `FakeIapService`.

Shop UI на русском, цены-заглушки.

- [ ] **Step 4: Run — expect PASS**

```bash
cd midgard_outpost && flutter test test/iap/
```

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/iap midgard_outpost/lib/hub midgard_outpost/test/iap
git commit -m "feat: add IAP products and fake store purchase flow"
```

---

### Task 11: Cloud save wiring + README for stores

**Files:**
- Create: `midgard_outpost/lib/save/http_cloud_save_port.dart` (optional stub)
- Modify: `midgard_outpost/lib/save/cloud_save_port.dart`
- Modify: `midgard_outpost/lib/main.dart` — choose cloud impl via env/flavor
- Create: `midgard_outpost/README.md`
- Modify: root `README.md` — link to game
- Test: `midgard_outpost/test/save/cloud_save_port_test.dart`

**Interfaces:**
- Consumes: `SaveService`
- Produces: `InMemoryCloudSavePort` for tests; documented hook for Huawei Account / backend later

- [ ] **Step 1: Write failing test that push+pull returns hero**

```dart
test('in-memory cloud roundtrip', () async {
  final cloud = InMemoryCloudSavePort();
  final hero = HeroProgress.createNew(HeroClassId.paladin).copyWith(crystals: 7);
  await cloud.push(hero);
  final pulled = await cloud.pull();
  expect(pulled!.crystals, 7);
});
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd midgard_outpost && flutter test test/save/cloud_save_port_test.dart
```

- [ ] **Step 3: Implement InMemoryCloudSavePort + README**

`midgard_outpost/README.md` содержимое (обязательные секции):

- Как запустить
- Архитектура hub/run
- Как переключить `StoreTarget` / cloud port
- Чеклист публикации App Gallery + RuStore (package id, landscape, русские стор-тексты, IAP products)
- Ссылка на спеку `docs/superpowers/specs/2026-08-07-midgard-outpost-design.md`

Wire `SaveService(cloud: InMemoryCloudSavePort())` in debug; `NoopCloudSavePort` acceptable for release until backend exists — but document that MVP cloud path is `InMemory`→replace with real.

- [ ] **Step 4: Full test suite**

```bash
cd midgard_outpost && flutter test
```

Expected: all PASS

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost README.md
git commit -m "feat: wire cloud save port and document store release checklist"
```

---

## Plan Self-Review

### Spec coverage

| Spec area | Task |
|-----------|------|
| Side-scroller endless run | 7, 9 |
| Classes archer/mage/paladin | 2, 6, 8 |
| Auto skills + ultimate | 8 |
| Base/Job + 6 stats | 3, 6 |
| Run upgrades general + per-skill ×3 | 2, 4, 9 |
| Chests / drop% / temp XP | 4, 9 |
| Bosses + biomes | 9 |
| Death → town | 7 |
| Narrow hub | 6 |
| IAP crystals + boosts | 10 |
| Cloud save | 5, 11 |
| App Gallery + RuStore | 10, 11 |
| Russian only, landscape | 1, 6 |
| Pixel art | visual placeholders in 7; art pass outside critical path (use colored rects first) |

### Gaps intentionally deferred (post-MVP / art)

- Финальные пиксель-спрайты и анимации (после playable loop)
- Реальные SDK биллинга Huawei/RuStore (adapters ready, keys needed)
- Реальный backend cloud (port ready)
- Мультиплеер, квесты, крафт, скины — out of scope

### Placeholder scan

План без TBD-шагов; баланс вынесен в `Balance` constants намеренно (как в спеке §13).

### Type consistency

Единые имена: `HeroClassId`, `StatId.intStat`, `HeroProgress`, `RunRewards`, `RunState`, `UpgradeOfferService`, `SaveService`, `IapService`.
