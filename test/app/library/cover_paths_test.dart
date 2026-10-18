import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/cover_paths.dart';

void main() {
  test('拼接根 URI 与相对路径', () {
    expect(
      absoluteCoverPath(
        relativePath: '三体/cover.jpg',
        libraryRootUri: '/storage/emulated/0/Books',
      ),
      '/storage/emulated/0/Books/三体/cover.jpg',
    );
  });

  test('根 URI 带尾斜杠不会双斜杠', () {
    expect(
      absoluteCoverPath(
        relativePath: '三体/cover.jpg',
        libraryRootUri: '/books/',
      ),
      '/books/三体/cover.jpg',
    );
  });

  test('缺失任一侧都返回 null（UI 走字标兜底）', () {
    expect(
      absoluteCoverPath(relativePath: null, libraryRootUri: '/books'),
      isNull,
    );
    expect(
      absoluteCoverPath(relativePath: '', libraryRootUri: '/books'),
      isNull,
    );
    expect(
      absoluteCoverPath(relativePath: 'a.jpg', libraryRootUri: null),
      isNull,
    );
    expect(
      absoluteCoverPath(relativePath: 'a.jpg', libraryRootUri: ''),
      isNull,
    );
  });
}
