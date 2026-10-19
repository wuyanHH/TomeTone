import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书籍封面。
///
/// 封面五级继承（《架构需求文档》§2.1）的最后一级是"几何字标兜底"：
/// 无封面时用书名首字（最多两字）+ 主题色块绘制字标，不依赖任何图片资源。
/// 有 [coverPath] 时在其上叠加真实封面，读取失败则静默回落到字标。
///
/// 字标采用"竖排双字 + 书脊 + 四角角饰"的书籍版式；文字整体包在
/// [FittedBox] 中，任意长度、任意字号的标题都不会溢出。
class BookCover extends StatelessWidget {
  /// 创建书籍封面。
  const BookCover({
    required this.title,
    required this.size,
    this.coverPath,
    this.coverImage,
    this.borderRadius,
    super.key,
  });

  /// 字标兜底层的定位键（测试与调试用）。
  static const Key monogramKey = Key('book-cover-monogram');

  /// 字标四角角饰的定位键（测试与调试用）。
  static const Key markFrameKey = Key('book-cover-mark-frame');

  /// 封面图路径。**必须是绝对文件路径**。
  ///
  /// 数据库里的 `books.cover_path` / `volumes.cover_path` 是**相对书库根**的，
  /// 调用方必须先用 `library_roots.uri` 拼成绝对路径再传进来 ——
  /// `Image.file` 遇到相对路径不会报错，只会静默不显示图片，
  /// 表现成"封面莫名不见了"。这里用 debug assert 把这种误用当场打出来。
  ///
  /// 仅在 [coverImage] 为空时生效；为空或读取失败时使用字标兜底。
  final String? coverPath;

  /// 封面图片来源，优先于 [coverPath]。
  ///
  /// 供无法通过 `Image.file` 读取的场景使用：SAF 书库根的封面
  /// 只有 `content://` 之类的 URI，`File(path)` 永远读不到，另一层
  /// 会先把封面字节解码出来，再用 [MemoryImage] 等 provider 传进来。
  ///
  /// 加载/解码失败时静默回落到底层字标，不会抛异常、也不留空白。
  final ImageProvider? coverImage;

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
    final bool hasFile = path != null && path.isNotEmpty;
    // 只有在真正用文件路径绘制时（未提供 coverImage）才校验绝对路径。
    assert(
      coverImage != null || !hasFile || _isAbsolutePath(path),
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
                // 图片层：coverImage 优先于 coverPath；两者都取不到或用不了
                // （读取/解码失败）时静默回落到底层字标，绝不留空白。
                if (coverImage != null)
                  Image(
                    image: coverImage!,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  )
                else if (hasFile)
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

/// 几何字标：书脊、四角角饰与竖排首字。
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
          // 四角角饰：用四段短角线替代整框，保留线装书"版框"的版式暗示，
          // 又不会在大尺寸下于字标上下拉出两条游离的横线。
          if (size >= 36)
            Positioned(
              left: spineWidth + size * 0.085,
              top: size * 0.085,
              right: size * 0.085,
              bottom: size * 0.085,
              child: _CornerFrame(
                key: BookCover.markFrameKey,
                color: markColor.withValues(alpha: 0.30),
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

/// 四角角饰：四段短角线，代替整框避免在字标上下形成游离横线。
class _CornerFrame extends StatelessWidget {
  const _CornerFrame({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerFramePainter(color: color),
      size: Size.infinite,
    );
  }
}

/// 四角角饰画笔：只在容器四角各画一段直角短线。
class _CornerFramePainter extends CustomPainter {
  const _CornerFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // 角臂长度随封面缩放，并夹在窄区间内，保证小尺寸不糊、大尺寸不抢戏。
    final double arm = (size.shortestSide * 0.16).clamp(6.0, 20.0);
    void corner(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin.translate(dx * arm, 0), paint);
      canvas.drawLine(origin, origin.translate(0, dy * arm), paint);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(_CornerFramePainter oldDelegate) =>
      oldDelegate.color != color;
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
