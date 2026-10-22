import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/library/preview_audio_player.dart';
import 'package:tometone/ui/pages/library/switch_source_sheet.dart';

class _FakeOnlineBookService implements OnlineBookService {
  SwitchSourceResult? switchResult;
  String? switchedTargetSourceId;

  @override
  Future<SwitchSourceResult> switchSource({
    required String bookId,
    required String targetSourceId,
    required String targetBookUrl,
    String? targetChapterId,
    BookSource? targetSource,
    SourceToc? targetToc,
  }) async {
    switchedTargetSourceId = targetSourceId;
    return switchResult ??
        const SwitchSourceResult(
          isProgressMapped: true,
          currentChapterId: 'ch_mapped',
          totalChapters: 10,
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePreviewPlayer extends PreviewAudioPlayer {
  String? playedUrl;
  bool isStopped = false;

  @override
  Future<void> play(String url) async {
    playedUrl = url;
    isStopped = false;
  }

  @override
  Future<void> stop() async {
    isStopped = true;
  }
}

void main() {
  final now = DateTime(2026, 10, 22);
  final sourceB = BookSource(
    id: 'src_b',
    libraryRootId: 'root_b',
    name: '优质听书源',
    sourceUrl: 'http://src-b.com',
    sourceType: 1,
    rawJson: '{}',
    header: const {},
    enabled: true,
    enabledExplore: true,
    customOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
  final sourceC = BookSource(
    id: 'src_c',
    libraryRootId: 'root_c',
    name: '备用音频源',
    sourceUrl: 'http://src-c.com',
    sourceType: 1,
    rawJson: '{}',
    header: const {},
    enabled: true,
    enabledExplore: true,
    customOrder: 1,
    createdAt: now,
    updatedAt: now,
  );

  final candidateB = SwitchSourceCandidate(
    source: sourceB,
    bookUrl: 'http://src-b.com/book/1',
    latestChapter: '第 100 章 终局',
    latency: const Duration(milliseconds: 150),
    matchScore: 1.0,
    matchBadge: '100% 章节匹配',
    sampleAudioUrl: 'http://src-b.com/sample.mp3',
  );

  final candidateC = SwitchSourceCandidate(
    source: sourceC,
    bookUrl: 'http://src-c.com/book/2',
    latestChapter: '番外 01',
    latency: const Duration(milliseconds: 850),
    matchScore: 0.0,
    matchBadge: '序号可能有差异',
  );

  testWidgets('renders candidates with badges and allows selecting and confirming switch', (tester) async {
    final fakeService = _FakeOnlineBookService();
    final fakePlayer = _FakePreviewPlayer();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SwitchSourceSheet(
              bookId: 'b_test',
              currentBookTitle: '遮天',
              currentSourceId: 'src_a',
              initialCandidates: [candidateB, candidateC],
              onlineBookService: fakeService,
              previewPlayer: fakePlayer,
            ),
          ),
        ),
      ),
    );

    // 1. 验证标题和候选卡片展示
    expect(find.textContaining('遮天'), findsWidgets);
    expect(find.text('优质听书源'), findsOneWidget);
    expect(find.text('备用音频源'), findsOneWidget);

    // 2. 验证延迟徽标与匹配度徽标
    expect(find.text('150ms'), findsOneWidget);
    expect(find.text('850ms'), findsOneWidget);
    expect(find.text('100% 章节匹配'), findsOneWidget);
    expect(find.text('序号可能有差异'), findsOneWidget);

    // 3. 试听片头按钮
    final previewBtn = find.byIcon(Icons.play_circle_outline_rounded);
    expect(previewBtn, findsOneWidget);
    await tester.tap(previewBtn);
    await tester.pump();
    expect(fakePlayer.playedUrl, 'http://src-b.com/sample.mp3');

    // 4. 选中候选源 B 并点击确认切换
    await tester.tap(find.text('优质听书源'));
    await tester.pump();

    final confirmBtn = find.text('确认换源');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(fakeService.switchedTargetSourceId, 'src_b');
  });

  testWidgets('renders on 320dp narrow screen without layout overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SwitchSourceSheet(
                bookId: 'b_test',
                currentBookTitle: '一个非常长的超长书名测试用例',
                currentSourceId: 'src_a',
                initialCandidates: [candidateB, candidateC],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
