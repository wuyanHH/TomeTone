import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/library/library_root_location.dart';

LibraryRootView _root({
  required String uri,
  String displayName = '本机书库',
  String type = 'local',
}) {
  return LibraryRootView(
    id: 'root-1',
    type: type,
    uri: uri,
    displayName: displayName,
  );
}

void main() {
  group('readableLibraryRootLocation：SAF', () {
    test('primary 卷翻成「内部存储」，路径段直接可读', () {
      expect(
        readableLibraryRootLocation(
          _root(
            uri:
                'content://com.android.externalstorage.documents/tree/'
                'primary%3AAudiobooks',
            type: 'saf',
          ),
        ),
        '内部存储/Audiobooks',
      );
    });

    test('多层目录与中文都完整保留', () {
      expect(
        readableLibraryRootLocation(
          _root(
            uri:
                'content://com.android.externalstorage.documents/tree/'
                'primary%3A%E6%9C%89%E5%A3%B0%E4%B9%A6%2F%E6%AD%A6%E4%BE%A0',
            type: 'saf',
          ),
        ),
        '内部存储/有声书/武侠',
      );
    });

    test('home 卷翻成「文档」', () {
      expect(
        readableLibraryRootLocation(
          _root(
            uri:
                'content://com.android.externalstorage.documents/tree/'
                'home%3ADocuments%2FBooks',
            type: 'saf',
          ),
        ),
        '文档/Documents/Books',
      );
    });

    test('tree URI 末尾的 document 段代表进入的子目录', () {
      expect(
        readableLibraryRootLocation(
          _root(
            uri:
                'content://com.android.externalstorage.documents/tree/'
                'primary%3AAudiobooks/document/'
                'primary%3AAudiobooks%2F%E6%AD%A6%E4%BE%A0',
            type: 'saf',
          ),
        ),
        '内部存储/Audiobooks/武侠',
      );
    });

    test('SD 卡卷名不会裸露成一串编号', () {
      expect(
        readableLibraryRootLocation(
          _root(
            uri:
                'content://com.android.externalstorage.documents/tree/'
                '1234-ABCD%3ABooks',
            type: 'saf',
          ),
        ),
        '存储卡/Books',
      );
    });

    test('未知 provider 退回展示名，不硬翻译不透明编号', () {
      expect(
        readableLibraryRootLocation(
          _root(
            uri: 'content://com.example.cloud/tree/opaque-document-id',
            displayName: '我的网盘',
            type: 'saf',
          ),
        ),
        '我的网盘',
      );
    });

    test('目录名里的 % 只解码一次', () {
      expect(
        readableLibraryRootLocation(
          _root(
            uri:
                'content://com.android.externalstorage.documents/tree/'
                'primary%3A100%25%E5%8D%B7',
            type: 'saf',
          ),
        ),
        '内部存储/100%卷',
      );
    });

    test('坏掉的编码与空 URI 都不抛异常', () {
      expect(
        readableLibraryRootLocation(
          _root(
            uri:
                'content://com.android.externalstorage.documents/tree/%E0%A4%A',
            displayName: '坏路径',
            type: 'saf',
          ),
        ),
        isNotEmpty,
      );
      expect(
        readableLibraryRootLocation(_root(uri: '', displayName: '没有位置')),
        '没有位置',
      );
    });
  });

  group('readableLibraryRootLocation：本地', () {
    test('Windows 盘符路径保留完整层级', () {
      expect(
        readableLibraryRootLocation(
          _root(uri: r'E:\Projects\TomeTone\有声书\武侠\'),
        ),
        r'E:\Projects\TomeTone\有声书\武侠',
      );
    });

    test('POSIX 路径保留完整层级', () {
      expect(
        readableLibraryRootLocation(
          _root(uri: '/storage/emulated/0/Audiobooks/武侠 合集'),
        ),
        '/storage/emulated/0/Audiobooks/武侠 合集',
      );
    });

    test('file URI 也能读成本地路径', () {
      final String readable = readableLibraryRootLocation(
        _root(uri: 'file:///storage/emulated/0/Books'),
      );
      expect(readable, contains('Books'));
      expect(readable, isNot(contains('file://')));
    });
  });
}
