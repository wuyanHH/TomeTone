# 平台适配层（`lib/platform/`）

对应《架构需求文档》§5.1 PLATFORM 层：Android 媒体会话 / 前台服务 / SAF / MediaStore
等平台能力封装。

## 依赖规则

- 允许：`platform` → `platform` / `contracts`
- 禁止：`platform` → `ui` / `app` / `domain` / `modules`

## 约定

- 平台能力以契约形式暴露给 `modules`，不得泄漏平台类型到上层。
