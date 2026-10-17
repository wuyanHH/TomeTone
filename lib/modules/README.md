# 模块实现层（`lib/modules/`）

对应《架构需求文档》§5.1 MODULES 层：播放引擎、StorageProvider + 下载、备份 / 更新 / 诊断。

## 依赖规则

- 允许：`modules` → `modules` / `contracts` / `platform`
- 禁止：`modules` → `ui` / `app` / `domain`
  （即模块**不得感知**书 / 卷 / 章等业务概念，也不得依赖 i18n 文案）

## 约定

- 每个实现必须通过 `test/contracts/` 下的统一契约测试套件。
- 实现通过自身暴露的 provider 交由 `lib/main.dart`（唯一装配入口）注入；
  模块内部不得反向 import 上层。
- 日志强制脱敏（URL / Cookie / Token / 路径，见 §9.5）。
