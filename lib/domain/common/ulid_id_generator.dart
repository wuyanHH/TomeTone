import 'dart:math';

import 'id_generator.dart';

/// ULID 生成器：48 位毫秒时间戳 + 80 位随机，Crockford Base32 编码为 26 字符。
///
/// 选择 ULID 的理由（§8.2）：**字典序即时间序**（毫秒级），
/// 因此主键索引天然按创建顺序聚簇，列表分页不需要额外排序字段。
///
/// 同毫秒内不保证单调（后缀为随机数），但 80 位随机使碰撞概率可忽略。
class UlidIdGenerator implements IdGenerator {
  /// 创建生成器。测试可注入确定性的 [random] 与 [clock]。
  UlidIdGenerator({Random? random, DateTime Function()? clock})
    : _random = random ?? Random.secure(),
      _clock = clock ?? DateTime.now;

  /// Crockford Base32 字母表（去掉了易混淆的 I / L / O / U）。
  static const String alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// 编码后长度。
  static const int length = 26;

  final Random _random;
  final DateTime Function() _clock;

  @override
  String next() => encode(timestamp: _clock(), random: _random);

  /// 用给定时间与随机源编码一个 ULID。
  ///
  /// 时间戳取 `timestamp.toUtc().millisecondsSinceEpoch`；超出 48 位的高位被丢弃
  /// （公元 10889 年以后，无需处理）。
  static String encode({required DateTime timestamp, required Random random}) {
    final millis = timestamp.toUtc().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var shift = 45; shift >= 0; shift -= 5) {
      buffer.write(alphabet[(millis >> shift) & 31]);
    }
    for (var index = 0; index < 16; index++) {
      buffer.write(alphabet[random.nextInt(32)]);
    }
    return buffer.toString();
  }

  /// 从 ULID 解码时间戳（诊断 / 测试用）。
  static DateTime decodeTimestamp(String ulid) {
    if (ulid.length != length) {
      throw ArgumentError.value(ulid, 'ulid', 'ULID 长度必须为 $length');
    }
    var millis = 0;
    for (var index = 0; index < 10; index++) {
      final value = alphabet.indexOf(ulid[index]);
      if (value < 0) {
        throw ArgumentError.value(ulid, 'ulid', '非法 Crockford Base32 字符');
      }
      millis = (millis << 5) | value;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
