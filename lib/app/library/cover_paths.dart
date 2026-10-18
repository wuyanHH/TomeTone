/// 封面路径解析：库内相对路径 → UI 可用的绝对文件路径。
///
/// 数据库里 `books.cover_path` / `volumes.cover_path` 都是**相对书库根**的，
/// 而 `Image.file` 只接受绝对路径 —— 传相对路径不会报错，只会静默不显示
/// （`BookCover` 里有 debug assert 兜住这种误用）。
///
/// 放在应用层：这是「相对路径 + 根 URI 语义」的领域知识，UI 不该各自拼字符串。
String? absoluteCoverPath({
  required String? relativePath,
  required String? libraryRootUri,
}) {
  if (relativePath == null || relativePath.isEmpty) {
    return null;
  }
  if (libraryRootUri == null || libraryRootUri.isEmpty) {
    return null;
  }
  final base = libraryRootUri.endsWith('/')
      ? libraryRootUri.substring(0, libraryRootUri.length - 1)
      : libraryRootUri;
  return '$base/$relativePath';
}
