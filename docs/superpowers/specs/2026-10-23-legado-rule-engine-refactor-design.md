# Legado 听书源规则引擎与分类/目录重构设计

- 日期：2026-10-23
- 状态：已根据 `legado-book-source` 技能规范校准
- 基准文档：
  - `C:\Users\Lenovo\.gemini\config\skills\legado-book-source\SKILL.md`
  - `C:\Users\Lenovo\.gemini\config\skills\legado-book-source\references\legado-rules.md`
  - `docs/superpowers/specs/2026-10-20-online-book-sources-design.md` §9「规则引擎架构」
- 触发背景：实际 Legado 听书源（如「听友听书」、「懒人听书（优+++）」）在分类发现和目录抓取时出现无法识别或目录为空的阻断性缺陷。

---

## 1. 为什么做与现状根因

在导入并使用开源阅读（Legado 3.0）规范的听书源（`bookSourceType: 1`）时，当前规则引擎存在若干关键短板，导致核心链路直接阻断：

### 1.1 现状缺陷诊断

1. **`exploreUrl` 分类识别失败**：
   - 当前分类解析只做了静态的单行 `名称::URL` 拆分和严格的 `jsonDecode`。
   - 实际书源的 `exploreUrl` 广泛使用 JS 脚本（如以 `@js:` 或 `<js>` 开头，在客户端动态调用 `java.ajax()` 请求分类接口，或通过函数拼装包含 `style: {layout_flexGrow: 1}` 的分类列表）。
   - 另有书源包含非严格 JSON（单引号、未加引号的键名）或分组标题行，当前解析器直接返回空列表，导致发现页完全无法呈现分类。

2. **目录查询不到（TOC 解析断裂）**：
   - **多语句 JS 脚本不支持**：许多源的 `chapterUrl`（如听友听书）包含多行 JS 语句（`var albumId = ...; 'https://...'`）。当前 `RestrictedJsRuntime` 仅支持纯单表达式，在遇到 `var` 变量声明、语句分号和局部赋值时直接抛错并跳过所有章节，导致章节列表为空。
   - **缺少变量暂存与 `init` 上下文转移**：如懒人听书使用 `init: "$.data.bookDetail"` 进行数据前置解包，且使用 `@put:{n: $.sections, entityType: $..entityType}` 保存全局变量，后续在 `chapterUrl` 中通过 `{{java.get("entityType")}}` 读取。当前引擎缺失 `init` 和 `@put` 机制。
   - **`nextTocUrl` 数组批量翻页**：实际听书源的 `nextTocUrl` 往往通过 JS 一次性计算并返回全部后续页的 URL 数组（`list.push(href); list`），而非单页递归。当前引擎仅接受单个字符串，导致后续分页全部丢失。

3. **请求选项构建局限**：
   - 听书源在 `searchUrl` 的 options 里，`body` 常常直接编写为 JSON 对象（例如 `,"body":{"keyword":"{{key}}","page":{{page}}}`），而非转义后的字符串形式。当前请求解析器期望 body 是字符串，造成请求体解析不合规或请求失败。

---

## 2. 目标、非目标与反目标

### 2.1 目标

1. **完整兼容用户提供的基准听书源**：以「听友听书」和「懒人听书（优+++）」为回归验证标准，确保发现分类加载、搜索、书籍详情、完整目录分页抓取与音频解析全流程通畅。
2. **可执行完整 JS 语句的运行时集成**：
   - 升级 `JsRuntime`，支持多语句执行、局部变量、循环、正则匹配、数组操作及常见内置函数。
   - 注入合规的宿主环境对象：
     - `result`、`$`、`src`（原始文本或上一步解析结果）
     - `baseUrl`、`page`、`key`
     - `source.get(key)` / `source.put(key, value)`（源作用域变量暂存）
     - `java.get(key)` / `java.put(key, value)`（兼容别名）
     - `java.ajax(url)`（在 JS 中发起受限 HTTP 请求，带源通用头与限速）
     - `java.getString(rule)`、`java.log(msg)`、`java.timeFormatUTC(...)`、`java.longToast(...)`
3. **动态 `exploreUrl` 分类解析**：
   - 支持 `@js:` / `<js>` 动态计算并返回分类数据；
   - 容错解析 JSON 数组（支持属性名无引号、单引号、嵌套对象）、`title/name` 键值、提取有效 URL；
   - 过滤与兼容 `style`、布局权重等 UI 指令。
4. **扩展 Legado 规则求值能力**：
   - 支持 `ruleBookInfo.init`（预处理解包根节点）；
   - 支持 `@put:{k: v}` 规则操作符，在提取字段的同时保存变量到 `source/java` 上下文；
   - `nextTocUrl` 支持返回单个 URL 字符串或 URL 数组（`List<String>`），引擎平滑迭代所有页面；
   - `LegadoRequestBuilder` 兼容 `body` 为 Map/Object 的格式，正确转义插值。

### 2.2 非目标

- 不支持普通文本网文小说阅读源（`bookSourceType: 0`）与正文分页。
- 不引入重型浏览器内核或 WebView DOM 渲染抓取（不爬取依赖复杂反爬/Canvas/纯前端水合的音频）。
- 不绕过 VIP、付费或防盗链（遇到 VIP 章节严格遵照 `isVip` 标识提示用户）。

### 2.3 反目标

- **绝不硬编码**：禁止针对特定域名（如 `lrts.me` 或 `tingyou.fm`）写死特化分支，必须在通用规则引擎机制上实现。
- **绝不泄漏凭证**：日志、异常与状态中绝不输出 Token、Cookie 与敏感鉴权 Header。
- **绝不阻塞 UI 线程**：JS 执行与网络调度保持异步解耦。

---

## 3. 系统架构与关键技术方案

### 3.1 JS 运行时实现（`JsRuntime` 架构）

为了在纯 Dart / Flutter 跨端（Android、Windows、单测 Native 环境）均能稳定高效运行，我们将 JS 执行体系分为两层：

1. **核心桥接层（`JsRuntime` 接口扩展）**：
   - 提供异步执行 `evaluate(String script, JsContext context)`。
   - `JsContext` 增加 `SourceHttpClient` 与 `SourceVariableStore`（支持 `source.get/put` 和 `java.get/put`）。
2. **运行时选型**：
   - 采用标准、成熟的轻量嵌入式 JS 引擎（在 Dart 层面使用嵌入式解释执行器或 `flutter_js` / `quickjs_engine` 等跨平台引擎），完整支持 ES5/ES6 常用语法（Arrow Function、`var`/`let`、循环、`JSON.parse/stringify`、`RegExp`、`split/slice/map`）。
   - 保留原纯 Dart 降级方案作为轻量单测备用，核心解析优先使用功能完备的 JS 解释环境。
3. **宿主函数注入规范**：
   - `java.ajax(url)`：在 Legado 规范中为同步调用（例如 `JSON.parse(java.ajax(fl_url))`）。运行时在执行前分析/拦截或在支持异步暂停的引擎上下文里解析，返回响应文本；必须遵守 `SourceRateLimiter` 频控与源基础 Header 注入。
   - `source.get(k)` / `source.put(k, v)` 与 `java.get(k)` / `java.put(k, v)`：
     - 生命周期与作用域（架构定案）：
       - 源级变量（通过 `source.put` 存入）：缓存在 `LegadoSourceEngine` 内存会话中（`_sourceVariables[sourceId]`）。
       - 书籍级变量（在 `ruleBookInfo` 中通过 `@put:{...}` 或 `java.put` 存入）：附加到 `SourceBookInfo.variables` 字段，并在内存字典 `_bookVariables['$sourceId:$bookUrl']` 中做双重缓存；在执行 `toc(source, info)` 时透明回填到上下文，确保目录解析能够完整获取书籍详情阶段暂存的变量（如 `entityType`）。
   - `java.getString(rule)`：在当前节点上按简单 JSONPath 或字面量求值并转为字符串。
   - `java.timeFormatUTC(timestamp, format, offsetHours)`：标准时间格式化。

### 3.2 发现分类解析器（`ExploreCategoryParser`）升级

重构 `lib/domain/sources/discovery/explore_category.dart`：

```dart
Future<List<ExploreCategory>> resolveExploreCategories({
  required String? exploreUrl,
  required bool enabledExplore,
  required JsRuntime jsRuntime,
  required JsContext context,
}) async
```

1. **JS 触发判断**：若 `exploreUrl` 包含 `@js:` 或 `<js>`，先调用 `jsRuntime.evaluate` 计算最终结果字符串或对象。
2. **宽容 JSON 解析**：
   - 支持由 JS 返回的已解码 `List<dynamic>`；
   - 对字符串形式，若包含 `[`，尝试标准 `jsonDecode`；若失败，执行松散 JSON 正则/格式化（修复未加引号的 key、替换单引号为双引号）再解析；
   - 抽取每一项的 `title`（回退 `name`、`category`）与 `url`；
   - 若 `url` 仍为 `@js:...`（如懒人听书内层分类），原样保留在 `ExploreCategory.urlTemplate` 中，在执行发现请求时由引擎求值。
3. **文本分行回退**：若非 JSON，按 `\n` 或 `&&` 拆分，识别 `分类名::URL`。

### 3.3 规则求值管道（`LegadoRuleEvaluator`）增强

1. **`init` 规则前置**：
   - 在详情页 `ruleBookInfo` 中，若配置了 `init`，先对其求值；
   - 将结果作为后续字段（`name`, `author`, `tocUrl` 等）的 evaluation root context。
2. **`@put:{...}` 提取语法**：
   - 在规则字符串中识别 `@put:{key: rule, ...}` 后缀；
   - 对 `@put` 前部规则正常求值产出当前字段；
   - 对花括号内的键值对逐项求值，并存入 `context.variables`（即 `source.put` / `java.put`）。
3. **动态 URL 求值（`url` 包含 `@js:`）**：
   - 当 `category.urlTemplate` 或 `chapter.url` 以 `@js:` 开头时，直接将当前上下文（含 `page`, `baseUrl`, `key`, `source`）传入 JS 运行，返回计算后的真实请求 URL 与选项。

### 3.4 目录解析器（`toc`）多页与数组翻页支持

在 `LegadoSourceEngine.toc()` 中重构翻页逻辑：

```dart
// nextTocUrl 规则求值可能返回：
// 1. null / "" -> 目录结束
// 2. 单个 String URL -> 加载下一页，继续循环
// 3. List<dynamic> (URL 列表) -> 直接获取到了全部后续分页的 URL 集合
```

- 当返回为数组时，引擎无需继续递归求 `nextTocUrl`，而是按顺序遍历拉取数组中所有分页并合并章节。
- 保证已访问 URL 判重与最大 50 页安全护栏依然有效。

### 3.5 请求构建器（`LegadoRequestBuilder`）兼容增强

- 当 options 中的 `body` 本身是 Map 或 List 时，不强制要求为字符串，先进行占位符（`{{key}}`、`{{page}}`）递归插值，再自动序列化为合法的 JSON 字符串。
- 正确处理 `Content-Type: application/json` 请求头。

---

## 4. 验证计划与测试用例

1. **单元测试与夹具测试**：
   - 增加「听友听书」真实格式测试用例（覆盖多行 JS `chapterUrl`、Map 请求体 `searchUrl`、章节目录抓取）。
   - 增加「懒人听书（优+++）」真实格式测试用例（覆盖 `@js:` 分类请求 `java.ajax`、`init` 前置上下文、`@put` 与 `java.get` 变量传递、`nextTocUrl` 数组批量翻页）。
2. **规则求值器专门测试**：
   - `@put:{...}` 语法提取与变量写入测试。
   - 多行 JS 语句、Arrow Function、变量声明赋值求值测试。
3. **全流程回归**：
   - 运行项目全量测试套件 `flutter test`，确保原有本地书架、音频播放等功能零回归。

---

## 5. 待构建者决定的实现细节

- JS 运行时的打包与依赖落地细节（优先使用满足跨端与单测纯 Dart 环境的轻量级方案）。
- 请求超时控制与多页目录合并时的微秒级频控处理。
- `java.timeFormatUTC` 在不同时间戳进制（秒/毫秒）下的容错格式化。
