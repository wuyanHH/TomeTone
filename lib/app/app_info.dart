/// 应用元信息与发布纪律（《架构需求文档》2.7）。
///
/// 版本号规范：SemVer；测试期使用 `0.x.y-beta.N`。
/// **`CHANGELOG.md` 是发布记录的唯一来源**；修改 [version] 必须同步
/// `pubspec.yaml` 与 `CHANGELOG.md`（由 `test/app_info_test.dart` 守门）。
abstract final class AppInfo {
  /// 中文产品名。
  static const String appName = '听卷';

  /// 英文产品名。
  static const String appNameLatin = 'TomeTone';

  /// 组织标识（Android namespace / 包名前缀）。
  static const String organization = 'com.tometone';

  /// Android applicationId。
  static const String applicationId = 'com.tometone.app';

  /// 当前版本（不含 build metadata）。
  static const String version = '0.3.0-beta.2';

  /// 当前发布通道。
  static const AppChannel channel = AppChannel.beta;

  /// 更新源主渠道：GitHub Releases（`repos/{owner}/{repo}/releases`）。
  static const String githubOwner = 'wuyanHH';

  /// 更新源主渠道仓库名。
  static const String githubRepo = 'TomeTone';

  /// 回退静态清单地址（可指向可访问镜像）。
  static const String updateManifestUrl = '';

  /// 更新源是否已配置。
  ///
  /// 未配置时"检查更新"应提示未启用，且**不得发起任何网络请求**。
  static bool get hasUpdateSource =>
      githubOwner.isNotEmpty && githubRepo.isNotEmpty;
}

/// 发布通道。
enum AppChannel {
  /// 测试通道（当前）。
  beta('beta'),

  /// 稳定通道。
  stable('stable');

  const AppChannel(this.label);

  /// 对外展示名。
  final String label;
}
