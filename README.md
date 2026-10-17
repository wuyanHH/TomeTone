# TomeTone · 听卷

面向长篇有声书重度用户的**本地优先**藏馆与播放器：高保真、沉浸式、离线完整可用。

- 需求与架构基线：[`docs/tometone_architecture_requirements.md`](docs/tometone_architecture_requirements.md)
- 发布记录（唯一来源）：[`CHANGELOG.md`](CHANGELOG.md)

当前形态：Android-first（`com.tometone.app`，`minSdk 24` / `targetSdk 36`），测试期版本走 `0.x.y-beta.N` 通道。

## 开发

```bash
flutter pub get
flutter analyze                                        # 门禁：0 错误 0 警告
flutter test                                           # 单元测试 + 契约测试 + 依赖方向检查
dart run tool/ci/check_import_boundaries.dart          # 依赖方向门禁（单独可跑）
flutter run -d Medium_Phone_API_36.1                   # 本机 Android 模拟器
```

## 架构分层与依赖方向

```
lib/
  main.dart      装配入口（唯一 composition root，具体实现只在这里注入）
  ui/            UI 层：页面 / 组件 / 主题（只依赖 app / domain / contracts）
  app/           应用 / 策略层：睡眠、微回退、连播调度、每书偏好、统计心跳、进度写入
  domain/        领域服务层：书库服务、播放编排、入库编排
  contracts/     模块契约层：接口 + 能力声明 + 结构化错误码 + 契约测试套件 + Fake
  modules/       模块实现层：播放引擎、StorageProvider 与下载、备份 / 更新 / 诊断
  platform/      平台层：Android 媒体会话 / 前台服务 / SAF / MediaStore
tool/ci/         依赖方向门禁脚本（含负例自检）
```

依赖方向由 `tool/ci/check_import_boundaries.dart` 强制：

| 层 | 允许依赖 |
| :--- | :--- |
| `ui` | `ui` / `app` / `domain` / `contracts` |
| `app` | `app` / `domain` / `contracts` |
| `domain` | `domain` / `contracts` |
| `contracts` | `contracts` |
| `modules` | `modules` / `contracts` / `platform` |
| `platform` | `platform` / `contracts` |

模块实现**不得**感知书 / 卷 / 章等业务概念；策略与机制分离，业务策略永远在核心层。
