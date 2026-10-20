# 主题偏好与检查更新 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让外观设置真正生效并持久化，并实现基于 GitHub Releases 的自动/手动检查更新、跳过版本、启动提示与应用内更新历史。

**Architecture:** 偏好走 `shared_preferences`，经 `AppPreferencesStore` 抽象注入，UI 通过 Riverpod `Notifier` 同步读取、改动即落盘。更新源实现放在 `lib/modules/update_github/`，只通过 `lib/contracts/update/` 的接口被应用层使用，装配仍在 `main.dart`。检查逻辑是纯编排（选择版本 / 24h 节流 / 缓存 / 跳过），UI 只消费 `UpdateState`。

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5、flutter_riverpod 3.4.3、shared_preferences 2.5.6、http 1.6.0、url_launcher 6.3.3、flutter_markdown_plus 1.0.12、Android MethodChannel。

**Spec:** `docs/superpowers/specs/2026-10-19-theme-and-update-design.md`

## Global Constraints

- Dart SDK `^3.13.5`；不得引入除下述之外的新依赖：`shared_preferences ^2.5.6`、`http ^1.6.0`、`url_launcher ^6.3.3`、`flutter_markdown_plus ^1.0.12`。
- 依赖方向铁律：`lib/ui/`、`lib/app/`、`lib/domain/` 只能依赖 `lib/contracts/`；`lib/modules/` 的具体实现只能在 `lib/main.dart` 注入（`tool/ci/check_import_boundaries.dart` 守门）。
- 用户可见文案一律中文；代码注释中文，风格与现有文件一致。
- `flutter analyze` 必须 0 错误 0 警告；`flutter test` 全绿。
- 自动检查关闭时**不得**发起任何网络请求。
- 只发 GET；请求头不得包含 token、设备标识或用户数据。
- 版本比较统一走 SemVer（含预发布段规则），不得用字符串比较。
- Android 专属能力（ABI）必须能在非 Android 测试环境下降级为空列表而不抛错。

## Review Focus

- 断网或 GitHub 超时：首帧不得被阻塞，自动检查失败静默，界面仍可用。
- 偏好 JSON 损坏 / 字段类型不对 / 未来版本：回落默认值且不崩溃，不影响书库数据。
- Release 列表为空、全是 draft、或只有 prerelease（stable 通道）：显示“暂无可用版本”，不报错、不点红点。
- 已安装版本高于最新 Release：显示“已是最新”，绝不提示降级。
- 跳过 `0.2.0-beta.1` 之后出现 `0.2.0-beta.2`：必须重新提示；跳过状态跨重启保持。
- 24h 内重复启动（含上次失败）：自动检查只尝试一次；手动检查不受此限制。

---

### Task 1: 偏好模型与存储

**Files:**
- Create: `lib/app/preferences/app_preferences.dart`
- Create: `lib/app/preferences/app_preferences_store.dart`
- Create: `lib/app/providers/preferences_providers.dart`
- Modify: `lib/main.dart`（装配 store 与初始值）
- Test: `test/app/preferences/app_preferences_test.dart`
- Test: `test/app/preferences/app_preferences_store_test.dart`

**Interfaces:**
- Consumes: `AppPaletteId` **不直接引用**（`lib/app/` 禁止依赖 `lib/ui/`，见 `tool/ci/import_boundary_rules.dart`）
- Produces:
  - `enum BrightnessPreference { system, light, dark }`
  - `class AppPreferences`：字段 `String paletteId`（存 `AppPaletteId.name`，默认 `'amberScroll'`）、`BrightnessPreference brightness`、`bool oledDark`、`bool autoCheckUpdates`、`String? skippedVersion`、`String? promptedVersion`、`String? acknowledgedVersion`、`DateTime? lastCheckAt`、`DateTime? lastAttemptAt`
  - `AppPreferences.copyWith(...)`、`Map<String, Object?> toJson()`、`factory AppPreferences.fromJson(Map<String, Object?> json)`、`static const AppPreferences defaults`
  - `abstract interface class AppPreferencesStore { Future<AppPreferences> load(); Future<void> save(AppPreferences preferences); }`
  - `class SharedPreferencesAppPreferencesStore implements AppPreferencesStore`，键 `tometone.preferences.v1`
  - `class InMemoryAppPreferencesStore implements AppPreferencesStore`，暴露 `AppPreferences current` 与 `int saveCount`
  - `final Provider<AppPreferencesStore> preferencesStoreProvider`
  - `final Provider<AppPreferences> initialPreferencesProvider`
  - `final NotifierProvider<PreferencesNotifier, AppPreferences> preferencesProvider`，`PreferencesNotifier.update(AppPreferences Function(AppPreferences))` 与 `replace(AppPreferences)`

**说明：** `cachedRelease` 依赖 Task 3 的 `ReleaseInfo`，本任务不定义，Task 5 再加入。

- [ ] **Step 1: 写失败测试（模型往返）**

`test/app/preferences/app_preferences_test.dart`：

```dart
test('默认值：琥珀旧卷 / 跟随系统 / 自动检查开', () {
  const prefs = AppPreferences.defaults;
  expect(prefs.paletteId, 'amberScroll');
  expect(prefs.brightness, BrightnessPreference.system);
  expect(prefs.oledDark, isFalse);
  expect(prefs.autoCheckUpdates, isTrue);
  expect(prefs.skippedVersion, isNull);
});

test('JSON 往返保留全部字段', () {
  final prefs = AppPreferences.defaults.copyWith(
    paletteId: 'bambooMist',
    brightness: BrightnessPreference.dark,
    oledDark: true,
    autoCheckUpdates: false,
    skippedVersion: '0.2.0-beta.1',
    promptedVersion: '0.2.0-beta.1',
    acknowledgedVersion: '0.2.0-beta.1',
    lastCheckAt: DateTime.utc(2026, 10, 19, 12),
    lastAttemptAt: DateTime.utc(2026, 10, 19, 12),
  );
  expect(AppPreferences.fromJson(prefs.toJson()).toJson(), prefs.toJson());
});

test('损坏 / 未知字段回落默认值', () {
  final prefs = AppPreferences.fromJson(<String, Object?>{
    'paletteId': 42,
    'brightness': 42,
    'oledDark': 'yes',
    'autoCheckUpdates': null,
  });
  expect(prefs.paletteId, 'amberScroll');
  expect(prefs.brightness, BrightnessPreference.system);
  expect(prefs.oledDark, isFalse);
  expect(prefs.autoCheckUpdates, isTrue);
});
```

- [ ] **Step 2: 运行并确认失败**

Run: `flutter test test/app/preferences/app_preferences_test.dart`
Expected: FAIL（`app_preferences.dart` 不存在）

- [ ] **Step 3: 实现 `AppPreferences`**

要点：`toJson` 用稳定的字符串键；`fromJson` 每个字段独立容错（类型不符或枚举未知一律回落默认），不得整体抛错。日期用 `toUtc().toIso8601String()`，解析失败为 `null`。

- [ ] **Step 4: 写存储测试**

`test/app/preferences/app_preferences_store_test.dart`：

```dart
test('InMemory 保存后可读回，saveCount 递增', () async {
  final store = InMemoryAppPreferencesStore();
  expect((await store.load()).paletteId, 'amberScroll');
  await store.save(AppPreferences.defaults.copyWith(oledDark: true));
  expect((await store.load()).oledDark, isTrue);
  expect(store.saveCount, 1);
});
```

- [ ] **Step 5: 实现存储与 provider**

`SharedPreferencesAppPreferencesStore.load()`：`SharedPreferences.getInstance()` → `getString(key)`；为空返回默认；`jsonDecode` 或 `fromJson` 抛错时返回默认值，**不写回**（留给下一次用户操作覆盖）。
`save`：`setString(key, jsonEncode(preferences.toJson()))`，失败 swallow（偏好不是关键数据）。

`PreferencesNotifier`：

```dart
class PreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => ref.watch(initialPreferencesProvider);

  Future<void> update(AppPreferences Function(AppPreferences) change) async {
    final next = change(state);
    state = next;
    await ref.read(preferencesStoreProvider).save(next);
  }
}
```

- [ ] **Step 6: 装配 `main.dart`**

`main()` 改 `Future<void> main() async`；`await SharedPreferencesAppPreferencesStore.open()` 后把 `preferencesStoreProvider` 与 `initialPreferencesProvider` 加入 `ProviderScope.overrides`。其余装配不动。

- [ ] **Step 7: 运行测试与静态检查**

Run: `flutter test test/app/preferences`
Expected: PASS
Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 8: Commit**

```bash
git add lib/app/preferences lib/app/providers/preferences_providers.dart lib/main.dart test/app/preferences
git commit -m "feat(prefs): 偏好模型、持久化与 Riverpod 接线"
```

---

### Task 2: 主题接线与外观控件

**Files:**
- Modify: `lib/ui/app.dart`（`ConsumerWidget`，读偏好）
- Modify: `lib/ui/pages/settings/settings_page.dart:170-227`（外观区）
- Modify: `test/ui/app_theme_wiring_test.dart`
- Modify: `test/ui/settings_page_test.dart`
- Test: `test/ui/settings_appearance_test.dart`

**Interfaces:**
- Consumes: `preferencesProvider`、`PreferencesNotifier.update`、`AppColorPalettes`
- Produces: `AppPaletteId paletteIdFromName(String name)`（加在 `lib/ui/theme/app_color_palette.dart`，未知名称回落 `AppPaletteId.amberScroll`）；`TomeToneApp` 构造参数 `palette` / `oledDark` 移除，改为读 provider。测试辅助 `SettingsPage.appearancePaletteKey(AppPaletteId)`、`SettingsPage.oledSwitchKey`、`SettingsPage.brightnessKey(BrightnessPreference)`。

- [ ] **Step 1: 写失败测试（主题跟随偏好）**

`test/ui/settings_appearance_test.dart` 至少包含：

```dart
testWidgets('切换色盘后 MaterialApp.theme 立即变化并落盘', (tester) async {
  final engine = FakePlaybackEngine();
  final controller = testController(engine);
  addTearDown(controller.dispose);
  final store = InMemoryAppPreferencesStore();
  final container = ProviderContainer(overrides: <Override>[
    ...testOverrides(controller: controller),
    preferencesStoreProvider.overrideWithValue(store),
    initialPreferencesProvider.overrideWithValue(AppPreferences.defaults),
  ]);
  addTearDown(container.dispose);
  container.read(appTabProvider.notifier).select(AppTab.settings);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const TomeToneApp(),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(SettingsPage.appearancePaletteKey(AppPaletteId.bambooMist)));
  await tester.pumpAndSettle();

  final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  final palette = AppColorPalettes.bambooMist.colorsFor(Brightness.light);
  expect(app.theme?.colorScheme.primary, palette.primary);
  expect(store.current.paletteId, 'bambooMist');
});
```

再加两条：`brightness = dark` → `app.themeMode == ThemeMode.dark`；`oledDark = true` → `app.darkTheme` 的 surface 为 `AppColorPalettes.<当前色盘>.darkOled.surface`。另加一条：明暗为浅色时 OLED 开关 `onChanged == null`。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/ui/settings_appearance_test.dart`
Expected: FAIL（找不到 key / 构造参数不匹配）

- [ ] **Step 3: 改 `TomeToneApp`**

`ConsumerWidget`；`final AppPreferences prefs = ref.watch(preferencesProvider);`
`final AppPalette palette = AppColorPalettes.byId(paletteIdFromName(prefs.paletteId));`
`themeMode` 映射：`system → ThemeMode.system`、`light → ThemeMode.light`、`dark → ThemeMode.dark`。
`darkTheme` 的 `oled` 只在 `有效明暗为深色` 时传 `prefs.oledDark`（有效明暗为浅色时忽略）。

- [ ] **Step 4: 重写外观区**

- `_SectionHeader` 说明改为“色盘、明暗与暗夜 OLED，改完立刻生效并记住。”
- 明暗：`SegmentedButton<BrightnessPreference>`，三段标签“跟随系统 / 浅色 / 深色”，`key: SettingsPage.brightnessKey(...)`。
- 色盘：`Wrap` 五个 `InkWell`，每个含 32dp 圆形色块（取该色盘 light 的 `primaryContainer`，描边 `primary`）+ 名称；`Semantics(selected: ...)`；`key: SettingsPage.appearancePaletteKey(id)`；点击写 `paletteId: id.name`。
- OLED：`SwitchListTile`，`key: SettingsPage.oledSwitchKey`，`onChanged` 在 `brightness == light` 时为 `null`，subtitle “仅深色下生效”。

- [ ] **Step 5: 适配既有测试与测试装配**

- `test/ui/ui_test_harness.dart` 的 `testOverrides()` 默认加入 `preferencesStoreProvider.overrideWithValue(InMemoryAppPreferencesStore())` 与 `initialPreferencesProvider.overrideWithValue(AppPreferences.defaults)`，并新增可选参数 `AppPreferences preferences = AppPreferences.defaults`、`AppPreferencesStore? preferencesStore`，避免所有 pump `TomeToneApp` / `AppShell` 的用例因 provider 未装配而抛错。
- `app_theme_wiring_test.dart`：去掉 `TomeToneApp(oledDark: ...)`，改为通过 `testOverrides(preferences: ...)` 注入偏好；默认断言保持 `ThemeMode.system` 与琥珀旧卷。
- `settings_page_test.dart`：删除 `find.text('跟随系统明暗')` 与 `'只读'` 断言，替换为“明暗 / 色盘 / 暗夜 OLED”控件存在。

- [ ] **Step 6: 运行**

Run: `flutter test test/ui/settings_appearance_test.dart test/ui/app_theme_wiring_test.dart test/ui/settings_page_test.dart`
Expected: PASS
Run: `flutter analyze`

- [ ] **Step 7: Commit**

```bash
git add lib/ui/app.dart lib/ui/pages/settings/settings_page.dart test/ui
git commit -m "feat(theme): 外观设置生效并持久化"
```

---

### Task 3: SemVer 与 Release 选择

**Files:**
- Create: `lib/contracts/update/update_models.dart`
- Create: `lib/app/update/semver.dart`
- Create: `lib/app/update/release_selection.dart`
- Test: `test/app/update/semver_test.dart`
- Test: `test/app/update/release_selection_test.dart`

**Interfaces:**
- Consumes: `AppChannel`（`lib/app/app_info.dart`）
- Produces（`update_models.dart` 属于 contracts 层：**禁止 import `package:flutter/`**，不要用 `@immutable`，只用 `const` 构造与 `final` 字段）:
  - `class ReleaseAsset { const ReleaseAsset({required this.name, required this.sizeBytes, required this.downloadUrl, this.digest}); final String name; final int sizeBytes; final String downloadUrl; final String? digest; }` + `toJson/fromJson`
  - `class ReleaseInfo { const ReleaseInfo({required this.tag, required this.name, required this.body, required this.publishedAt, required this.htmlUrl, required this.prerelease, required this.draft, required this.assets}); ... }` + `toJson/fromJson`
  - `class SemVer { final int major; final int minor; final int patch; final List<String> prerelease; static SemVer? tryParse(String); int compareTo(SemVer); bool get isPrerelease; }`
  - `SemVer? versionFromTag(String tag)`（去掉一个前导 `v`）
  - `class ReleaseCandidate { const ReleaseCandidate({required this.release, required this.version}); final ReleaseInfo release; final SemVer version; }`
  - `ReleaseCandidate? selectLatestRelease({required List<ReleaseInfo> releases, required AppChannel channel})`
  - `enum UpdateVerdict { upToDate, available }`
  - `UpdateVerdict compareToCurrent({required SemVer current, required SemVer latest})`
  - `String? recommendedAbiAsset(List<String> abis, List<ReleaseAsset> assets)`

- [ ] **Step 1: 写 SemVer 失败测试**

```dart
test('预发布段按 SemVer 排序', () {
  expect(SemVer.tryParse('0.2.0-beta.2')!.compareTo(SemVer.tryParse('0.2.0-beta.10')!), lessThan(0));
  expect(SemVer.tryParse('0.2.0-beta.10')!.compareTo(SemVer.tryParse('0.2.0')!), lessThan(0));
  expect(SemVer.tryParse('0.2.0-alpha')!.compareTo(SemVer.tryParse('0.2.0-beta')!), lessThan(0));
  expect(versionFromTag('v0.2.0-beta.1'), SemVer.tryParse('0.2.0-beta.1'));
});

test('非法输入返回 null', () {
  expect(SemVer.tryParse('v0.2'), isNull);
  expect(SemVer.tryParse('0.2.0-'), isNull);
  expect(SemVer.tryParse('nope'), isNull);
});
```

- [ ] **Step 2: 运行确认失败，然后实现**

Run: `flutter test test/app/update/semver_test.dart` → FAIL
实现 `semver.dart`。比较规则：主次补丁逐段数值比较；都有预发布段时逐段比较（两段都是数字按数值，否则按字典序，数字段低于字母段，前缀相同时短者小）；一方无预发布段时它更大。`==`/`hashCode` 与 `compareTo == 0` 一致。

- [ ] **Step 3: 写选择规则失败测试**

```dart
ReleaseInfo release(String tag, {bool draft = false, bool pre = false, List<String> assets = const ['a-arm64-v8a.apk']}) => ...;

test('过滤 draft / 无 APK / 不可解析 tag，取最大版本', () {
  final picked = selectLatestRelease(releases: [
    release('v0.2.0-beta.9', draft: true),
    release('not-a-version'),
    release('v0.2.0-beta.3', assets: []),
    release('v0.2.0-beta.2'),
    release('v0.2.0-beta.10'),
  ], channel: AppChannel.beta);
  expect(picked!.version, SemVer.tryParse('0.2.0-beta.10'));
});

test('stable 通道忽略 prerelease；beta 接受', () {
  final list = [release('v0.2.0-beta.2', pre: true), release('v0.1.9')];
  expect(selectLatestRelease(releases: list, channel: AppChannel.beta)!.version, SemVer.tryParse('0.2.0-beta.2'));
  expect(selectLatestRelease(releases: list, channel: AppChannel.stable)!.version, SemVer.tryParse('0.1.9'));
});

test('已安装更高版本不提示降级', () {
  expect(compareToCurrent(current: SemVer.tryParse('0.3.0')!, latest: SemVer.tryParse('0.2.9')!), UpdateVerdict.upToDate);
});

test('ABI 资产推荐按设备顺序命中', () {
  final assets = [
    ReleaseAsset(name: 'x86_64.apk', sizeBytes: 1, downloadUrl: '', digest: null),
    ReleaseAsset(name: 'arm64-v8a.apk', sizeBytes: 1, downloadUrl: '', digest: null),
  ];
  expect(recommendedAbiAsset(['arm64-v8a', 'x86_64'], assets), 'arm64-v8a.apk');
  expect(recommendedAbiAsset(['mips'], assets), isNull);
});
```

- [ ] **Step 4: 运行确认失败，然后实现 `release_selection.dart`**

Run: `flutter test test/app/update/release_selection_test.dart` → FAIL
实现后重跑 → PASS。

- [ ] **Step 5: Commit**

```bash
git add lib/contracts/update/update_models.dart lib/app/update test/app/update
git commit -m "feat(update): SemVer 比较与 Release 选择规则"
```

---

### Task 4: GitHub 更新源

**Files:**
- Create: `lib/contracts/update/update_source.dart`
- Create: `lib/modules/update_github/github_releases_source.dart`
- Modify: `pubspec.yaml`（加 `http`）
- Test: `test/modules/update_github/github_releases_source_test.dart`

**Interfaces:**
- Consumes: `ReleaseInfo` / `ReleaseAsset`
- Produces:
  - `class UpdateFetchResult { List<ReleaseInfo> releases; String? etag; bool notModified; }`
  - `enum UpdateFailureKind { network, rateLimited, badResponse, notConfigured }`
  - `class UpdateException implements Exception { UpdateFailureKind kind; String? message; }`
  - `abstract interface class UpdateSource { Future<UpdateFetchResult> fetchReleases({String? etag}); }`
  - `class GitHubReleasesSource implements UpdateSource { GitHubReleasesSource({required http.Client client, required String owner, required String repo, required String userAgent}); }`

- [ ] **Step 1: 写失败测试（用 `package:http/testing.dart` 的 `MockClient`）**

```dart
test('200 解析 releases 并回传 etag', () async {
  final client = MockClient((request) async {
    expect(request.method, 'GET');
    expect(request.url.toString(), 'https://api.github.com/repos/o/r/releases?per_page=30');
    expect(request.headers['Accept'], 'application/vnd.github+json');
    expect(request.headers['User-Agent'], 'TomeTone/0.2.0-beta.1');
    return http.Response('''

[{"tag_name":"v0.2.0-beta.1","name":"n","body":"b","published_at":"2026-10-19T15:36:27Z","html_url":"h","prerelease":true,"draft":false,"assets":[{"name":"a.apk","size":10,"browser_download_url":"u","digest":"sha256:abc"}]}]

''', 200, headers: {'etag': 'W/"1"'});
  });
  final result = await GitHubReleasesSource(client: client, owner: 'o', repo: 'r', userAgent: 'TomeTone/0.2.0-beta.1').fetchReleases();
  expect(result.notModified, isFalse);
  expect(result.etag, 'W/"1"');
  expect(result.releases.single.assets.single.digest, 'sha256:abc');
});

test('304 表示未修改且不带 releases', () async { ... });

test('403 + rate limit 头 → rateLimited', () async {
  ... headers: {'x-ratelimit-remaining': '0', 'x-ratelimit-reset': '...'} ...
  expect(() => source.fetchReleases(), throwsA(isA<UpdateException>()
      .having((e) => e.kind, 'kind', UpdateFailureKind.rateLimited)));
});

test('SocketException / 超时 → network', () async { ... });
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/modules/update_github/github_releases_source_test.dart`
Expected: FAIL

- [ ] **Step 3: 实现**

`pubspec.yaml` 加 `http: ^1.6.0`。
请求 `https://api.github.com/repos/$owner/$repo/releases?per_page=30`；头：`Accept: application/vnd.github+json`、`X-GitHub-Api-Version: 2022-11-28`、`User-Agent: <userAgent>`；`etag != null` 时加 `If-None-Match`。
`.timeout(const Duration(seconds: 10))`。
200 → `jsonDecode` 列表，映射时对缺字段容错（`assets` 缺失为 `const []`，`digest` 缺失为 `null`，`published_at` 解析失败用 `DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)`）。
304 → `notModified: true`。
403/429 → 若 `x-ratelimit-remaining == '0'` 则 `rateLimited`，否则 `badResponse`。
其余非 200 → `badResponse`。`SocketException`、`ClientException`、`TimeoutException` → `network`。

- [ ] **Step 4: 运行**

Run: `flutter test test/modules/update_github/github_releases_source_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/contracts/update lib/modules/update_github test/modules/update_github
git commit -m "feat(update): GitHub Releases 只读更新源"
```

---

### Task 5: 更新服务（节流、缓存、跳过、状态判定）

**Files:**
- Create: `lib/contracts/update/update_state.dart`
- Create: `lib/app/update/update_service.dart`
- Create: `lib/app/providers/update_providers.dart`（本任务只放源与服务 provider；控制器在 Task 6 加入）
- Modify: `lib/app/preferences/app_preferences.dart`（加入 `CachedRelease? cachedRelease` 与 JSON）
- Modify: `lib/main.dart`（装配 `UpdateSource` 与 `UpdateService`）
- Test: `test/app/update/update_service_test.dart`
- Test: `test/app/preferences/app_preferences_test.dart`（补 cachedRelease 往返）

**Interfaces:**
- Consumes: `UpdateSource`、`AppPreferences`、`selectLatestRelease`、`compareToCurrent`、`SemVer`
- Produces:
  - `enum UpdateStatus { idle, checking, upToDate, noRelease, available, skipped, failure }`
  - `class UpdateState { final UpdateStatus status; final ReleaseInfo? release; final UpdateFailureKind? failure; final bool fromCache; }`
  - `class UpdateCheckOutcome { final UpdateStatus status; final ReleaseInfo? release; final UpdateFailureKind? failure; final bool fromCache; final AppPreferences preferences; }`
  - `class UpdateService { UpdateService({required UpdateSource source, DateTime Function() now = DateTime.now}); static const Duration checkInterval = Duration(hours: 24); Future<UpdateCheckOutcome> check({required AppPreferences preferences, required bool manual}); }`
  - `class CachedRelease { final ReleaseInfo release; final String? etag; final DateTime fetchedAt; }`
  - `final Provider<UpdateSource> updateSourceProvider`（默认抛 `UnimplementedError`）
  - `final Provider<UpdateService> updateServiceProvider`

- [ ] **Step 1: 写失败测试（假源 + 固定时钟）**

测试文件内定义：

```dart
class FakeUpdateSource implements UpdateSource {
  FakeUpdateSource(this.result);
  UpdateFetchResult Function()? result;
  int calls = 0;
  String? lastEtag;
  @override
  Future<UpdateFetchResult> fetchReleases({String? etag}) async {
    calls++;
    lastEtag = etag;
    return result!();
  }
}
```

断言：

```dart
test('自动检查 24h 内（含上次失败）不请求', () async {
  final source = FakeUpdateSource(...);
  final service = UpdateService(source: source, now: () => DateTime.utc(2026, 10, 19, 12));
  final prefs = AppPreferences.defaults.copyWith(lastAttemptAt: DateTime.utc(2026, 10, 19, 1));
  final outcome = await service.check(preferences: prefs, manual: false);
  expect(source.calls, 0);
  expect(outcome.status, UpdateStatus.idle);
});

test('发现更高版本 → available，并写入缓存与时间戳', () async { ... });

test('跳过该版本 → skipped；更高版本 → available', () async { ... });

test('304 → 刷新时间戳且保留缓存', () async { ... });

test('空列表 → noRelease 且不清缓存', () async { ... });

test('手动检查失败且有缓存 → 返回缓存结果 + failure，fromCache=true', () async { ... });

test('自动检查失败且无缓存 → failure（调用方静默）', () async { ... });
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/app/update/update_service_test.dart`
Expected: FAIL

- [ ] **Step 3: 实现 `UpdateService.check`**

顺序（严格照此，避免歧义）：

1. `final now = _now();`
2. 非 manual 且 `lastAttemptAt != null && now.difference(lastAttemptAt) < checkInterval` → 不请求，直接 `_evaluate(preferences, fromCache: true)`。
3. `var next = preferences.copyWith(lastAttemptAt: now);`
4. 调 `_source.fetchReleases(etag: preferences.cachedRelease?.etag)`。
5. `notModified` → `next = next.copyWith(lastCheckAt: now)` → `_evaluate(next, fromCache: true)`。
6. 成功：`selectLatestRelease(releases: result.releases, channel: AppInfo.channel)`。
   - `null` → `UpdateCheckOutcome(status: noRelease, preferences: next.copyWith(lastCheckAt: now))`，**不动 `cachedRelease`**。
   - 非空 → `next = next.copyWith(lastCheckAt: now, cachedRelease: CachedRelease(release: c.release, etag: result.etag, fetchedAt: now))` → `_evaluate(next, fromCache: false)`。
7. 捕获 `UpdateException`：
   - manual 且 `preferences.cachedRelease != null` → `_evaluate(next, fromCache: true)`，并把 `failure` 带上。
   - 非 manual 且 `cachedRelease != null` → `_evaluate(next, fromCache: true)`（静默）。
   - 否则 → `UpdateCheckOutcome(status: failure, failure: e.kind, preferences: next)`。

`_evaluate`：无缓存 → `idle`（表示“还没查过/被节流”，不是“没有版本”）；解析缓存 tag 失败 → `noRelease`；`compareToCurrent == upToDate` → `upToDate`；`skippedVersion` 解析后与版本相等 → `skipped`；否则 `available`。成功但过滤后为空只会在第 6 步出现，状态固定 `noRelease`。

- [ ] **Step 4: 偏好加入 `cachedRelease`**

`AppPreferences` 加字段、`copyWith`、`toJson`（`cachedRelease == null ? null : {...}`）、`fromJson`（容错）。补一条往返测试。

- [ ] **Step 5: 装配**

`main.dart`：`final updateSource = GitHubReleasesSource(client: http.Client(), owner: AppInfo.githubOwner, repo: AppInfo.githubRepo, userAgent: 'TomeTone/${AppInfo.version}');`，在 `ProviderScope.overrides` 加入 `updateSourceProvider.overrideWithValue(updateSource)`。
同一步给 `AppInfo` 填仓库常量（`githubOwner = 'wuyanHH'`、`githubRepo = 'TomeTone'`），并更新 `test/app_info_test.dart`：把“未配置”用例改为断言 `hasUpdateSource` 为 true 且 owner/repo 非空。

- [ ] **Step 6: 运行**

Run: `flutter test test/app/update test/app/preferences test/app_info_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/contracts/update lib/app/update lib/app/preferences lib/app/providers/update_providers.dart lib/app/app_info.dart lib/main.dart test/app/update test/app/preferences test/app_info_test.dart
git commit -m "feat(update): 检查服务（24h 节流/缓存/跳过/空结果）"
```

---

### Task 6: 更新控制器与设置页关于区

**Files:**
- Create: `lib/app/providers/update_providers.dart`
- Modify: `lib/ui/pages/settings/settings_page.dart:229-299`（关于区）
- Modify: `pubspec.yaml`（加 `url_launcher`）
- Test: `test/ui/settings_update_section_test.dart`

**Interfaces:**
- Consumes: `UpdateService`、`preferencesProvider`、`UpdateStatus`、`UpdateState`、Task 5 的 `updateServiceProvider`
- Produces:
  - `final NotifierProvider<UpdateController, UpdateState> updateControllerProvider`
  - `UpdateController`：`Future<void> check({required bool manual})`、`Future<void> skipVersion(String version)`、`Future<void> clearSkip()`、`Future<void> acknowledge(String version)`、`Future<void> markPrompted(String version)`、`Future<void> setAutoCheck(bool enabled)`（`maybeAutoCheck` 在 Task 8 加入）
  - `final Provider<bool> updateBadgeProvider`
  - `SettingsPage.updateHistoryKey`、`SettingsPage.autoCheckSwitchKey`、`SettingsPage.updatePageKey`

- [ ] **Step 1: 写失败测试**

用 `InMemoryAppPreferencesStore` + 假 `UpdateSource` 注入，断言：

- 自动检查开关默认开；关闭后 `store.current.autoCheckUpdates == false`。
- 状态为 available 时，行文案 `有新版本 0.2.0-beta.2`，尾部 tag `可更新`；点击进入 `UpdatePage`。
- 状态为 upToDate 时文案 `已是最新`，tag `最新`。
- 状态为 skipped 时文案 `已跳过 0.2.0-beta.2`，tag `已跳过`。
- 状态为 failure 时文案 `检查失败`，tag `失败`。
- 状态为 noRelease 时文案 `暂无可用版本`，tag `暂无`。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/ui/settings_update_section_test.dart`
Expected: FAIL

- [ ] **Step 3: 实现 provider 与控制器**

```
updateControllerProvider: NotifierProvider<UpdateController, UpdateState>(UpdateController.new);
```

`UpdateController.check`：

```dart
Future<void> check({required bool manual}) async {
  if (state.status == UpdateStatus.checking) return;
  final prefs = ref.read(preferencesProvider);
  state = const UpdateState(status: UpdateStatus.checking);
  final outcome = await ref.read(updateServiceProvider).check(preferences: prefs, manual: manual);
  await ref.read(preferencesProvider.notifier).replace(outcome.preferences);
  state = UpdateState(
    status: outcome.status,
    release: outcome.release,
    failure: outcome.failure,
    fromCache: outcome.fromCache,
  );
}
```

`PreferencesNotifier` 增加 `Future<void> replace(AppPreferences next)`（直接 `state = next` 并 save）。
`skipVersion` → 先把传入 tag 归一化为 `versionFromTag(version)?.toString() ?? version`，再 `update((p) => p.copyWith(skippedVersion: normalized, acknowledgedVersion: normalized))`，并把 state 置 `skipped`。
`clearSkip` → `skippedVersion = null`，并重新 `check(manual: true)`。
`acknowledge` / `markPrompted` 同样先归一化再写入；`setAutoCheck` 只改 `autoCheckUpdates`。

`updateBadgeProvider`：

```dart
final bool enabledAndAvailable =
    prefs.autoCheckUpdates && state.status == UpdateStatus.available && release != null;
final String? latest = release == null ? null : versionFromTag(release.tag)?.toString();
return enabledAndAvailable && latest != prefs.acknowledgedVersion;
```

- [ ] **Step 4: 重写关于区**

卡片内自上而下：自动检查开关（`SwitchListTile`，title `自动检查更新`，subtitle `每天最多一次，只读取版本信息`）→ 分隔线 → 检查更新行 → 分隔线 → 更新历史行 → 分隔线 → 版本行 → 分隔线 → 开源许可行。
检查更新行：`onTap` 打开 `UpdatePage` 并触发 `check(manual: true)`；`subtitle`/`trailing` 按 `UpdateStatus` 映射（见测试文案）；`UpdateStatus.checking` 时 `trailing` 为 `SizedBox(16×16, CircularProgressIndicator(strokeWidth: 2))`。
更新历史行：`icon: Icons.history_rounded`，`title: '更新历史'`，`subtitle: '逐版本查看更新内容'`，`onTap` 打开 `UpdateHistoryPage`（Task 9；本任务先建空壳页面，Task 9 填充）。

- [ ] **Step 5: 运行**

Run: `flutter test test/ui/settings_update_section_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/app/providers/update_providers.dart lib/ui/pages/settings pubspec.yaml pubspec.lock test/ui/settings_update_section_test.dart
git commit -m "feat(update): 更新控制器与设置页状态"
```

---

### Task 7: ABI 桥与更新详情页

**Files:**
- Create: `lib/contracts/update/device_architecture.dart`
- Create: `lib/platform/device/abi_bridge.dart`
- Modify: `android/app/src/main/kotlin/com/tometone/app/MainActivity.kt`
- Create: `lib/ui/widgets/markdown_body.dart`
- Create: `lib/ui/pages/settings/update_page.dart`
- Modify: `pubspec.yaml`（加 `flutter_markdown_plus`）
- Modify: `lib/ui/pages/settings/settings_page.dart`（检查更新行 push `UpdatePage`）
- Test: `test/ui/update_page_test.dart`

**Interfaces:**
- Consumes: `UpdateController`、`updateStateProvider`、`preferencesProvider`、`recommendedAbiAsset`
- Produces:
  - `abstract interface class DeviceArchitecture { Future<List<String>> supportedAbis(); }`
  - `class AbiBridge implements DeviceArchitecture`（channel `tometone/device`）
  - `class MarkdownBodyView extends StatelessWidget { String data; }`
  - `class UpdatePage extends ConsumerStatefulWidget`
  - `Keys`: `UpdatePage.downloadKey(String assetName)`、`UpdatePage.releasePageKey`、`UpdatePage.skipKey`、`UpdatePage.unskipKey`、`UpdatePage.retryKey`、`UpdatePage.historyKey`

- [ ] **Step 1: 写失败测试**

断言：
- 有可用更新时显示新版本号、发布日期、Markdown 标题文本与表格首行、三个资产名与大小（`21.9 MB` 形式）、推荐 ABI 标记 `推荐`。
- 点击“跳过此版本” → `store.current.skippedVersion == '0.2.0-beta.2'`，页面显示“已跳过”。
- 再次打开且已跳过 → 显示“取消跳过”；点击后 `skippedVersion == null`。
- `failure` 且无缓存 → 显示失败文案与“重试”。
- `fromCache && failure != null` → 显示“检查失败，显示上次结果”。
- 下载按钮存在且 `tester.tap` 不抛错（`url_launcher` 在测试里用注入的 `LaunchUrl` 回调替代，默认 `launchUrl`）。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/ui/update_page_test.dart`
Expected: FAIL

- [ ] **Step 3: 实现 ABI 桥**

Dart：

```dart
class AbiBridge implements DeviceArchitecture {
  const AbiBridge();
  static const MethodChannel channel = MethodChannel('tometone/device');
  @override
  Future<List<String>> supportedAbis() async {
    try {
      return await channel.invokeListMethod<String>('supportedAbis') ?? const <String>[];
    } on PlatformException {
      return const <String>[];
    } on MissingPluginException {
      return const <String>[];
    }
  }
}
```

Kotlin：`configureFlutterEngine` 中再加一条 `MethodChannel(..., "tometone/device")`，`"supportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())`，`else -> result.notImplemented()`；`import android.os.Build`。

- [ ] **Step 4: 实现 Markdown 与页面**

`MarkdownBodyView`：`MarkdownBody(data: data, selectable: false, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(...))`，表格允许横向滚动（`MarkdownBody` 所在处外包 `SingleChildScrollView(scrollDirection: Axis.horizontal)` 会导致正文也横滚，改为 `MarkdownBody` 外不加滚动，表格由包内默认布局处理；如遇溢出，用 `Wrap` 包裹 `data` 的表格前不特殊处理——实现时以 `flutter test` 不出现 overflow 为准）。
`UpdatePage` 首帧触发 `check(manual: true)` 并 `acknowledge(tag)`；顶部显示当前版本 → 最新版本、发布日期（`yyyy-MM-dd`，不引 intl，手写补零）；正文 `MarkdownBodyView`；资产列表每行：文件名、格式化大小（`MB = bytes / 1024 / 1024`，保留 1 位小数）、`推荐` 标签（`recommendedAbiAsset` 命中）；按钮 `下载` 调 `launchUrl(Uri.parse(asset.downloadUrl), mode: LaunchMode.externalApplication)`、`打开 Release 页` 调 `htmlUrl`；底部 `跳过此版本` / `取消跳过`。
错误与缓存文案按测试。

- [ ] **Step 5: 运行**

Run: `flutter test test/ui/update_page_test.dart`
Expected: PASS
Run: `flutter analyze`

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/kotlin/com/tometone/app/MainActivity.kt lib/contracts/update/device_architecture.dart lib/platform/device lib/ui/widgets/markdown_body.dart lib/ui/pages/settings/update_page.dart lib/ui/pages/settings/settings_page.dart pubspec.yaml pubspec.lock test/ui/update_page_test.dart
git commit -m "feat(update): 更新详情页、Markdown 说明与 ABI 推荐"
```

---

### Task 8: 启动自动检查、红点与一次性提示

**Files:**
- Modify: `lib/ui/app_shell.dart`（`ConsumerStatefulWidget`、红点、SnackBar、首帧触发）
- Modify: `lib/app/providers/update_providers.dart`（`maybeAutoCheck`）
- Modify: `lib/main.dart`（注入 `DeviceArchitecture` 与 `updateSourceProvider`）
- Test: `test/ui/app_shell_update_test.dart`

**Interfaces:**
- Consumes: `updateControllerProvider`、`updateBadgeProvider`、`preferencesProvider`
- Produces: `UpdateController.maybeAutoCheck()` —— 关闭自动检查或 24h 内直接返回；否则 `check(manual: false)`，若结果 `available` 且 `promptedVersion != tag`，由调用方决定提示时机。`AppShell` 暴露 `static const Key settingsBadgeKey`。

- [ ] **Step 1: 写失败测试**

- 自动检查关闭：注入计数用 `FakeUpdateSource`，pump `AppShell`，`pumpAndSettle` 后 `calls == 0`。
- 自动检查开启且发现更新：红点出现（`find.byKey(AppShell.settingsBadgeKey)`）；SnackBar 文案含新版本号；`store.current.promptedVersion == tag`。
- 同一版本第二次启动（`promptedVersion` 已等于 tag）：不再弹 SnackBar，但红点仍在。
- 打开更新页后（`acknowledgedVersion == tag`）红点消失。
- 24h 内（`lastAttemptAt` 为 1 小时前）：`calls == 0`，无红点（无可用状态）。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/ui/app_shell_update_test.dart`
Expected: FAIL

- [ ] **Step 3: 实现**

`AppShell` 改 `ConsumerStatefulWidget`；`initState` 里 `WidgetsBinding.instance.addPostFrameCallback` → `ref.read(updateControllerProvider.notifier).maybeAutoCheck()`，返回后若 `status == available && promptedVersion != tag`：`ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发现新版本 v$tag'), action: SnackBarAction(label: '查看', onPressed: ...打开 UpdatePage...), duration: const Duration(seconds: 7)))`，完成后 `markPrompted(tag)`。`mounted` 必须检查。
红点：`NavigationDestination.icon` 与 `NavigationRailDestination.icon` 在外层包 `Badge(key: AppShell.settingsBadgeKey, isLabelVisible: badge, smallSize: 8, child: Icon(...))`，仅“设置”目的地。

- [ ] **Step 4: 运行**

Run: `flutter test test/ui/app_shell_update_test.dart test/ui/app_smoke_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/app_shell.dart lib/app/providers/update_providers.dart lib/main.dart test/ui/app_shell_update_test.dart
git commit -m "feat(update): 启动自动检查、设置红点与一次性提示"
```

---

### Task 9: 更新历史

**Files:**
- Create: `assets/changelog/CHANGELOG.md`（复制根 `CHANGELOG.md`）
- Create: `lib/app/update/changelog_parser.dart`
- Create: `lib/ui/pages/settings/update_history_page.dart`
- Modify: `pubspec.yaml`（注册 asset）
- Modify: `lib/ui/pages/settings/settings_page.dart`（更新历史行指向真实页面）
- Test: `test/app/update/changelog_parser_test.dart`
- Test: `test/ui/update_history_page_test.dart`
- Test: `test/release/changelog_asset_sync_test.dart`

**Interfaces:**
- Consumes: `MarkdownBodyView`、`SemVer`
- Produces:
  - `class ChangelogEntry { String version; String title; String body; }`
  - `List<ChangelogEntry> parseChangelog(String markdown)` —— 以 `## [` 开头的行切段，版本取方括号内文本，`body` 为该标题之后到下一个 `## ` 之前的原文；按 `SemVer` 倒序（无法解析的排最后，保持原顺序）。
  - `class UpdateHistoryPage extends ConsumerWidget`（或 `StatelessWidget`），`static Future<String> Function() loader = () => rootBundle.loadString('assets/changelog/CHANGELOG.md');` 以便测试替换。
  - `UpdateHistoryPage.currentVersionKey`、`UpdateHistoryPage.entryKey(String version)`

- [ ] **Step 1: 写解析失败测试**

```dart
test('按版本倒序切段并保留正文，“未发布”排最后', () {
  const text = '''
# 更新日志

## [未发布]

- 正在做

## [0.2.0-beta.1] - 2026-10-19

### 新增
- A

## [0.1.0] - 2026-10-01

- B
''';
  final entries = parseChangelog(text);
  expect(entries.map((e) => e.version), ['0.2.0-beta.1', '0.1.0', '未发布']);
  expect(entries.first.body, contains('### 新增'));
  expect(entries.first.body, isNot(contains('0.1.0')));
});
```

- [ ] **Step 2: 运行确认失败，然后实现解析**

Run: `flutter test test/app/update/changelog_parser_test.dart` → FAIL → 实现 → PASS

- [ ] **Step 3: 写页面测试**

- 页面按倒序显示版本标题；当前版本（`AppInfo.version`）带 `当前` 标签。
- 点击某版本条目展开正文，正文中出现 Markdown 标题渲染后的文字（`find.text('新增')`）。
- `loader` 抛错时显示“更新历史读取失败”。

- [ ] **Step 4: 运行确认失败，实现页面与 asset**

Run: `flutter test test/ui/update_history_page_test.dart` → FAIL
创建 `assets/changelog/CHANGELOG.md`（内容为当前根 `CHANGELOG.md` 的完整副本）；`pubspec.yaml` 的 `flutter:` 下加：

```yaml
  assets:
    - assets/changelog/CHANGELOG.md
```

页面：`ListView`，每条 `Card` + `ExpansionTile`，标题 `v${entry.version}`，当前版本尾部 `Chip(label: Text('当前'))`；展开内容 `MarkdownBodyView(data: entry.body)`。

- [ ] **Step 5: 写资产漂移测试**

`test/release/changelog_asset_sync_test.dart`：

```dart
test('assets/changelog/CHANGELOG.md 与仓库根 CHANGELOG.md 完全一致', () {
  final root = File('CHANGELOG.md').readAsStringSync();
  final copy = File('assets/changelog/CHANGELOG.md').readAsStringSync();
  expect(copy, root, reason: '更新历史打包的是根 CHANGELOG 的快照，发版时必须同步');
});
```

- [ ] **Step 6: 运行**

Run: `flutter test test/app/update/changelog_parser_test.dart test/ui/update_history_page_test.dart test/release/changelog_asset_sync_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add assets/changelog lib/app/update/changelog_parser.dart lib/ui/pages/settings/update_history_page.dart lib/ui/pages/settings/settings_page.dart pubspec.yaml test/app/update/changelog_parser_test.dart test/ui/update_history_page_test.dart test/release/changelog_asset_sync_test.dart
git commit -m "feat(update): 应用内更新历史（离线 CHANGELOG 快照）"
```

---

### Task 10: 全量门禁与真机验证

**Files:**
- Modify: 仅修复测试暴露的问题
- Test: 全量

- [ ] **Step 1: 全量静态检查**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: 全量测试**

Run: `flutter test`
Expected: 全部通过；若有既有用例因文案变化失败，改断言而不是改回旧文案。

- [ ] **Step 3: 依赖方向检查**

Run: `dart run tool/ci/check_import_boundaries.dart`
Expected: 通过（`lib/modules/update_github` 不被 `lib/app`/`lib/ui` 直接 import）

- [ ] **Step 4: 手动验收（Android 设备/模拟器）**

1. 关闭“自动检查更新”，冷启动一次，确认无任何 `api.github.com` 请求（`adb logcat` 或抓包代理）。
2. 打开自动检查，冷启动：因版本等于 `v0.2.0-beta.1`，显示“已是最新”，无红点。
3. 临时把 `AppInfo.version` 改为 `0.2.0-beta.0`（仅本地，不提交），冷启动：出现 SnackBar 与红点；打开更新页能看到 Markdown 表格、三个 APK 与 `推荐` 标记；点击下载能在浏览器打开对应资产。
4. 点“跳过此版本”，重启：无 SnackBar、无红点；进入更新页显示“已跳过”与“取消跳过”。
5. 切换色盘 / 深色 / OLED，杀进程重启：选择保持。
6. 改回 `AppInfo.version`。

- [ ] **Step 5: Commit 修复项并推送**

```bash
git add -A
git commit -m "test: 全量门禁与真机验收修正"
git push origin main
```

## Self-Review

- Spec 覆盖：§5 偏好（Task 1）、§6 主题（Task 2）、§7.1 源（Task 4）、§7.2 比较（Task 3）、§7.3 缓存/退避（Task 5）、§7.4 跳过（Task 5/6）、§7.5 触发与提示（Task 8）、§7.6 详情页（Task 7）、§7.7 历史（Task 9）、§10 测试（各任务 + Task 10）。
- Review Focus 的六条都有对应用例：断网（Task 4/5）、偏好损坏（Task 1）、空列表（Task 3/5）、更高版本（Task 3）、跳过与更高版本（Task 5）、24h 与关闭自动检查（Task 5/8）。
- 类型一致性：`UpdateState` / `UpdateCheckOutcome` / `CachedRelease` / `ReleaseInfo` 在所有任务中使用同名同字段；`versionFromTag` 只定义一次（Task 3）。
