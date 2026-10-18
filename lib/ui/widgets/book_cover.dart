import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书籍封面。
///
/// 封面五级继承（《架构需求文档》§2.1）的最后一级是"几何字标兜底"：
/// 无封面时用书名首字（最多两字）+ 主题色块绘制字标，不依赖任何图片资源。
/// 有 [coverPath] 时在其上叠加真实封面，读取失败则静默回落到字标。
///
/// 字标采用"竖排双字 + 书脊 + 内框"的书籍版式；文字整体包在
/// [FittedBox] 中，任意长度、任意字号的标题都不会溢出。
class BookCover extends StatelessWidget {
  /// 创建书籍封面。
  const BookCover({
    required this.title,
    required this.size,
    this.coverPath,
    this.borderRadius,
    super.key,
  });

  /// 字标兜底层的定位键（测试与调试用）。
  static const Key monogramKey = Key('book-cover-monogram');

  /// 封面图路径。**必须是绝对文件路径**。
  ///
  /// 数据库里的 `books.cover_path` / `volumes.cover_path` 是**相对书库根**的，
  /// 调用方必须先用 `library_roots.uri` 拼成绝对路径再传进来 ——
  /// `Image.file` 遇到相对路径不会报错，只会静默不显示图片，
  /// 表现成"封面莫名不见了"。这里用 debug assert 把这种误用当场打出来。
  ///
  /// 为空或读取失败时使用字标兜底。
  final String? coverPath;

  /// 书名，用于取字标与无障碍标签。
  final String title;

  /// 边长（正方形）。
  final double size;

  /// 圆角；默认使用 [AppRadii.cover]。
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius radius = borderRadius ?? AppRadii.cover;
    final String? path = coverPath?.trim();
    final bool hasImage = path != null && path.isNotEmpty;
    assert(
      !hasImage || _isAbsolutePath(path),
      'coverPath 必须是绝对文件路径。库内的 cover_path 相对书库根，'
      '需先与 library_roots.uri 拼接；相对路径会被 Image.file 静默忽略。',
    );

    return Semantics(
      image: true,
      label: '《${_displayTitle()}》封面',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                RepaintBoundary(
                  key: monogramKey,
                  child: _Monogram(title: title, size: size, scheme: scheme),
                ),
                if (hasImage)
                  Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                // 发丝描边压在图片之上，保证深色封面的边界清晰。
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayTitle() {
    final String trimmed = title.trim();
    return trimmed.isEmpty ? '未命名' : trimmed;
  }

  /// 绝对路径判定：POSIX / Android 根、UNC、Windows 盘符。
  static bool _isAbsolutePath(String path) {
    if (path.startsWith('/') || path.startsWith(r'\\')) {
      return true;
    }
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
  }
}

/// 几何字标：书脊、内框与竖排首字。
class _Monogram extends StatelessWidget {
  const _Monogram({
    required this.title,
    required this.size,
    required this.scheme,
  });

  final String title;
  final double size;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final Color base = scheme.primaryContainer;
    final Color spine = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.16),
      base,
    );
    final Color markColor = scheme.onPrimaryContainer;
    final double spineWidth = size * 0.09;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(scheme.surface.withValues(alpha: 0.28), base),
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.12), base),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 书脊。
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.09,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: spine,
                  border: Border(
                    right: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 内框：线装书的版式暗示。
          if (size >= 36)
            Positioned(
              left: spineWidth + size * 0.09,
              top: size * 0.09,
              right: size * 0.09,
              bottom: size * 0.09,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: markColor.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: spineWidth + size * 0.12,
              right: size * 0.10,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _MarkText(
                  characters: _monogramCharacters(title),
                  color: markColor,
                  fontSize: size * 0.34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 取书名首字（最多两字），忽略空白与常见书名号。
  static List<String> _monogramCharacters(String title) {
    String cleaned = title.replaceAll(RegExp(r'[\s\u3000]'), '');
    while (cleaned.isNotEmpty && _leadingMarks.contains(cleaned[0])) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.isEmpty) {
      return const <String>['书'];
    }
    return cleaned.runes
        .take(2)
        .map(String.fromCharCode)
        .toList(growable: false);
  }

  /// 需要剥离的书名号 / 引号 / 括号。
  static const List<String> _leadingMarks = <String>[
    '《',
    '〈',
    '「',
    '『',
    '“',
    '"',
    "'",
    '[',
    '【',
    '(',
    '（',
  ];
}

/// 竖排字标文本。
class _MarkText extends StatelessWidget {
  const _MarkText({
    required this.characters,
    required this.color,
    required this.fontSize,
  });

  final List<String> characters;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontFamily: AppTypefaces.serifFamily,
      fontFamilyFallback: AppTypefaces.serifFallback,
      fontSize: fontSize,
      height: 1.08,
      fontWeight: FontWeight.w600,
      color: color,
    );
    if (characters.length == 1) {
      return Text(characters.single, style: style, maxLines: 1);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String character in characters)
          Text(character, style: style, maxLines: 1),
      ],
    );
  }
}
