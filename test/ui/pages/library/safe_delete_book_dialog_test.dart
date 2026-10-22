import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/library/safe_delete_book_dialog.dart';

void main() {
  const localBook = BookSummary(
    id: 'b_local',
    title: '三体',
    libraryRootId: 'root_local',
    rootPath: 'SanTi',
    coverSource: CoverSource.typography,
    totalChapters: 30,
    totalDurationMs: 3600000,
    missingChapters: 0,
    sourceType: 'local',
  );

  const localSafRootBook = BookSummary(
    id: 'b_saf',
    title: 'SAF根目录书',
    libraryRootId: 'root_saf',
    rootPath: '', // 挂载在根目录
    coverSource: CoverSource.typography,
    totalChapters: 10,
    totalDurationMs: 1200000,
    missingChapters: 0,
    sourceType: 'local',
  );

  const onlineBook = BookSummary(
    id: 'b_online',
    title: '遮天',
    libraryRootId: 'root_online',
    rootPath: 'http://source.test/book/1',
    coverSource: CoverSource.typography,
    totalChapters: 100,
    totalDurationMs: 0,
    missingChapters: 0,
    sourceType: 'online',
    sourceId: 'src_1',
  );

  testWidgets('Online book dialog offers 移出书架 and 彻底删除', (tester) async {
    SafeDeleteResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showSafeDeleteBookDialog(
                  context,
                  book: onlineBook,
                  isLocal: false,
                );
              },
              child: const Text('删除在线书'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('删除在线书'));
    await tester.pumpAndSettle();

    expect(find.text('删除在线书目'), findsOneWidget);
    expect(find.text('仅移出书架'), findsOneWidget);
    expect(find.text('彻底删除'), findsOneWidget);

    // 默认点击仅移出书架
    await tester.tap(find.text('仅移出书架'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.action, SafeDeleteAction.removeFromShelf);
    expect(result!.deleteLocalFiles, isFalse);
  });

  testWidgets('Local book dialog defaults to 从书库移除记录 and delete files checkbox is unchecked', (tester) async {
    SafeDeleteResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showSafeDeleteBookDialog(
                  context,
                  book: localBook,
                  isLocal: true,
                );
              },
              child: const Text('删除本地书'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('删除本地书'));
    await tester.pumpAndSettle();

    expect(find.text('删除本地书目'), findsOneWidget);
    expect(find.text('从书库移除记录'), findsOneWidget);

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse); // 严禁默认勾选！

    // 点击直接确认移除
    await tester.tap(find.text('确认移除'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.action, SafeDeleteAction.deleteRecord);
    expect(result!.deleteLocalFiles, isFalse);
  });

  testWidgets('Review Focus 5: SAF root or empty rootPath strictly disables delete files checkbox', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSafeDeleteBookDialog(
                context,
                book: localSafRootBook,
                isLocal: true,
                isSafRoot: true,
              ),
              child: const Text('删除SAF根书'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('删除SAF根书'));
    await tester.pumpAndSettle();

    // Checkbox 应被禁用 (onChanged == null)
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.onChanged, isNull);

    // 检查安全护栏警示文字
    expect(find.textContaining('禁止物理删除'), findsOneWidget);
  });

  testWidgets('Checking delete files triggers secondary confirmation alert', (tester) async {
    SafeDeleteResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showSafeDeleteBookDialog(
                  context,
                  book: localBook,
                  isLocal: true,
                  isSafRoot: false,
                );
              },
              child: const Text('删除本地书带文件'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('删除本地书带文件'));
    await tester.pumpAndSettle();

    // 勾选删除物理文件
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // 点击确认删除
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    // 验证弹出二次高危确认弹窗
    expect(find.text('不可撤销警告'), findsOneWidget);
    expect(find.textContaining('物理删除本地音频文件'), findsOneWidget);

    // 点击二次确认按钮
    await tester.tap(find.text('彻底物理删除'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.action, SafeDeleteAction.deleteRecordAndFiles);
    expect(result!.deleteLocalFiles, isTrue);
  });
}
