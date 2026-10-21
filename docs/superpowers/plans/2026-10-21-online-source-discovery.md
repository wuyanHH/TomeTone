# 在线书源 M1-B：规则引擎、发现与详情预览

> **给实现工程师：** 本计划假设你从零接手，按任务顺序执行。每个任务先写失败测试，再实现，再验证，再提交。不要跳过测试权限闸门。
>
> **测试权限：** 在运行任何 `flutter analyze` 或 `flutter test` 之前，必须先取得用户明确许可。每个任务的验证命令都是待执行步骤，不是自动授权。

**目标：** 在 M1-A 的书源导入/管理基础上，交付 Legado 听书源的只读浏览链路：规则引擎（JSONPath、模板、`||`、`##`、受限/QuickJS JS）、HTTP 请求（GET/POST、headers、charset、重定向、限速）、发现分类、搜索、分页、在线书详情预览，以及五栏底部导航。完成后用户能切换书源、浏览分类、搜索、打开详情并查看目录；本计划**不写书目、不播放、不加入书架**，这些属于 M1-C。

**架构：** 规则值对象与纯求值逻辑放 `domain/sources/rules/`；HTTP/JS 只通过 `contracts/sources/` 的接口注入，具体实现放 `modules/`；Legado 规则解析、请求构造与 `SourceEngine` 编排放 `app/sources/legado/`；UI 只依赖 `app` 的 `SourceDiscovery` 接口。模块层不得 import `domain`，否则依赖方向门禁会失败。

**技术栈：** Flutter、Dart 3、Riverpod、Drift、`dart:io` HttpClient、`json_path`、`enough_convert`、QuickJS（spike，可回退到受限求值器）。

**设计文档：** `docs/superpowers/specs/2026-10-20-online-book-sources-design.md`

---

## M1 计划系列

| 计划 | 交付 | 依赖 |
|---|---|---|
| **M1-A（已完成）** | schema v3；书源解析/校验/持久化；导入与管理 UI；虚拟在线根 | 无 |
| **M1-B（本计划）** | 规则引擎、发现/搜索/详情预览、五栏导航、书源测试与健康 | M1-A |
| **M1-C** | 在线书入库、`on_shelf`、书库混排、加入书架、在线播放 | M1-B |
| **M1-D** | 刷新/换源/删除护栏、预下载/缓存、整体验收 | M1-C |

**范围边界：**

- 本计划只实现 `bookSourceType == 1` 的听书源；规则只覆盖设计 §9.6 的 M1 子集：JSONPath、模板、`||`、`##`、`@js:`/`<js>`、exploreUrl、POST/headers/charset、URL options、`nextTocUrl`。
- `&&`、`%%`、`#####`、列表反转、CSS/XPath/Default/AllInOne 选择器不在 M1-B；遇到时给可读错误，不静默返回空。
- 发现结果行**不显示「加入 / 已在书库」**，详情页**不显示「立即收听 / 加入书架」**；M1-C 接入写库与播放后再补。不要放禁用按钮或“下一步支持”占位。
- 详情页是纯预览：打开、翻目录、重试都不得写 `books`、`chapters`、`book_tags` 或进度。
- 书源测试、发现和搜索属于源级请求，可更新 `book_sources.last_test_*` / `consecutive_failures`；详情与目录失败只返回给页面，不污染源健康。
- HTTP 明文源必须可用并显式提示；Android 无法按任意用户域名动态白名单，因此使用全局 `network_security_config` + 导入/来源卡警告，这是有意的取舍。

---

## 全局约束

- 任何请求只允许 `http` / `https`；禁止 `file` / `content` / `intent` / `javascript` / `data`。相对地址按响应最终 URL 解析，再走 `normalizeNetworkUrl`。
- 请求头、响应体、书源规则中的会话值不得进入日志、异常文案、测试名或提交。夹具固定使用 `test-session`，绝不使用真实 `x-listening-session`。
- 单元测试与 widget 测试**不得访问真实站点**；HTTP 测试只连本机 `HttpServer`，规则测试只用夹具和 fake transport。
- 跨源重定向只保留安全头（`user-agent`、`accept`、`accept-language`），丢弃 `authorization`、`cookie` 与书源自定义会话头；最多 5 跳。
- 响应体上限 10 MB；超限、超时、DNS、TLS、HTTP 状态错误都要映射成可读 `SourceFailure`。
- 每源限速：默认串行并间隔 300ms；支持 `1000` 与 `20/60000` 两种写法。DB 的 `concurrent_rate` 是 int，无法表示 `20/60000`，因此引擎从 `rawJson` 解析原始值。
- 在线详情永不写库；预览页不得依赖 `BookSourceService` 的写方法。
- 320dp、系统大字号（至少 2.0）、深色模式下不得溢出；长书名/作者/简介最多两行或可滚动。
- 每个任务一个提交；提交信息用 `feat(sources): ...` / `test(sources): ...` / `fix(sources): ...`。
- 不运行全量 `dart format`（会改写 20 个既有文件）；只格式化新增/修改文件。
- 任何 `flutter analyze` / `flutter test` 前先向用户申请许可；本计划获批不等于测试许可。

---

## Review Focus（最可能咬人的五处）

1. **搜索关键词含引号、`&`、中文时的编码**：POST body 必须仍是合法 JSON，URL 模板必须正确 percent-encode；错误会让真实搜索直接 400 或注入请求体。
2. **`nextTocUrl` 循环/重复页/第二页失败**：必须停在上限 50、章节不重复、`complete=false` 时不得声称完整；否则 M1-D 会 retire 掉正常章节。
3. **切源/搜索/翻页竞态**：旧请求晚到不得覆盖新书源或新关键词的结果；必须用 generation/request token 丢弃陈旧响应。
4. **跨源重定向与会话头**：重定向到另一个 host 时必须丢弃 `authorization`、`cookie` 和自定义会话头；否则会把用户凭证发给第三方。
5. **五栏 + 320dp + 大字号 + 长元数据**：NavigationBar、来源卡、分类 chips、结果行和预览页都要在小屏/大字号/深色下不溢出。

---

## 开工前检查

- [ ] 工作区干净，分支为 `feat/book-sources`，HEAD 至少包含 M1-A 的 `bc79330`。
- [ ] 已读设计 §4.1–4.4、§6、§9.1–9.6、附录 A。
- [ ] 已读 M1-A 计划的任务 7 与 `progress.md`，确认测试权限已重新取得。
- [ ] 基线：`flutter analyze` 无问题、`flutter test` 632 项通过（数量以实际为准）；这两条命令必须先获用户许可。
- [ ] 记录 `flutter build apk --debug` 的包体大小，作为 QuickJS spike 对比基线。
- [ ] 新建 `.superpowers/sdd/2026-10-21-online-source-discovery/progress.md`（该目录被 gitignore，不提交），登记每个任务的测试命令与结果。

---

## 文件地图

**新增（契约/领域）**

- `lib/contracts/sources/js_runtime.dart`
- `lib/contracts/sources/source_http.dart`
- `lib/domain/sources/rules/rule_error.dart`
- `lib/domain/sources/rules/json_path_rule.dart`
- `lib/domain/sources/rules/template_rule.dart`
- `lib/domain/sources/rules/rule_context.dart`
- `lib/domain/sources/discovery/explore_category.dart`
- `lib/domain/sources/discovery/source_models.dart`
- `lib/domain/sources/discovery/source_failure.dart`

**新增（应用/模块）**

- `lib/app/sources/legado/restricted_js_runtime.dart`
- `lib/app/sources/legado/legado_source_rules.dart`
- `lib/app/sources/legado/legado_rule_evaluator.dart`
- `lib/app/sources/legado/legado_request.dart`
- `lib/app/sources/legado/legado_source_engine.dart`
- `lib/app/sources/legado/source_charset.dart`
- `lib/app/sources/source_rate_limiter.dart`
- `lib/app/sources/source_discovery.dart`
- `lib/app/providers/source_engine_providers.dart`
- `lib/modules/source_http/io_source_http_client.dart`
- `lib/modules/source_quickjs/quickjs_js_runtime.dart`（spike 通过才保留）

**新增（UI）**

- `lib/ui/pages/discovery/discovery_page.dart`
- `lib/ui/pages/discovery/discovery_source_card.dart`
- `lib/ui/pages/discovery/discovery_result_tile.dart`
- `lib/ui/pages/discovery/source_switcher_sheet.dart`
- `lib/ui/pages/discovery/online_book_preview_page.dart`
- `lib/ui/widgets/network_cover.dart`

**修改**

- `pubspec.yaml`
- `lib/main.dart`
- `lib/ui/app_tabs.dart`
- `lib/ui/app_shell.dart`
- `lib/ui/pages/shelf/shelf_page.dart`
- `lib/ui/pages/sources/source_management_page.dart`
- `lib/ui/pages/sources/source_import_sheet.dart`
- `lib/domain/sources/book_source_queries.dart`
- `test/ui/app_smoke_test.dart`、`test/ui/shelf_page_test.dart` 及相关书源测试
- `android/app/src/main/AndroidManifest.xml`、新增 `android/app/src/main/res/xml/network_security_config.xml`

---

## 任务 1：规则基础（JSONPath、模板、exploreUrl）

**文件：** 新增 `rule_error.dart`、`json_path_rule.dart`、`template_rule.dart`、`explore_category.dart`；修改 `pubspec.yaml`；新增三个测试文件。

- [ ] 添加依赖 `json_path: ^0.9.0`（不要手写 JSONPath 解析器）。
- [ ] 先写失败测试：
  - `jsonPathMatches(r'$.items[*]', {'items': [{'title': 'A'}, {'title': 'B'}]})` 返回两个 Map。
  - `jsonPathValue(r'$.title', {'title': 'A'}) == 'A'`；无匹配返回 `null`；多匹配返回 `List<Object?>`。
  - 非法表达式抛出 `RuleEvaluationException`，消息不含原始响应体。
  - 模板 `{{page}}` / `{{key}}` / `{{$.count}}` / 混合文本；`null` 变空串。
  - `TemplateOutputMode.url` 对 `a&b 中文` 做 percent-encode；`jsonBody` 插入 `"`、`\`、换行后仍能 `jsonDecode`；`text` 原样。
  - `parseExploreCategories` 支持换行、`&&`、`名称::URL`、`enabledExplore=false`、空行；缺 `::` 的条目跳过。
- [ ] 实现精确签名：

```dart
// rule_error.dart
class RuleEvaluationException implements Exception {
  const RuleEvaluationException(this.message, {this.rule});
  final String message;
  final String? rule;
}

// json_path_rule.dart
List<Object?> jsonPathMatches(String expression, Object? root);
Object? jsonPathValue(String expression, Object? root);

// template_rule.dart
enum TemplateOutputMode { url, jsonBody, text }

typedef TemplateResolver = Future<Object?> Function(String expression);

class TemplateRenderer {
  const TemplateRenderer({required this.resolve});
  final TemplateResolver resolve;
  Future<String> render(String template, {required TemplateOutputMode mode});
}

// explore_category.dart
class ExploreCategory {
  const ExploreCategory({required this.name, required this.urlTemplate});
  final String name;
  final String urlTemplate;
}

List<ExploreCategory> parseExploreCategories({
  required String? exploreUrl,
  required bool enabledExplore,
});
```

- [ ] `TemplateRenderer` 用 `RegExp(r'\{\{\s*(.*?)\s*\}\}')` 找占位符；只替换全部匹配，不递归解析替换结果。
- [ ] `parseExploreCategories` 先按 `\r?\n|&&` 切分，再在每段**第一个** `::` 处切名称/URL；名称和 URL 都 trim 后非空才保留。
- [ ] 运行目标测试（需许可）：`flutter test test/domain/sources/rules test/domain/sources/discovery/explore_category_test.dart`。
- [ ] 提交：`feat(sources): add rule primitives`。

---

## 任务 2：JS 契约与受限求值器

**文件：** 新增 `lib/contracts/sources/js_runtime.dart`、`lib/app/sources/legado/restricted_js_runtime.dart`、`test/support/js_runtime_contract.dart`、`test/app/sources/restricted_js_runtime_test.dart`。

- [ ] 先定义契约：

```dart
class JsContext {
  const JsContext({
    required this.result,
    required this.baseUrl,
    this.page,
    this.key,
    this.source = const <String, Object?>{},
  });
  final Object? result;
  final String baseUrl;
  final int? page;
  final String? key;
  final Map<String, Object?> source;
}

class JsRuntimeException implements Exception {
  const JsRuntimeException(this.message);
  final String message;
}

abstract interface class JsRuntime {
  Future<Object?> evaluate(String script, JsContext context);
  Future<void> dispose();
}
```

- [ ] 写共享契约测试 `expectJsRuntimeContract(JsRuntime runtime)`，至少覆盖：
  - `result.title`、`$` 与 `result` 指向同一对象。
  - `baseUrl`、`page`、`key`、`source.name`。
  - 字符串/数字/布尔/null、`+`、括号、数组下标。
  - `baseUrl.match(/chapters\/(\d+)/)[1]`。
  - 示例脚本（附录 A 的 content）返回完整 URL。
  - 未知标识符/语法错误抛 `JsRuntimeException`。
- [ ] 实现 `RestrictedJsRuntime`：只做表达式，不做语句/赋值/循环；支持 `result`/`$`/`baseUrl`/`page`/`key`/`source`、字面量、成员访问、下标、`+`、括号、正则字面量，以及 `.match()`、`.toString()`、`.trim()`、`.toLowerCase()`、`.toUpperCase()`。遇到不支持语法抛 `JsRuntimeException('不支持的 JS 表达式')`，不带脚本全文。
- [ ] `Future` 实现直接 `Future.value(...)`；`dispose()` 无操作。受限求值器是 M1 的保底实现，即使 QuickJS spike 失败也能完成全部功能。
- [ ] 运行目标测试（需许可）。
- [ ] 提交：`feat(sources): add js runtime contract`。

---

## 任务 3：QuickJS 适配 spike（可回退）

**文件：** 修改 `pubspec.yaml`；新增 `lib/modules/source_quickjs/quickjs_js_runtime.dart`、`integration_test/quickjs_js_runtime_test.dart`；可能修改 `lib/main.dart`。

- [ ] 添加 `quickjs_engine: ^0.1.6`，确认 `flutter pub get` 成功。
- [ ] 实现 `QuickJsJsRuntime implements JsRuntime`：
  - 构造时 `getJavascriptRuntime()`；`evaluate` 把 context 序列化为 JSON，拼成 IIFE：定义 `result`、`$`、`baseUrl`、`page`、`key`、`source`，`return (<script>);`。
  - 用 `JsEvalResult.isError` 判断异常；错误只抛 `JsRuntimeException('JS 执行失败')`，不泄露上下文。
  - `dispose()` 调用底层 `dispose`；重复调用安全。
- [ ] 写 `integration_test/quickjs_js_runtime_test.dart`，复用 `expectJsRuntimeContract`，在 Android 模拟器运行：
  `flutter test integration_test/quickjs_js_runtime_test.dart -d emulator-5554`（需设备与许可）。
- [ ] 记录 `flutter build apk --debug` 的包体大小与基线差值；若构建失败、集成测试失败或 APK 增长超过 15 MB，**回退**：移除依赖、适配器和集成测试，保留 `RestrictedJsRuntime`，在 `progress.md` 记录原因。
- [ ] 仅当 spike 通过才在 `main.dart` 把 `jsRuntimeProvider` 覆盖为 `QuickJsJsRuntime()`；否则不覆盖，默认使用受限实现。
- [ ] 提交（通过时）：`feat(sources): add quickjs js runtime`。

---

## 任务 4：HTTP 传输与字符集

**文件：** 新增 `lib/contracts/sources/source_http.dart`、`lib/modules/source_http/io_source_http_client.dart`、`lib/app/sources/legado/source_charset.dart`；修改 `pubspec.yaml`；新增测试。

- [ ] 添加 `enough_convert: ^1.7.1`（GBK；`gb18030` 先按 GBK 解码，四字节生僻字属于已知限制）。
- [ ] 先定义契约：

```dart
class SourceHttpRequest {
  const SourceHttpRequest({
    required this.url,
    this.method = 'GET',
    this.headers = const <String, String>{},
    this.body,
    this.timeout = const Duration(seconds: 15),
  });
  final Uri url;
  final String method;
  final Map<String, String> headers;
  final String? body;
  final Duration timeout;
}

class SourceHttpResponse {
  const SourceHttpResponse({
    required this.finalUrl,
    required this.statusCode,
    required this.headers,
    required this.bytes,
  });
  final Uri finalUrl;
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bytes;
}

enum SourceTransportFailure { network, timeout, tooLarge, invalidUrl, redirect }

class SourceTransportException implements Exception {
  const SourceTransportException(this.failure, this.message);
  final SourceTransportFailure failure;
  final String message;
}

abstract interface class SourceHttpClient {
  Future<SourceHttpResponse> send(SourceHttpRequest request);
}
```

- [ ] `IoSourceHttpClient`：`maxBytes` 与 `maxRedirects` 可注入（测试用小值）；手动跟随 301/302/303/307/308；303 与非 307/308 的 301/302 改 GET 并丢 body；最多 5 跳；非 http(s)、缺 host 抛 `invalidUrl`；流式读取超过上限立即关闭并抛 `tooLarge`；`SocketException` -> `network`，超时 -> `timeout`。
- [ ] 跨源重定向（scheme/host/port 任一变化）只保留 `user-agent`、`accept`、`accept-language`；删除其余头（大小写不敏感）。
- [ ] `source_charset.dart`：
  ```dart
  String decodeSourceBytes(Uint8List bytes, {String? declaredCharset, String? contentType});
  ```
  从 `contentType` 的 `charset=` 或 `declaredCharset` 取值；`utf-8`/缺省用 utf8；`gbk`/`gb2312`/`gb18030` 用 `GbkCodec(allowInvalid: true)`；不支持编码抛 `FormatException`。
- [ ] 测试：本机 `HttpServer` 验证 GET/POST、headers/body、307 保方法、302 改 GET、跨源丢凭证、5 跳上限、小 `maxBytes` 超限、超时；GBK 字节解码；UTF-8 中文。
- [ ] 运行目标测试（需许可），提交 `feat(sources): add source http client`。

---

## 任务 5：Legado URL options 与请求构造

**文件：** 新增 `lib/app/sources/legado/legado_request.dart`、`test/app/sources/legado_request_test.dart`。

- [ ] 定义：

```dart
class LegadoRequest {
  const LegadoRequest({
    required this.url,
    required this.method,
    required this.headers,
    this.body,
    this.charset,
  });
  final Uri url;
  final String method;
  final Map<String, String> headers;
  final String? body;
  final String? charset;
}

class LegadoRequestBuilder {
  const LegadoRequestBuilder();
  LegadoRequest build({
    required String raw,
    required Uri baseUrl,
    required Map<String, String> sourceHeaders,
    String? key,
    int? page,
    String? defaultCharset,
  });
}
```

- [ ] 解析 `url,{json}`：从最后一个 `,{` 开始尝试 `jsonDecode`；成功才是 options，失败则整串当 URL。options 支持 `method`、`headers`（Map）、`body`、`charset`。
- [ ] URL/body/header 全部走 `TemplateRenderer`：URL 模式 percent-encode；body 模式 JSON 转义；page 数字原样。
- [ ] 相对 URL 先 `baseUrl.resolve`，再 `normalizeNetworkUrl`；headers 合并 `sourceHeaders` 与 options.headers，options 覆盖同名（大小写不敏感）。
- [ ] 默认 `GET`；有 body 且未显式 method 时仍保持 GET（Legado 可 GET 带 body，但只在显式写 `POST` 时用 POST）。
- [ ] 测试：POST JSON body 中关键词含 `"`/`&`/中文仍可 `jsonDecode`；URL query 关键词 percent-encode；相对路径；header 覆盖；缺 options；非法 options JSON；`charset` 透传。
- [ ] 运行目标测试（需许可），提交 `feat(sources): build legado requests`。

---

## 任务 6：规则集解析、表达式求值与限速

**文件：** 新增 `lib/app/sources/legado/legado_source_rules.dart`、`lib/app/sources/legado/legado_rule_evaluator.dart`、`lib/app/sources/source_rate_limiter.dart`、`lib/domain/sources/rules/rule_context.dart`；新增测试。

- [ ] 定义规则集：

```dart
class LegadoSourceRules {
  static LegadoSourceRules parse(BookSource source);
  final String? exploreUrl;
  final String? searchUrl;
  final Map<String, String> exploreFields;
  final Map<String, String> searchFields;
  final Map<String, String> bookInfoFields;
  final Map<String, String> tocFields;
  final Map<String, String> contentFields;
  final SourceRateLimit rateLimit;
}
```

- [ ] `parse` 用 `jsonDecode(source.rawJson)`，只读 `ruleExplore` / `ruleSearch` / `ruleBookInfo` / `ruleToc` / `ruleContent` 中的字符串值；非字符串值忽略。缺 `bookList` 或 `chapterList` 时在对应阶段抛 `RuleEvaluationException`，不要整源解析失败。
- [ ] `SourceRateLimit.parse(Object? raw)`：缺省 `SourceRateLimit(minInterval: 300ms)`；int/数字字符串 -> 间隔毫秒；`"20/60000"` -> 窗口 60s 最多 20 次；非法值回退默认。
- [ ] `LegadoRuleEvaluator` 精确签名：

```dart
class LegadoRuleEvaluator {
  LegadoRuleEvaluator({required JsRuntime jsRuntime});
  Future<Object?> evaluate(String rule, RuleEvaluationContext context);
}
```

- [ ] 求值顺序：trim -> 空规则返回 `null` -> 若以 `@js:` 或 `<js>` 开头，整段交给 JS（不再按 `||` 切）-> 顶层 `||` 逐个尝试，首个非空返回 -> `##` 清洗 -> `{{}}` 模板 -> `$.`/`$[` JSONPath -> 字面量。`&&`、`%%`、`#####`、`@css:`、`@xpath:`、`@json:` 抛“M1 暂不支持该规则”。
- [ ] `||` 切分必须忽略引号和 `{{ }}` 内的 `||`；`##` 只支持单段正则替换为空，`##` 内的 `$1` 替换属于 M2。
- [ ] 模板 resolver：`page`、`key` 直接返回；`$.` 走 JSONPath；其余表达式走 `JsRuntime`；`JsRuntimeException` 转成 `RuleEvaluationException`。
- [ ] `RuleEvaluationContext`：

```dart
class RuleEvaluationContext {
  const RuleEvaluationContext({
    required this.result,
    required this.baseUrl,
    this.page,
    this.key,
    this.source = const <String, Object?>{},
  });
  final Object? result;
  final String baseUrl;
  final int? page;
  final String? key;
  final Map<String, Object?> source;
}
```

- [ ] `SourceRateLimiter`：`Future<void> acquire(String sourceId, SourceRateLimit limit)`；每源串行，按 `clock` 与注入的 `delay` 等待；测试注入零延迟和固定时钟；不同源互不阻塞。
- [ ] 测试：`$.title || $.name` 回退；`##` 去空白；模板混合；`@js` 样本；CSS 规则报可读错误；`20/60000` 解析；同源两次请求间隔、异源并发。
- [ ] 运行目标测试（需许可），提交 `feat(sources): evaluate legado rules`。

---

## 任务 7：领域模型与 SourceEngine（explore/search/bookInfo/toc）

**文件：** 新增 `lib/domain/sources/discovery/source_models.dart`、`lib/domain/sources/discovery/source_failure.dart`、`lib/app/sources/source_engine.dart`、`lib/app/sources/legado/legado_source_engine.dart`；新增夹具与测试。

- [ ] 定义模型：

```dart
class SourceBookSummary {
  final String title;
  final String bookUrl; // 规范化后的绝对 URL，书身份
  final String? author;
  final String? narrator;
  final String? coverUrl;
  final String? intro;
  final String? kind;
  final String? wordCount;
  final String? lastChapter;
  final String? status;
}

class SourceBookInfo extends SourceBookSummary {
  final String tocUrl;
}

class SourceChapter {
  final int index;
  final String title;
  final String rawUrl; // 可含 ,{options}
  final String url;    // 去掉 options 的规范化 URL
  final bool isVip;
}

class SourcePage<T> {
  final List<T> items;
  final bool hasMore;
  final Uri finalUrl;
  final List<String> warnings;
}

class SourceToc {
  final List<SourceChapter> chapters;
  final bool complete;
  final List<String> warnings;
}

class SourceTestReport {
  final Duration latency;
  final int resultCount;
  final String? sampleTitle;
}

enum SourceStage { explore, search, bookInfo, toc, test }
enum SourceFailureKind { network, timeout, httpStatus, encoding, json, rule, authRequired, vipRequired, empty, aborted }

class SourceFailure implements Exception {
  final SourceFailureKind kind;
  final SourceStage stage;
  final String message;
  final int? statusCode;
}
```

- [ ] 定义 `SourceEngine`：

```dart
abstract interface class SourceEngine {
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  );
  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  );
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl);
  Future<SourceToc> toc(BookSource source, SourceBookInfo info);
  Future<SourceTestReport> test(BookSource source);
}
```

- [ ] 新增富夹具 `test/fixtures/sources/tingyou/source_m1b.json` 与 API 响应：
  - 5 个分类（热门/最新/推荐/连载/评书），至少两个分类 URL 不同。
  - `searchUrl` 带 `,{"method":"POST","headers":{"Content-Type":"application/json"},"body":"{\"keyword\":\"{{key}}\",\"page\":{{page}}}"}`。
  - `ruleBookInfo.tocUrl` 使用 `{{$.id}}`；`ruleToc.nextTocUrl` 为 `$.next`；`chapterUrl` 含 `@js:` 或 URL options。
  - `explore_hot_page1.json`、`explore_hot_page2.json`、`search_page1.json`、`book_info.json`、`toc_page1.json`、`toc_page2.json`。
  - header 固定 `test-session`，禁止真实会话。
- [ ] 引擎构造：

```dart
class LegadoSourceEngine implements SourceEngine {
  LegadoSourceEngine({
    required SourceHttpClient http,
    required JsRuntime jsRuntime,
    required SourceRateLimiter rateLimiter,
  });
}
```

- [ ] `explore`：render category URL（page）-> build -> acquire 限速 -> send -> 非 2xx 抛 `httpStatus`（401/403 映射 `authRequired`）-> 解码 -> JSON 解析 -> 取 `bookList` 列表 -> 逐项求字段 -> 跳过缺 title/bookUrl 的项并记 warning -> 解析相对 cover/bookUrl -> 去重 -> `hasMore = rawItems.isNotEmpty`。
- [ ] `search`：空关键词直接抛 `SourceFailure(kind: empty, stage: search)`，不发请求；其余同 explore，keyword/page 进入 URL/body 模板。
- [ ] 所有实际请求（explore / search / bookInfo / toc 每一页 / test）都先 `rateLimiter.acquire(source.id, rules.rateLimit)`，再发 HTTP；详情与目录同样不得绕过限速。
- [ ] `bookInfo`：请求 bookUrl -> 求 `ruleBookInfo` 字段 -> title 缺失回退请求页面的 host/path（不要空白）-> 解析 `tocUrl`；无 `tocUrl` 回退 bookUrl。
- [ ] `toc`：从 `info.tocUrl` 开始；每页求 `chapterList`；逐章求 `chapterName`/`chapterUrl`，缺失标题回退 `第 N 章`，缺失/非法 URL 跳过并 warning；`isVip` 支持 bool/字符串；章节 index 跨页连续。
- [ ] `nextTocUrl`：每页求值；空/`null` 停止；规范化后若与已访问 URL 重复，停止并 `complete=false`；最多 50 页，达到上限也 `complete=false`；第 2 页及以后失败保留已抓章节并 `complete=false`，第 1 页失败抛 `SourceFailure`。
- [ ] `test`：优先第一个分类 page=1；无分类时用关键词“测试”搜索；测时；空结果仍算成功但 `resultCount=0`；失败抛 `SourceFailure(stage: test)`。
- [ ] 错误映射集中在 `_mapFailure`：`SourceTransportException`、`FormatException`、`jsonDecode` 异常、`RuleEvaluationException` 分别映射；消息不含 headers/body/query；HTTP 状态只保留 code。
- [ ] 测试：分类解析、POST 搜索、关键词引号/中文、相对 cover、坏条目跳过、401、超时、坏 JSON、toc 两页、重复 next、第 2 页失败、50 页上限、章节 index、`complete` 语义。
- [ ] 运行目标测试（需许可），提交 `feat(sources): add legado source engine`。

---

## 任务 8：源健康、错误展示与 SourceDiscovery 编排

**文件：** 修改 `lib/domain/sources/book_source_queries.dart`；新增 `lib/app/sources/source_discovery.dart`；新增测试。

- [ ] 给 `BookSourceQueries` 增加并实现：

```dart
Future<void> recordProbe(
  String sourceId, {
  required bool ok,
  String? error,
  DateTime? checkedAt,
});
```

  成功：`lastTestAt=checkedAt`、`lastTestOk=true`、`lastError=null`、`consecutiveFailures=0`；失败：`lastTestAt=checkedAt`、`lastTestOk=false`、`lastError=error`、`consecutiveFailures+1`。不更新 `updatedAt`。所有测试里的 fake/内存 `BookSourceQueries` 实现都要补这个方法，否则编译失败。
- [ ] 定义：

```dart
abstract interface class SourceDiscovery {
  Future<SourcePage<SourceBookSummary>> explore(BookSource source, ExploreCategory category, int page);
  Future<SourcePage<SourceBookSummary>> search(BookSource source, String keyword, int page);
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl);
  Future<SourceToc> toc(BookSource source, SourceBookInfo info);
  Future<SourceTestReport> test(BookSource source);
}

class SourceDiscoveryService implements SourceDiscovery {
  SourceDiscoveryService({
    required SourceEngine engine,
    required BookSourceQueries sources,
    DateTime Function()? clock,
  });
}
```

- [ ] `explore` / `search` / `test` 成功时 `recordProbe(ok: true)`；抛 `SourceFailure` 时 `recordProbe(ok: false, error: failure.message)` 后再 rethrow；非 `SourceFailure` 先包成 `SourceFailure(kind: rule)` 再记录。
- [ ] `bookInfo` / `toc` 只委托引擎，**不**调用 `recordProbe`。
- [ ] 错误文案：`network` “网络不可用”、`timeout` “请求超时”、`authRequired` “需要登录或会话已失效”、`vipRequired` “该内容需要会员”、`json` “返回内容不是有效 JSON”、`rule` “书源规则无法解析”、`httpStatus` “服务返回 HTTP N”、`empty` “没有结果”。不得拼接 query、header 或响应体。
- [ ] 测试：健康成功/失败、连续失败计数、详情/目录不写健康、错误分类文案、recordProbe 不改 updatedAt。
- [ ] 运行目标测试（需许可），提交 `feat(sources): record source health`。

---

## 任务 9：Provider 装配、Android 明文与导入警告

**文件：** 新增 `lib/app/providers/source_engine_providers.dart`；修改 `lib/main.dart`、`lib/ui/pages/sources/source_import_sheet.dart`、`android/app/src/main/AndroidManifest.xml`；新增 `android/app/src/main/res/xml/network_security_config.xml`；补充测试。

- [ ] Provider：

```dart
final Provider<SourceHttpClient> sourceHttpClientProvider =
    Provider<SourceHttpClient>((ref) => throw UnimplementedError('未装配 HTTP 客户端'));
final Provider<JsRuntime> jsRuntimeProvider =
    Provider<JsRuntime>((ref) => RestrictedJsRuntime());
final Provider<SourceRateLimiter> sourceRateLimiterProvider = ...;
final Provider<SourceEngine> sourceEngineProvider = ...;
final Provider<SourceDiscovery> sourceDiscoveryProvider = ...;
final StateProvider<String?> selectedSourceIdProvider = StateProvider((ref) => null);
```

  `sourceEngineProvider` 组合 http/js/limiter；`sourceDiscoveryProvider` 组合 engine 与 `bookSourceQueriesProvider`。
- [ ] `main.dart` 覆盖 `sourceHttpClientProvider` 为 `IoSourceHttpClient()`；若任务 3 spike 通过，再覆盖 `jsRuntimeProvider` 为 `QuickJsJsRuntime()`。测试使用 fake override。
- [ ] 新增 `android/app/src/main/res/xml/network_security_config.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config cleartextTrafficPermitted="true" />
</network-security-config>
```

  在 `<application>` 上加 `android:networkSecurityConfig="@xml/network_security_config"`。这是为了任意用户自建 HTTP 书源；不做全局静默，必须在 UI 显式警告。
- [ ] 导入弹层：URL tab 输入以 `http://` 开头时显示警告“HTTP 明文书源会暴露请求内容，仅建议用于自建/局域网源。”；文件/粘贴成功后由来源卡显示 HTTP 标签。新增测试键 `httpWarningKey`。
- [ ] 测试：HTTP URL 警告出现/消失；HTTPS 不出现；provider 在缺少 HTTP override 时抛错；QuickJS 覆盖不阻塞 host 测试。
- [ ] 运行目标测试（需许可），提交 `feat(sources): wire discovery providers`。

---

## 任务 10：书源管理页测试与 HTTP 标记

**文件：** 修改 `lib/ui/pages/sources/source_management_page.dart`、`test/ui/pages/sources/source_management_page_test.dart` 与测试支撑。

- [ ] 新增键：`testActionKey(id)`、`testDialogKey`、`testDialogCloseKey`、`httpBadgeKey(id)`。
- [ ] 弹出菜单增加“测试”，顺序为 测试 / 编辑 / 删除；点击后调用 `ref.read(sourceDiscoveryProvider).test(item.source)`，对话框显示“成功 · N 条 · X ms · 示例《…》”或“失败 · <message>”；成功后 `_reload()`，失败也刷新以显示健康。
- [ ] 卡片元信息增加 `source.sourceUrl.startsWith('http://')` 的“HTTP 明文”标签；健康文案沿用现有 `lastTestOk`/`consecutiveFailures`。
- [ ] 测试：测试成功更新卡片、测试失败显示可读错误且不泄露会话、菜单项不误触编辑/删除、HTTP 标签。
- [ ] 运行目标测试（需许可），提交 `feat(sources): test sources from management`。

---

## 任务 11：发现页壳、书源切换与分类

**文件：** 新增 `lib/ui/pages/discovery/discovery_page.dart`、`discovery_source_card.dart`、`source_switcher_sheet.dart`、`lib/ui/widgets/network_cover.dart`；新增 widget 测试。

- [ ] `DiscoveryPage` 为 `ConsumerStatefulWidget`，状态：`_sources`、`_source`、`_categories`、`_category`、`_loadingSources`、`_loadingPage`、`_failure`、`_generation`。
- [ ] 初始化：`bookSourceServiceProvider.listSources()`，只保留 `!isDeleted && enabled`；读取 `selectedSourceIdProvider`，不存在则选排序后的第一个；无源显示空态。
- [ ] 页首：`发现` 标题；当前书源卡显示名称、分组、健康（未测试/正常/连续失败 N）、`最近同步`（`lastTestAt`，只有值才显示）、`切换`、`管理`。`管理` 与空态 `导入书源` 都 push `SourceManagementPage`，返回后重新加载源。
- [ ] 切换弹层列出所有启用源，当前项打勾；点选后写 `selectedSourceIdProvider`，重置并加载。弹层底部“管理书源”。
- [ ] 分类：`parseExploreCategories(exploreUrl: source.exploreUrl, enabledExplore: source.enabledExplore)`；有分类时横向 `ChoiceChip`，默认第一个；无分类时不渲染 chips，直接显示“该源没有发现分类，试试搜索”。
- [ ] 空态：没有书源时显示“还没有书源”+“导入书源”+“支持 Legado 听书源 JSON”；有源但无分类且未搜索时显示引导，不显示空白页。
- [ ] 加载/错误：首次加载显示进度；错误显示可读文案 + 重试；本任务只加载书源与分类壳，不请求结果。任务 12 再在初始化、切源、切分类处接入 `_loadFirstPage`，本任务不要写空方法或假结果。
- [ ] `NetworkCover`：`Image.network` + `loadingBuilder` + `errorBuilder` 回退图标；不新增缓存依赖；测试用 `coverUrl: null` 或非法 URL 验证回退。
- [ ] 稳定键：`emptyKey`、`importKey`、`sourceCardKey`、`switchKey`、`manageKey`、`retryKey`、`categoryKey(name)`。
- [ ] Widget 测试：无源空态、导入入口、源卡健康、切换源后分类变化、管理返回刷新、320dp + 2.0 字号 + 深色不溢出。
- [ ] 运行目标测试（需许可），提交 `feat(discovery): add discovery shell`。

---

## 任务 12：发现搜索、结果列表、分页与错误保留

**文件：** 修改 `discovery_page.dart`；新增 `discovery_result_tile.dart`；新增 widget 测试。

- [ ] 搜索框提交式：`TextField` + `onSubmitted`；空字符串不请求；提交后 `_searchMode=true`，结果标题“搜索结果 · 来自 <源名>”+ 清除按钮；清除恢复当前分类第一页。
- [ ] 结果行：封面、书名（最多 2 行）、作者/演播、分类/字数、来源名；点击 push `OnlineBookPreviewPage(source, item)`；不显示加入按钮。
- [ ] 分页：`ScrollController` 距底 200px 触发 `_loadMore`；`_page` 递增；请求期间忽略重复触发；`hasMore=false` 或本页去重后无新项则停止。按 `bookUrl` 去重。
- [ ] 竞态：每次首屏/切源/搜索/刷新 `_generation++`；异步返回后若 generation 不匹配，直接丢弃，不 setState 到当前列表。
- [ ] 下拉刷新：`RefreshIndicator` 重载当前分类或搜索第一页，替换旧列表；失败时保留旧内容，顶部显示“本次加载失败”+ 重试。
- [ ] 错误态：首屏失败且无内容 -> 全屏错误 + 重试；已有内容 -> 顶部 banner，不清空列表；空结果 -> “换个关键词”。
- [ ] 分页失败：保留已加载结果，底部显示“加载下一页失败”+ 重试；再次触发时重试同一页，不跳页。
- [ ] 键：`searchFieldKey`、`searchClearKey`、`resultListKey`、`resultTileKey(bookUrl)`、`loadMoreKey`、`errorBannerKey`、`emptyResultKey`、`retryKey`。
- [ ] Widget 测试：搜索 POST 结果、清空恢复、翻页追加与去重、翻页失败保留、首屏失败/重试、切源后旧响应不覆盖（用 Completer 控制）、320dp/深色/大字号。
- [ ] 运行目标测试（需许可），提交 `feat(discovery): add search and paging`。

---

## 任务 13：在线书详情预览

**文件：** 新增 `lib/ui/pages/discovery/online_book_preview_page.dart`；新增 widget 测试与无写库测试。

- [ ] 构造：

```dart
class OnlineBookPreviewPage extends ConsumerStatefulWidget {
  const OnlineBookPreviewPage({
    super.key,
    required this.source,
    required this.item,
  });
  final BookSource source;
  final SourceBookSummary item;
}
```

- [ ] 初始化并行/串行加载：`bookInfo(source, item.bookUrl)` 成功后 `toc(source, info)`；任何一步失败都保留 `item` 的可用元数据，显示回退与重试。
- [ ] 布局：AppBar 标题 + 来源名；封面（`NetworkCover`）；书名；作者/演播；分类/字数/状态；简介（可展开/滚动）；“预览”徽标；“目录 · N 章”；章节列表只读（不绑定播放）。
- [ ] 预览说明：“预览模式 · 不会写入书库”；不得出现“加入书架”“立即收听”或禁用占位按钮。
- [ ] 目录不完整时显示“目录未完整抓取，共 N 章”；`complete=true` 不显示。目录失败时显示“目录暂不可用”+ 单独重试；书信息仍显示。
- [ ] 加载中显示骨架/进度；错误按 `SourceFailure.message` 显示，不展示 query/header。
- [ ] 稳定键：`loadingKey`、`errorKey`、`retryKey`、`titleKey`、`tocListKey`、`partialTocKey`、`previewNoticeKey`、`chapterKey(index)`。
- [ ] 测试：
  - 打开详情前后 in-memory `books` / `chapters` 行数均为 0（用真实 DB + fake discovery）。
  - 正常信息 + 两页目录；长书名/简介不溢出。
  - 目录部分失败显示提示；书信息失败仍显示 item 回退。
  - 320dp + 2.0 字号 + 深色无 overflow。
- [ ] 运行目标测试（需许可），提交 `feat(discovery): add online book preview`。

---

## 任务 14：五栏导航与书架空态入口

**文件：** 修改 `lib/ui/app_tabs.dart`、`lib/ui/app_shell.dart`、`lib/ui/pages/shelf/shelf_page.dart`；更新 `test/ui/app_smoke_test.dart`、`test/ui/shelf_page_test.dart` 等。

- [ ] `AppTab` 顺序改为 `shelf / discovery / library / chronicle / settings`；注释与 `appTabProvider` 文档同步。
- [ ] `AppShell._pageFor` 增加 `AppTab.discovery => const DiscoveryPage()`；`_destinations` 在书架后插入“发现”（`Icons.explore_outlined` / `Icons.explore`，hint “发现：从书源找书”）；NavigationBar/Rail 自动 5 项。
- [ ] 书架空态增加第二个入口：`ShelfPage.goToDiscoveryKey`，文案“去发现找书”，点击 `appTabProvider.select(AppTab.discovery)`；保留“去书库添加本机目录”。
- [ ] 更新所有依赖 tab 索引/数量的测试；新增：5 个目的地、切到发现、书架空态两个入口、320dp + 大字号标签不换行。
- [ ] 运行目标测试（需许可），提交 `feat(nav): add discovery tab`。

---

## 任务 15：端到端夹具、全量验证与手工冒烟

**文件：** 补充 `test/fixtures/sources/tingyou/` 下的 API 夹具；新增 `test/app/sources/legado_source_engine_fixture_test.dart`；修改 `README`/progress 台账（不提交 progress）。

- [ ] 用 fake HTTP 客户端把富源夹具 + API 夹具串起来，跑完整链路：分类 -> 第二页 -> 搜索 POST -> 详情 -> 两页目录；断言书名、作者、目录数、`complete=true`、无真实网络。
- [ ] 增加负例端到端：第二页目录 500 -> 保留第一页章节且 `complete=false`；重复 `nextTocUrl` -> 停止且不重复章节。
- [ ] 全量门禁（每步先取得许可）：
  - `flutter analyze`
  - `flutter test`
  - `dart run tool/ci/check_import_boundaries.dart`
  - `flutter build apk --debug`
- [ ] 手工冒烟（Android 模拟器）：
  1. 本机启动静态 HTTP 服务，提供 `source.json` 与 API 夹具；源 URL 指向 `http://10.0.2.2:<port>`。
  2. 从书库右上角导入，确认 HTTP 警告与来源卡“HTTP 明文”标签。
  3. 发现页看到 5 个分类；切分类、搜索关键词（含引号/中文）、翻页、下拉刷新。
  4. 打开详情，确认封面/元数据/两页目录；返回发现页。
  5. 用 `adb shell` 或应用内书库确认 `books`/`chapters` 未增加（或仅用内存库测试断言）。
  6. 书源管理点“测试”，确认健康从“未测试”变“正常”；再停掉本地服务测试，确认失败文案与连续失败计数。
  7. 320dp 模拟器/大字号/深色各走一遍发现与预览。
- [ ] 更新 `.superpowers/sdd/2026-10-21-online-source-discovery/progress.md`，记录所有测试结果与已知限制。
- [ ] 提交夹具/端到端测试：`test(sources): cover discovery fixture flow`。

---

## 验收清单

- [ ] 导入 M1-A 的 Legado 听书源后，发现页显示当前源、分组、健康与分类；无源空态可直达导入。
- [ ] 分类来自 `exploreUrl`，顺序稳定；切换分类会重置分页并加载第一页。
- [ ] 搜索支持 POST/body/headers，关键词含引号、`&`、中文不破坏 JSON/URL。
- [ ] 结果列表分页、去重、下拉刷新；翻页失败保留旧内容并可重试。
- [ ] 切源/搜索竞态下，旧响应不会覆盖新状态。
- [ ] 详情页打开不写库；显示信息、封面回退、目录；目录部分失败有提示。
- [ ] 书源管理可“测试”，健康字段更新；详情/目录失败不污染健康。
- [ ] 五栏导航正确，书架空态有“去发现找书”和“去书库添加本机目录”。
- [ ] HTTP 书源可用，导入有警告、来源卡有标记；HTTPS 无警告。
- [ ] 320dp、2.0 字号、深色模式无 overflow。
- [ ] 无真实站点、真实会话、真实音频 URL 进入测试/仓库。
- [ ] `flutter analyze`、`flutter test`、依赖方向门禁、debug APK 全部通过。

---

## 已知限制 / 后续

- CSS/XPath/Default/AllInOne、`&&`、`%%`、`#####`、列表反转、Cookie/WebView 登录、音频解析与播放均不在 M1-B；遇到时给可读“暂不支持”，不要静默空结果。
- GB18030 四字节生僻字按 GBK 解码可能替换；如后续真实源需要，再引入完整 GB18030 codec。
- `network_security_config` 全局允许明文是 Android 的平台限制；用导入警告、来源卡标记和测试动作降低误用，不宣称“安全 HTTP”。
- 发现结果暂不显示加入/已在书库，详情暂无播放入口；M1-C 接入 `books`/`on_shelf`/播放后补齐。
- QuickJS 若 spike 失败，受限求值器覆盖 M1 的简单 JS；复杂源留到 M2。


