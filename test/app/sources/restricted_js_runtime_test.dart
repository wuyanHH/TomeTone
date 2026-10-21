import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/restricted_js_runtime.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';

import '../../support/js_runtime_contract.dart';

void main() {
  group('RestrictedJsRuntime', () {
    test('满足 JsRuntime 共享契约', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      await expectJsRuntimeContract(runtime);
    });

    test('复现附录 A 的字符串拼接与 match 表达式', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      const context = JsContext(
        result: <String, Object?>{'index': 7},
        baseUrl: 'https://www.tingyou.fm/api/chapters/123',
      );

      final value = await runtime.evaluate(
        "'https://www.tingyou.fm/play?album=' + "
        "baseUrl.match(/chapters\\/(\\d+)/)[1] + '&index=' + result.index",
        context,
      );

      expect(value, 'https://www.tingyou.fm/play?album=123&index=7');
    });

    test('不支持语句时给可读异常', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);

      await expectLater(
        runtime.evaluate(
          'var x = 1; x',
          const JsContext(result: null, baseUrl: 'https://e.test'),
        ),
        throwsA(isA<JsRuntimeException>()),
      );
    });
  });
}
