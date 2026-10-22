import 'package:flutter/material.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/shelf/book_detail_page.dart';

export 'package:tometone/ui/pages/shelf/book_detail_page.dart'
    show OnlineBookPreviewKeys;

/// 在线书预览页（统一转至 [BookDetailPage.online]）。
class OnlineBookPreviewPage extends StatelessWidget {
  /// 创建在线书预览页。
  const OnlineBookPreviewPage({
    super.key,
    required this.source,
    required this.item,
  });

  /// 当前书源。
  final BookSource source;

  /// 发现结果中的书目摘要。
  final SourceBookSummary item;

  @override
  Widget build(BuildContext context) {
    return BookDetailPage.online(
      source: source,
      item: item,
    );
  }
}
