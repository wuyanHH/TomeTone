/// SemVer 2.0.0 解析与比较规范实现（《架构需求文档》2.7）。
library;

/// 语义化版本号（SemVer 2.0.0）。
class SemVer implements Comparable<SemVer> {
  /// 创建语义化版本号。
  const SemVer({
    required this.major,
    required this.minor,
    required this.patch,
    this.prerelease = const <String>[],
  });

  /// 尝试解析 SemVer 2.0.0 字符串。
  ///
  /// 支持标准语法 `X.Y.Z`、`X.Y.Z-prerelease` 以及可选附带的 `+build`。
  /// 校验规则：
  /// - 主版本、次版本、修订号必须为非负整数且不可含有前导零（除非单为 0）；
  /// - 预发布标识以 `.` 分隔，段只能由 `[0-9A-Za-z-]` 组成且非空；
  /// - 纯数字的预发布段同样不可含有前导零（除非单为 0）；
  /// - 语法不合法返回 `null`。
  static SemVer? tryParse(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return null;
    }

    String withoutBuild = text;
    final plusIndex = text.indexOf('+');
    if (plusIndex >= 0) {
      withoutBuild = text.substring(0, plusIndex);
      final buildPart = text.substring(plusIndex + 1);
      if (buildPart.isEmpty) {
        return null;
      }
      final buildSegments = buildPart.split('.');
      for (final segment in buildSegments) {
        if (segment.isEmpty || !_identifierRegex.hasMatch(segment)) {
          return null;
        }
      }
    }

    String corePart;
    String? prePart;
    final dashIndex = withoutBuild.indexOf('-');
    if (dashIndex >= 0) {
      corePart = withoutBuild.substring(0, dashIndex);
      prePart = withoutBuild.substring(dashIndex + 1);
      if (prePart.isEmpty) {
        return null;
      }
    } else {
      corePart = withoutBuild;
    }

    final coreMatch = _coreRegex.firstMatch(corePart);
    if (coreMatch == null) {
      return null;
    }

    final major = int.tryParse(coreMatch.group(1)!);
    final minor = int.tryParse(coreMatch.group(2)!);
    final patch = int.tryParse(coreMatch.group(3)!);
    if (major == null || minor == null || patch == null) {
      return null;
    }

    List<String> prerelease = const <String>[];
    if (prePart != null) {
      final segments = prePart.split('.');
      for (final segment in segments) {
        if (segment.isEmpty || !_identifierRegex.hasMatch(segment)) {
          return null;
        }
        if (_numericRegex.hasMatch(segment)) {
          if (segment.length > 1 && segment.startsWith('0')) {
            return null;
          }
        }
      }
      prerelease = List<String>.unmodifiable(segments);
    }

    return SemVer(
      major: major,
      minor: minor,
      patch: patch,
      prerelease: prerelease,
    );
  }

  static final RegExp _coreRegex =
      RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$');
  static final RegExp _identifierRegex = RegExp(r'^[0-9A-Za-z-]+$');
  static final RegExp _numericRegex = RegExp(r'^\d+$');

  /// 主版本号（重大破坏性变更）。
  final int major;

  /// 次版本号（向后兼容新功能）。
  final int minor;

  /// 修订号（向后兼容修复）。
  final int patch;

  /// 预发布标识分段（如 `['beta', '1']`）。
  final List<String> prerelease;

  /// 是否为预发布版本。
  bool get isPrerelease => prerelease.isNotEmpty;

  @override
  int compareTo(SemVer other) {
    if (major != other.major) {
      return major.compareTo(other.major);
    }
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }
    if (patch != other.patch) {
      return patch.compareTo(other.patch);
    }

    // 正式版（无预发布标识）高于预发布版
    if (prerelease.isEmpty && other.prerelease.isNotEmpty) {
      return 1;
    }
    if (prerelease.isNotEmpty && other.prerelease.isEmpty) {
      return -1;
    }
    if (prerelease.isEmpty && other.prerelease.isEmpty) {
      return 0;
    }

    final minLength = prerelease.length < other.prerelease.length
        ? prerelease.length
        : other.prerelease.length;

    for (var i = 0; i < minLength; i++) {
      final a = prerelease[i];
      final b = other.prerelease[i];
      if (a == b) {
        continue;
      }

      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);

      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      if (aNum != null && bNum == null) {
        return -1;
      }
      if (aNum == null && bNum != null) {
        return 1;
      }
      return a.compareTo(b);
    }

    return prerelease.length.compareTo(other.prerelease.length);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemVer &&
          runtimeType == other.runtimeType &&
          compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(
        major,
        minor,
        patch,
        Object.hashAll(prerelease),
      );

  @override
  String toString() {
    if (prerelease.isEmpty) {
      return '$major.$minor.$patch';
    }
    return '$major.$minor.$patch-${prerelease.join('.')}';
  }
}

/// 从 Git Tag 解析版本号。
///
/// 若 tag 以 `'v'` 或 `'V'` 开头则去除前导 v 后交由 [SemVer.tryParse] 解析。
SemVer? versionFromTag(String tag) {
  var raw = tag.trim();
  if (raw.startsWith('v') || raw.startsWith('V')) {
    raw = raw.substring(1);
  }
  return SemVer.tryParse(raw);
}
