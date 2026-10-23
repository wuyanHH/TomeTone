# Legado 听书源规则引擎重构实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构 Legado 听书源规则引擎，全面支持多语句 JS、`java.*`/`source.*` 变量与网络桥接、动态分类识别、`init` 上下文解包、`@put` 变量暂存及 `nextTocUrl` 数组批量翻页，完整兼容「听友听书」与「懒人听书（优+++）」基准听书源。

**Architecture:** 增强 `JsRuntime` 与 `RestrictedJsRuntime` 支持多语句、赋值、循环与宿主内置桥接；重构 `ExploreCategoryParser` 支持 JS 动态求值与非严格 JSON 容错；增强 `LegadoRequestBuilder` 支持 Map 格式请求体；在 `LegadoRuleEvaluator` 中支持 `@put` 与 `ruleBookInfo.init`；重构 `LegadoSourceEngine.toc` 支持 URL 数组批量分页与跨阶段变量传递。

**Tech Stack:** Dart 3, Flutter, `package:json_path`, `package:crypto`, `package:http`.

**Spec:** `docs/superpowers/specs/2026-10-23-legado-rule-engine-refactor-design.md`

## Global Constraints

- 只支持 `bookSourceType == 1`（听书源），不破坏现有本地书架与播放链路。
- 绝不针对任何特定域名（如 `lrts.me`、`tingyou.fm`）编写特化硬编码分支，所有特性均基于 Legado 官方规范通用实现。
- 日志与异常信息绝不包含原始 Cookie、Token 或鉴权请求头。
- 所有单元测试必须在 `flutter test` 环境下完全通过。

## Review Focus

1. **`chapterUrl` 包含多行 `var` 变量声明与分号语句**：在执行多行 JS 时正确声明局部变量并求出最终返回值，章节地址与请求参数不丢失。
2. **`exploreUrl` 包含动态 `@js:` 脚本和 `java.ajax()`**：能在 JS 执行期间发起受限 HTTP 请求，解析出分类列表并过滤 `style` 属性。
3. **`ruleBookInfo` 的 `@put` 变量未能传递到 `ruleToc`**：在详情阶段 `@put:{entityType: ...}` 存入的变量，必须在目录阶段的 `{{java.get("entityType")}}` 中精确读取。
4. **`nextTocUrl` 返回 URL 数组而不是单个字符串**：引擎能遍历数组中的全部翻页 URL，合并所有章节且不发生循环或越界。
5. **`searchUrl` 的 options 中 `body` 直接是 JSON Map**：占位符 `{{key}}`、`{{page}}` 能深入 Map 的字段中完成替换并序列化为合法 JSON。

---

### Task 1: 升级 `JsRuntime` 支持多语句、变量赋值与常用宿主内置桥接

**Files:**
- Modify: `lib/contracts/sources/js_runtime.dart`
- Modify: `lib/app/sources/legado/restricted_js_runtime.dart`
- Test: `test/app/sources/restricted_js_runtime_test.dart`

**Interfaces:**
- Consumes: `JsContext(result, baseUrl, page, key, source, http, variables)`
- Produces: `JsRuntime.evaluate(String script, JsContext context) -> Future<Object?>`
- 支持语法：`var`/`let` 变量声明、赋值（`a = b`）、分号/换行多语句、数组操作（`push`、`map`、`slice`、`split`）、`JSON.parse`、`JSON.stringify`、`Math.ceil/floor`、`RegExp`、`java.ajax`、`source.get/put`、`java.get/put`。

- [ ] **Step 1: 编写多语句执行与变量声明的失败单测**

```dart
// test/app/sources/restricted_js_runtime_test.dart
test('evaluates multi-line script with var statements', () async {
  final runtime = RestrictedJsRuntime();
  const script = '''
    var albumId = baseUrl.match(/chapters\\/(\\d+)/)[1];
    'https://example.com/play?id=' + albumId + '&idx=' + result.index
  ''';
  final result = await runtime.evaluate(
    script,
    const JsContext(
      result: {'index': 5},
      baseUrl: 'https://example.com/chapters/12345',
    ),
  );
  expect(result, 'https://example.com/play?id=12345&idx=5');
});
```

- [ ] **Step 2: 运行测试验证失败**

运行：`flutter test test/app/sources/restricted_js_runtime_test.dart`
预期：FAIL，提示不支持的 JS 语句或未定义变量 `var`。

- [ ] **Step 3: 扩充 `RestrictedJsRuntime` 的 Lexer 与 Parser**

1. 在 `_Lexer` 中支持换行符作为语句边界；
2. 在 `_Parser` 中支持语句列表（Statement List），遇到 `var` / `let` / 标识符赋值时记录到局部作用域 `Map<String, Object?> scope`；
3. 支持 `JSON.parse`、`JSON.stringify`、`Math.ceil`、`Math.floor` 内置对象；
4. 注入 `java.ajax`（支持调用 `context.http`）、`source.get/put`、`java.get/put`、`java.log`。

- [ ] **Step 4: 运行测试验证通过**

运行：`flutter test test/app/sources/restricted_js_runtime_test.dart`
预期：PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/contracts/sources/js_runtime.dart lib/app/sources/legado/restricted_js_runtime.dart test/app/sources/restricted_js_runtime_test.dart
git commit -m "feat(sources): support multi-statement scripts and host bridges in js runtime"
```

---

### Task 2: 重构 `exploreUrl` 分类解析器支持 JS 执行与宽容 JSON

**Files:**
- Modify: `lib/domain/sources/discovery/explore_category.dart`
- Test: `test/domain/sources/discovery/explore_category_test.dart`

**Interfaces:**
- Consumes: `JsRuntime`, `JsContext`
- Produces: `Future<List<ExploreCategory>> resolveExploreCategories(...)`
- 能力：处理静态 `分类::URL`、标准严格 JSON 数组、非严格 JSON 数组（带单引号或未加引号键名）、过滤 `style` 字段、执行 `@js:` / `<js>` 脚本。

- [ ] **Step 1: 编写 `@js:` 分类与非严格 JSON 数组的失败单测**

```dart
// test/domain/sources/discovery/explore_category_test.dart
test('resolves dynamic js exploreUrl with categories', () async {
  final categories = await resolveExploreCategories(
    exploreUrl: r'''@js:
      sort = [];
      sort.push({title: '玄幻', url: '/xh_{{page}}', style: {layout_flexGrow: 1}});
      sort.push({title: '都市', url: '/ds_{{page}}'});
      JSON.stringify(sort);
    ''',
    enabledExplore: true,
    jsRuntime: RestrictedJsRuntime(),
    context: const JsContext(result: null, baseUrl: 'https://example.com'),
  );
  expect(categories.length, 2);
  expect(categories[0].name, '玄幻');
  expect(categories[0].urlTemplate, '/xh_{{page}}');
});
```

- [ ] **Step 2: 运行测试验证失败**

运行：`flutter test test/domain/sources/discovery/explore_category_test.dart`
预期：FAIL，`resolveExploreCategories` 未定义或返回空列表。

- [ ] **Step 3: 实现 `resolveExploreCategories`**

1. 检查 `exploreUrl` 是否包含 `@js:` 或 `<js>`，若包含则调用 `jsRuntime.evaluate` 计算最终结果；
2. 对结果进行解析：若是 `List` 直接提取；若是字符串，先尝试 `jsonDecode`；若失败，执行松散 JSON 修复或正则抽取 `{title: ..., url: ...}`；
3. 保留静态 `::` 文本行切分作为保底回退。

- [ ] **Step 4: 运行测试验证通过**

运行：`flutter test test/domain/sources/discovery/explore_category_test.dart`
预期：PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/domain/sources/discovery/explore_category.dart test/domain/sources/discovery/explore_category_test.dart
git commit -m "feat(sources): support dynamic js and loose json in explore categories"
```

---

### Task 3: 增强 `LegadoRequestBuilder` 支持 Map 格式 Request Body 与占位符插值

**Files:**
- Modify: `lib/app/sources/legado/legado_request.dart`
- Test: `test/app/sources/legado_request_test.dart`

**Interfaces:**
- Consumes: `raw` URL 规则字符串、`baseUrl`、`key`、`page`
- Produces: `LegadoRequest(url, method, headers, body, charset)`
- 能力：当 URL options 中的 `body` 是 Map/List 时，递归替换其中的 `{{key}}` 与 `{{page}}`，并编码为正确的 JSON 字符串。

- [ ] **Step 1: 编写 Map 请求体解析失败单测**

```dart
// test/app/sources/legado_request_test.dart
test('builds request when body option is raw JSON map', () {
  const raw = 'https://api.example.com/search,{"method":"POST","headers":{"Content-Type":"application/json"},"body":{"keyword":"{{key}}","page":{{page}}}}';
  final req = const LegadoRequestBuilder().build(
    raw: raw,
    baseUrl: Uri.parse('https://api.example.com'),
    key: '遮天',
    page: 2,
  );
  expect(req.method, 'POST');
  expect(jsonDecode(req.body!), {'keyword': '遮天', 'page': 2});
});
```

- [ ] **Step 2: 运行测试验证失败**

运行：`flutter test test/app/sources/legado_request_test.dart`
预期：FAIL，`body` 解析错误或类型不匹配。

- [ ] **Step 3: 优化 `LegadoRequestBuilder` 的 options 解析与 body 插值**

1. 当 options 中的 `body` 是 Map 时，递归遍历其键值；
2. 对字符串类型值执行 `{{key}}` / `{{page}}` 替换；若值为 `{{page}}` 且类型可转为数字，则直接保留为 `int`；
3. 将处理后的 Map 序列化为 UTF-8 JSON 字符串。

- [ ] **Step 4: 运行测试验证通过**

运行：`flutter test test/app/sources/legado_request_test.dart`
预期：PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/app/sources/legado/legado_request.dart test/app/sources/legado_request_test.dart
git commit -m "feat(sources): support json map body with placeholder interpolation in legado request"
```

---

### Task 4: 规则求值器增强：支持 `@put:{...}` 变量暂存与 `ruleBookInfo.init` 前置解包

**Files:**
- Modify: `lib/app/sources/legado/legado_rule_evaluator.dart`
- Modify: `lib/domain/sources/rules/rule_context.dart`
- Modify: `lib/domain/sources/discovery/source_models.dart`
- Modify: `lib/app/sources/legado/legado_source_engine.dart`
- Test: `test/app/sources/legado_rule_evaluator_test.dart`

**Interfaces:**
- Consumes: `RuleEvaluationContext`, `rule` 规则文本
- Produces: 字段求值结果，同时将 `@put:{...}` 中的键值写入 `context.variables`，并在 `SourceBookInfo.variables` 中透传。

- [ ] **Step 1: 编写 `@put:{...}` 语法和 `init` 上下文转移的失败单测**

```dart
// test/app/sources/legado_rule_evaluator_test.dart
test('extracts field and executes @put variables', () async {
  final variables = <String, Object?>{};
  final evaluator = LegadoRuleEvaluator(jsRuntime: RestrictedJsRuntime());
  final result = await evaluator.evaluate(
    r'$.name@put:{sections: $.sections, type: $.entityType}',
    RuleEvaluationContext(
      result: {'name': '斗罗大陆', 'sections': 100, 'entityType': 2},
      baseUrl: 'https://example.com',
      sourceVariables: variables,
    ),
  );
  expect(result, '斗罗大陆');
  expect(variables['sections'], 100);
  expect(variables['type'], 2);
});
```

- [ ] **Step 2: 运行测试验证失败**

运行：`flutter test test/app/sources/legado_rule_evaluator_test.dart`
预期：FAIL，不支持 `@put` 语法或未存入变量。

- [ ] **Step 3: 实现 `@put:{...}` 语法解析与 `ruleBookInfo.init` 逻辑**

1. 在 `LegadoRuleEvaluator` 中拆分主规则与 `@put:{...}` 部分；
2. 主规则求值返回字段值，对 `@put` 内部的各规则针对当前节点求值并写入 `context.sourceVariables`；
3. 在 `LegadoSourceEngine.bookInfo` 中，若存在 `fields['init']`，先求值得到新根节点，后续字段针对该新根节点求值；
4. 将产生的变量挂载到 `SourceBookInfo.variables`。

- [ ] **Step 4: 运行测试验证通过**

运行：`flutter test test/app/sources/legado_rule_evaluator_test.dart`
预期：PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/app/sources/legado/legado_rule_evaluator.dart lib/domain/sources/rules/rule_context.dart lib/domain/sources/discovery/source_models.dart lib/app/sources/legado/legado_source_engine.dart test/app/sources/legado_rule_evaluator_test.dart
git commit -m "feat(sources): support @put variable extraction and bookInfo init preprocessing"
```

---

### Task 5: 重构 `LegadoSourceEngine.toc` 支持 URL 数组批量翻页与跨阶段变量传递

**Files:**
- Modify: `lib/app/sources/legado/legado_source_engine.dart`
- Test: `test/app/sources/legado_source_engine_test.dart`

**Interfaces:**
- Consumes: `BookSource source`, `SourceBookInfo info` (携带 `info.variables`)
- Produces: `Future<SourceToc> toc(...)`
- 行为：
  1. 将 `info.variables` 注入到目录求值上下文中，使得 `ruleToc.chapterUrl` 中的 `{{java.get("entityType")}}` 能正确解析；
  2. 求值 `ruleToc.nextTocUrl`，若返回 `List<dynamic>`，则依次抓取数组中的每个 URL 并合并章节，同时保持防循环与 50 页上限。

- [ ] **Step 1: 编写 `nextTocUrl` 返回 URL 数组时的多页目录抓取失败单测**

```dart
// test/app/sources/legado_source_engine_test.dart
test('fetches all chapters when nextTocUrl returns a list of URLs', () async {
  // 模拟首页返回 2 章，nextTocUrl 返回 ['https://api.example.com/menu?page=2']
  // 验证 toc 返回全部章节，包含 page 1 和 page 2
});
```

- [ ] **Step 2: 运行测试验证失败**

运行：`flutter test test/app/sources/legado_source_engine_test.dart`
预期：FAIL，目前只抓取了第 1 页。

- [ ] **Step 3: 实现 `toc` 的数组翻页与上下文变量注入**

1. 将 `info.variables` 注入到 `SourceEvaluationContext`；
2. 当 `nextTocUrl` 求值结果为 `List` 时，将其展开为待爬取队列，依次遍历拉取并累加章节；
3. 单页失败时不崩溃，记录 warning 并返回已有章节。

- [ ] **Step 4: 运行测试验证通过**

运行：`flutter test test/app/sources/legado_source_engine_test.dart`
预期：PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/app/sources/legado/legado_source_engine.dart test/app/sources/legado_source_engine_test.dart
git commit -m "feat(sources): support batch array pagination and variable propagation in toc"
```

---

### Task 6: 「听友听书」与「懒人听书（优+++）」全流程回归与夹具验证

**Files:**
- Create: `test/fixtures/sources/tingyou/real_tingyou_source.json`
- Create: `test/fixtures/sources/lrts/lrts_source.json`
- Create: `test/app/sources/benchmark_sources_regression_test.dart`

**Interfaces:**
- 完整覆盖两个书源真实 JSON 配置的导入、分类识别、搜索、书籍详情、目录抓取及音频播放链接解析全链路。

- [ ] **Step 1: 编写两套基准书源端到端模拟测试**

编写使用 Mock HTTP 响应驱动的端到端测试：
1. 听友听书：测试 `exploreUrl` 分类、`searchUrl` 的 POST Map body、`chapterUrl` 的多行 `var` 脚本解析播放 options；
2. 懒人听书：测试 `exploreUrl` 的 `@js:` 动态生成、`init` 前置解包、`@put` 与 `java.get` 变量传递、`nextTocUrl` 批量数组翻页与章节解析。

- [ ] **Step 2: 运行测试并验证**

运行：`flutter test test/app/sources/benchmark_sources_regression_test.dart`
预期：全部用例 PASS。

- [ ] **Step 3: 运行全量测试套件确保零回归**

运行：`flutter test`
预期：所有现有测试与新测试全部 PASS。

- [ ] **Step 4: 提交**

```bash
git add test/fixtures/sources/ test/app/sources/benchmark_sources_regression_test.dart
git commit -m "test(sources): add full regression tests for tingyou and lrts benchmark sources"
```
