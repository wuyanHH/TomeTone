/// 目录授权端口：放弃某个书库根的持久化访问授权。
///
/// 为什么单独一个端口：[DirectoryPicker] 的语义是「让用户选目录」，
/// 「放弃授权」是它的反面动作，混进去会让实现方（含测试替身）被迫实现无关方法。
abstract interface class DirectoryAuthorization {
  /// 放弃 [rootUri] 对应的持久化读授权。返回是否真的放弃了。
  ///
  /// 实现必须**尽力而为**：授权本来就不在、或系统拒绝，都返回 false，
  /// 绝不能让调用方的「移除登记」失败。
  Future<bool> release(String rootUri);
}
