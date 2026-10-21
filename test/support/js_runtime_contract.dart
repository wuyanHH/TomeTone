import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';

/// 所有 [JsRuntime] 实现共享的行为契约。
Future<void> expectJsRuntimeContract(JsRuntime runtime) async {
  const context = JsContext(
    result: <String, Object?>{
      'title': '长安十二时辰',
      'index': 3,
      'nested': <String, Object?>{'value': 'ok'},
    },
    baseUrl: 'https://e.test/chapters/42?token=abc',
    page: 2,
    key: '关键词',
    source: <String, Object?>{'name': '听友听书'},
  );

  expect(await runtime.evaluate('result.title', context), '长安十二时辰');
  expect(await runtime.evaluate(r'$.title', context), '长安十二时辰');
  expect(await runtime.evaluate('result.nested.value', context), 'ok');
  expect(await runtime.evaluate('source.name', context), '听友听书');
  expect(await runtime.evaluate('page', context), 2);
  expect(await runtime.evaluate('key', context), '关键词');
  expect(await runtime.evaluate("'a' + 1", context), 'a1');
  expect(await runtime.evaluate('(1 + 2)', context), 3);
  expect(await runtime.evaluate('result["index"]', context), 3);
  expect(
    await runtime.evaluate('baseUrl.match(/chapters\\/(\\d+)/)[1]', context),
    '42',
  );
  expect(await runtime.evaluate("'  A  '.trim().toLowerCase()", context), 'a');
  expect(await runtime.evaluate('true', context), isTrue);
  expect(await runtime.evaluate('null', context), isNull);
  expect(await runtime.evaluate('result.missing', context), isNull);

  await expectLater(
    runtime.evaluate('missingName', context),
    throwsA(isA<JsRuntimeException>()),
  );
  await expectLater(
    runtime.evaluate("'unterminated", context),
    throwsA(isA<JsRuntimeException>()),
  );
}
