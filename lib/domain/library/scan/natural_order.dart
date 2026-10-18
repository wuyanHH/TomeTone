/// 自然排序（《架构需求文档》§2.1「自然排序（保留 + 语料化）」）。
///
/// 把「阿拉伯数字」与「中文序数（一 / 二 / 十 / 百 / 千 / 万）」统一映射为数值再比较，
/// 使 `第2章` 排在 `第10章` 之前、`卷三` 排在 `卷十` 之前。
///
/// 排序口径（可验收，见 `test/domain/library/scan/natural_order_test.dart`）：
///
/// 1. **前缀分组**：序言类 → 楔子类 → 正文 → 番外类（见 [prefixGroups]）。
/// 2. **自然键**：文本与数字交替的 token 序列，逐位比较；数字优先于文本。
/// 3. **确定性兜底**：自然键完全相同时按原始字符串比较 —— 保证全序，
///    让同级章节的顺序在多次扫描之间保持稳定（不会因扫描顺序抖动而重排）。
///
/// 该工具是**纯函数**，不触碰文件系统与数据库，可被扫描、排序、检索共用。
library;

/// 自然排序 token。
sealed class NaturalSortToken {
  const NaturalSortToken();
}

/// 文本 token（比较时忽略大小写）。
final class NaturalTextToken extends NaturalSortToken {
  /// 创建文本 token。
  NaturalTextToken(String raw) : raw = raw, folded = raw.toLowerCase();

  /// 原文（诊断用）。
  final String raw;

  /// 比较用折叠文本。
  final String folded;

  @override
  String toString() => 'text($raw)';
}

/// 数字 token（阿拉伯数字，或中文序数解析结果）。
final class NaturalNumberToken extends NaturalSortToken {
  /// 创建数字 token。
  const NaturalNumberToken(this.value);

  /// 数值。
  final int value;

  @override
  String toString() => 'num($value)';
}

/// 自然排序键。可直接用于 `List.sort`。
class NaturalSortKey implements Comparable<NaturalSortKey> {
  /// 创建排序键。
  const NaturalSortKey({
    required this.groupRank,
    required this.tokens,
    required this.source,
  });

  /// 前缀分组序号（见 [NaturalOrder.prefixGroups]）。
  final int groupRank;

  /// 文本 / 数字 token 序列。
  final List<NaturalSortToken> tokens;

  /// 原始文本，用于同键兜底。
  final String source;

  @override
  int compareTo(NaturalSortKey other) {
    if (groupRank != other.groupRank) {
      return groupRank.compareTo(other.groupRank);
    }

    final shared = tokens.length < other.tokens.length
        ? tokens.length
        : other.tokens.length;
    for (var index = 0; index < shared; index++) {
      final result = _compareToken(tokens[index], other.tokens[index]);
      if (result != 0) {
        return result;
      }
    }
    if (tokens.length != other.tokens.length) {
      // 前缀更短者排前：「第一章」在「第一章续」之前。
      return tokens.length.compareTo(other.tokens.length);
    }
    return source.compareTo(other.source);
  }

  static int _compareToken(NaturalSortToken a, NaturalSortToken b) {
    if (a is NaturalNumberToken && b is NaturalNumberToken) {
      return a.value.compareTo(b.value);
    }
    // 数字优先于文本：「第1章」在「第A章」之前。
    if (a is NaturalNumberToken) {
      return -1;
    }
    if (b is NaturalNumberToken) {
      return 1;
    }
    return (a as NaturalTextToken).folded.compareTo(
      (b as NaturalTextToken).folded,
    );
  }

  @override
  String toString() => 'NaturalSortKey($groupRank, $tokens, $source)';
}

/// 自然排序入口。
abstract final class NaturalOrder {
  /// 前缀分组：**序言** → **楔子** → **正文** → **番外**。
  ///
  /// 这是「既定顺序」的实现口径，改这里即可调整分组，无需改比较器。
  /// 正文组为空集：未命中任何标记的标题自动归入正文（[defaultGroupRank]）。
  static const List<Set<String>> prefixGroups = <Set<String>>[
    <String>{'序', '序言', '自序', '译序', '代序', '前言', '引言', '出版说明', '内容简介'},
    <String>{'楔子', '序幕', '引子', '开篇', '序章'},
    <String>{},
    <String>{'番外', '番外篇', '外传', '后记', '尾声', '附录', '附记', '致谢'},
  ];

  /// 正文分组序号。
  static const int defaultGroupRank = 2;

  /// 构建排序键。
  static NaturalSortKey key(String title) {
    return NaturalSortKey(
      groupRank: _groupRankOf(title),
      tokens: _tokenize(title),
      source: title,
    );
  }

  /// 比较两个标题的自然顺序。
  static int compare(String a, String b) => key(a).compareTo(key(b));

  /// 返回排序后的下标序列。
  ///
  /// 相同标题按**原始下标**兜底，因此结果是确定的（`List.sort` 本身不稳定，
  /// 直接用字符串列表排序会让同名章节的顺序在每次运行中不同）。
  static List<int> sortedIndices(List<String> titles) {
    final keys = <NaturalSortKey>[for (final title in titles) key(title)];
    final indices = List<int>.generate(titles.length, (int index) => index);
    indices.sort((int a, int b) {
      final result = keys[a].compareTo(keys[b]);
      return result != 0 ? result : a.compareTo(b);
    });
    return indices;
  }

  /// 返回排序后的标题列表。
  static List<String> sorted(Iterable<String> titles) {
    final list = titles.toList();
    final indices = sortedIndices(list);
    return <String>[for (final index in indices) list[index]];
  }

  // ---------------------------------------------------------------------------

  static int _groupRankOf(String title) {
    final trimmed = title.trim();
    for (var index = 0; index < prefixGroups.length; index++) {
      for (final marker in prefixGroups[index]) {
        if (_isMarkerPrefix(trimmed, marker)) {
          return index;
        }
      }
    }
    return defaultGroupRank;
  }

  /// 标记必须整词命中：`番外1` / `番外一` / `附录A` 命中，`序曲` 不命中。
  ///
  /// 判定口径：标记后面的字符**不能是普通汉字**，但**允许**中文数字 / 阿拉伯数字 /
  /// 标点 / 结尾 —— 否则 `番外一`（最常见的番外命名）会被错判成正文。
  static bool _isMarkerPrefix(String title, String marker) {
    if (!title.startsWith(marker)) {
      return false;
    }
    if (title.length == marker.length) {
      return true;
    }
    final next = title[marker.length];
    if (!_isCjkLetter(next)) {
      return true;
    }
    return _isChineseNumeral(next);
  }

  static bool _isCjkLetter(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x4E00 && code <= 0x9FFF;
  }

  static List<NaturalSortToken> _tokenize(String input) {
    final tokens = <NaturalSortToken>[];
    final text = StringBuffer();
    var index = 0;

    void flushText() {
      if (text.isNotEmpty) {
        tokens.add(NaturalTextToken(text.toString()));
        text.clear();
      }
    }

    while (index < input.length) {
      final char = input[index];

      if (_isAsciiDigit(char)) {
        final start = index;
        while (index < input.length && _isAsciiDigit(input[index])) {
          index++;
        }
        final run = input.substring(start, index);
        final value = int.tryParse(run);
        if (value == null) {
          // 超长数字（> 64 位，例如毫秒级时间戳命名）不是序数：
          // 按文本处理，绝不能让它抛 FormatException 中断整次扫描。
          text.write(run);
        } else {
          flushText();
          tokens.add(NaturalNumberToken(value));
        }
        continue;
      }

      if (_isChineseNumeral(char)) {
        final start = index;
        while (index < input.length && _isChineseNumeral(input[index])) {
          index++;
        }
        final run = input.substring(start, index);
        final value = parseChineseNumeral(run);
        if (value == null) {
          // 不是合法序数（如「一二」），按普通文本处理。
          text.write(run);
        } else {
          flushText();
          tokens.add(NaturalNumberToken(value));
        }
        continue;
      }

      text.write(char);
      index++;
    }

    flushText();
    return tokens;
  }

  static bool _isAsciiDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  static bool _isChineseNumeral(String char) =>
      chineseNumeralDigits.containsKey(char) ||
      chineseNumeralUnits.containsKey(char);

  /// 解析中文序数（`零` / `一` … `九` / `十` / `百` / `千` / `万` / `两`）。
  ///
  /// 返回 `null` 表示该字符串不是合法序数（例如「一二」这种连续数字），
  /// 调用方应退回按文本比较，避免把普通词语误当数值。
  static int? parseChineseNumeral(String run) {
    if (run.isEmpty) {
      return null;
    }
    // 章号不会超过 4 位；过长的串几乎必然是普通词语（如「万万没想到」），
    // 且 `万` 重复会快速溢出 —— 一律退回文本比较。
    if (run.length > 8 || '万'.allMatches(run).length > 1) {
      return null;
    }

    var total = 0;
    var section = 0;
    var number = 0;

    for (final char in run.split('')) {
      final digit = chineseNumeralDigits[char];
      if (digit != null) {
        // 连续数字（「一二」「一三」）不是序数；零后面接数字是允许的（一百零八）。
        if (number != 0) {
          return null;
        }
        number = digit;
        continue;
      }

      final unit = chineseNumeralUnits[char];
      if (unit == null) {
        return null;
      }
      if (unit == 10000) {
        section += number;
        if (section == 0) {
          section = 1; // 「万」单独出现视为一万
        }
        total += section * unit;
        section = 0;
        number = 0;
      } else {
        if (number == 0) {
          number = 1; // 「十一」的十位是 1
        }
        section += number * unit;
        number = 0;
      }
    }

    return total + section + number;
  }

  /// 中文数字字符 → 数值。
  static const Map<String, int> chineseNumeralDigits = <String, int>{
    '零': 0,
    '〇': 0,
    '一': 1,
    '二': 2,
    '两': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
  };

  /// 中文单位字符 → 权值。
  static const Map<String, int> chineseNumeralUnits = <String, int>{
    '十': 10,
    '百': 100,
    '千': 1000,
    '万': 10000,
  };
}
