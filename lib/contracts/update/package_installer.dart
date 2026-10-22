/// 安装包安装契约（《架构需求文档》2.7 与更新基础设施）。
///
/// 纯 Dart 类，严禁依赖 Flutter。
library;

/// 安装包安装器接口。
abstract interface class PackageInstaller {
  /// 安装指定本地文件路径的 APK 安装包。
  ///
  /// 若成功唤起系统安装界面返回 `true`，安装失败或取消返回 `false`。
  Future<bool> installApk(String filePath);
}
