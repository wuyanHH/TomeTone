/// 目录选择端口（《架构需求文档》§2.5：Android 11+ 只能通过 SAF 授权目录）。
///
/// 为什么放在契约层：`ui` 与 `app` **不允许** import `lib/platform/`（§5.2），
/// 但设置页需要"弹系统目录选择器"这个能力。端口是唯一合法的通路，
/// 具体实现（SAF）在平台层，由 `main.dart` 注入。
abstract interface class DirectoryPicker {
  /// 弹出系统目录选择器；用户取消返回 `null`。
  ///
  /// 实现必须**持久化**读权限（重启后仍可访问），否则书库根下次启动就失效。
  Future<PickedDirectory?> pickDirectory();
}

/// 用户选中的目录。
class PickedDirectory {
  /// 创建结果。
  const PickedDirectory({required this.uri, required this.name});

  /// 目录标识。SAF 为 tree URI；本地实现可为绝对路径。
  final String uri;

  /// 展示名。
  final String name;

  @override
  String toString() => 'PickedDirectory($name, $uri)';
}
