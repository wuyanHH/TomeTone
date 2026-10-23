# 听卷 TomeTone v0.3.0-beta.4

对外测试版本：Legado 听书源规则引擎全链路深度重构，全面兼容「听友听书」与「懒人听书（优+++）」基准源；书架搜索筛选栏空态常驻保活。

## 亮点

**1. Legado 规则引擎深度重构**
- 增强 `RestrictedJsRuntime`：支持多语句 JS 脚本（`var`/`let` 局部变量声明与赋值、分号换行分隔）、循环（for/while）、对象与数组字面量、`JSON.parse/stringify`、`Math.*` 与 `RegExp`；
- 注入完整宿主桥接环境：`source.get/put`、`java.get/put`、`java.ajax`（网络桥接）与 `java.log`；
- 分类解析器 `ExploreCategoryParser`：全面支持 `@js:` / `<js>` 动态分类脚本求值与宽松非严格 JSON 容错解析；
- 规则求值器 `LegadoRuleEvaluator`：支持 `@put:{...}` 跨阶段变量暂存与 `ruleBookInfo.init` 前置数据解包；
- 目录解析引擎 `LegadoSourceEngine.toc`：支持 `nextTocUrl` 数组批量翻页抓取与上下文变量透明透传（如 `{{java.get("entityType")}}`）；
- 全链路回归验证：「听友听书」与「懒人听书（优+++）」基准听书源全流程端到端自动化测试完全通过。

**2. 书架搜索筛选栏空态常驻保活**
- 修复 `SearchFilterBar` 在书架为空（0 册）时被隐藏的问题，去除 `if (hasBooks)` 限制，确保新装与初次进入时搜索筛选栏常驻可见。

## 下载哪个包

按手机 CPU 架构选择（都是同一版本，装错会提示「应用未安装」）：

| 文件 | 适用 |
| :-- | :-- |
| `TomeTone-v0.3.0-beta.4-arm64-v8a.apk` | 绝大多数现代手机（推荐） |
| `TomeTone-v0.3.0-beta.4-armeabi-v7a.apk` | 较老的 32 位设备 |
| `TomeTone-v0.3.0-beta.4-x86_64.apk` | 模拟器 / x86 设备 |

校验值见同目录 `SHA256SUMS.txt`（PowerShell：`Get-FileHash <文件> -Algorithm SHA256`）。

## 版本信息

- versionName：`0.3.0-beta.4`
- versionCode：arm64 = 32004 / armeabi-v7a = 31004 / x86_64 = 34004
- minSdk 24（Android 7.0）/ targetSdk 36（Android 16）
