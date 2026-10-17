# 模块契约层（`lib/contracts/`）

对应《架构需求文档》§5.1 CONTRACT 层与 §5.3 模块契约总纲：

- 接口（`PlaybackEngine` / `StorageProvider` / 备份 / 更新）
- **能力声明**（capability flags：引擎的 gapless / rate / seek，Provider 的 range / digest / write）
- **结构化错误码**（只抛错误码与上下文，**不含任何 UI 文案**）
- 契约测试套件（`test/contracts/*_conformance.dart`，每个实现必须通过）
- Fake 实现（供上层开发与测试）

## 依赖规则

- 允许：`contracts` → `contracts`
- 禁止：依赖 `ui` / `app` / `domain` / `modules` / `platform`
- 禁止出现 i18n 文案与具体业务概念（书 / 卷 / 章）
- **禁止依赖 `package:flutter/`** —— 契约必须是纯 Dart，否则模块实现无法在
  CLI 工具与契约测试中复用（由 `tool/ci/check_import_boundaries.dart` 强制）

## 目录

| 目录 | 内容 |
| :--- | :--- |
| `diagnostics/` | `LogTag`（模块级日志标签）、`Redactor`（URL / Cookie / Token / 路径脱敏，§9.5 强制） |
| `playback/` | `PlaybackEngine`（§6.1）、源引用、事件、能力、结构化错误、`FakePlaybackEngine` |
| `storage/` | `StorageProvider`（§7.1）、条目 / 元信息 / 能力 / 结构化错误、`FakeStorageProvider` |

## 契约测试套件

实现方在自己的测试里直接调用套件（套件只依赖契约可观测的行为，不含实现假设）：

```dart
runPlaybackEngineConformance(
  createEngine: FakePlaybackEngine.new,
  validSource: () => const LocalFileSource(uri: 'file:///lib/a.mp3'),
  unsupportedSource: () => const LocalFileSource(uri: 'file:///notes.txt'),
);
```

`storage_provider_conformance.dart` 支持可选的 `liveStreams` 探针：
传入后套件会额外断言**取消订阅确实释放了底层传输**（连接池 / 句柄泄漏的通用体检项）。
