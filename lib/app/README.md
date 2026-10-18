# 应用 / 策略层（`lib/app/`）

对应《架构需求文档》§5.1 图中的 **APP 层**：睡眠定时、智能微回退、跨卷连播调度、
每书偏好、统计心跳、进度写入等**业务策略**全部落在这里 —— 引擎与 Provider 只提供机制。

## 依赖规则

- 允许：`app` → `app` / `domain` / `contracts`
- 禁止：`app` → `ui` / `modules` / `platform`

## 已定内容

- `app_info.dart`：应用元信息与发布纪律常量（版本号规范见 §2.7）。
- `policy/`：播放策略层（睡眠 / 微回退 / 连播 / 每书偏好 / 进度节流）与播放编排，
  全部走注入时钟，可用 Fake 引擎做确定性单测。

## 约定

- 本层只放**纯 Dart** 的策略与 Riverpod provider，不放 Widget。
- 禁止 `import 'package:flutter/material.dart'`：策略与 UI 解耦，保证可在纯 Dart 测试中验证。
- 需要 Flutter 绑定的能力（媒体会话、通知）一律下沉到 `lib/platform/` 与 `lib/modules/`。
