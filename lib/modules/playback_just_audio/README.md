# `playback_just_audio`

`PlaybackEngine` 的 `just_audio` 实现（《架构需求文档》§6.3 候选·首选）。

## 边界（§6.2 强制）

只做**机制**：解码、输出、位置 / 时长 / 状态播报、音量与倍速。
书 / 卷 / 章、睡眠、微回退、连播、进度写入全部在 `lib/app/policy/` ——
引擎不知道"章"是什么，只认识一个可播放的 URI。

## 必须知道的上游行为

1. **`AudioPlayer.play()` 的 Future 在播放结束时才完成**。`await` 它会把调用方
   挂到章节末尾，所以实现里用 `unawaited` 启动 —— 契约的 `play()` 语义是
   "开始播放"，不是"播放完"。
2. **`paused` 与 `ready` 不可区分**：just_audio 两者都是 `ready + !playing`。
   实现用 `_hasPlayed` 记录"是否播放过"，否则上层会把暂停误判成"就绪"。
3. **错误没有稳定枚举**：`_mapError` 按消息特征归类（404 / 401·403 / socket /
   codec），归类失败一律 `decodeFailed`。宁可提示"无法播放"，也不要吞掉错误。

## 契约测试

真实实现必须通过 `test/contracts/playback_engine_conformance.dart`。该套件需要
设备上的真实音频文件，**不能在 `flutter test`（Host VM）里跑** —— 因此本模块
目前只做编译级验证（APK 构建通过），运行期行为待 Step 6 接 UI 后在模拟器上验证。

## 尚未接线

- 媒体会话 / 前台服务 / MediaNotification（`audio_service`）属于 Step 5d；
  依赖暂不加入，避免出现"已声明但未使用"的配置。
- 字节管道（本地回环代理）属于 M2/M3，届时本模块只接触 `127.0.0.1`。
