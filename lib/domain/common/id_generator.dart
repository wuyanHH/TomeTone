/// ID 生成器端口（《架构需求文档》§8.2）。
///
/// 书 / 卷 / 章的 ID **一经生成即不可变**：文件重绑只更新绑定路径，
/// 不重写 ID —— 否则播放进度与收听统计会与新 ID 脱钩（归属断裂）。
abstract interface class IdGenerator {
  /// 生成一个新的不可变 ID。
  String next();
}
