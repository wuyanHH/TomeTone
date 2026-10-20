/// 从 URL 或本地 JSON 文件取得书源原文的端口。
///
/// UI 只依赖此契约；真实实现（网络 / 文件选择器）在 app 层注入，测试用 fake
/// 覆盖，避免 widget test 真正打开系统选择器或访问网络。
class SourceImportFile {
  const SourceImportFile({required this.name, required this.content});

  final String name;
  final String content;
}

abstract interface class SourceImportLoader {
  Future<String> loadFromUrl(String url);

  Future<SourceImportFile?> pickJsonFile();
}
