import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

void main() {
  test('executes registered flutter handler', () async {
    final executor = FlutterActionExecutor(
      handlers: {
        'app.get_env': (input) async => {
              'mode': 'debug',
              'input': input,
            },
      },
    );

    const spec = ToolSpec(
      id: 'app.get_env',
      title: 'Get env',
      description: 'Returns env',
      executorType: ExecutorType.flutterAction,
      inputSchema: [],
    );

    final result = await executor.execute(spec, {
      'includePlatform': true,
    });

    expect(result.success, isTrue);
    expect(result.data, {
      'mode': 'debug',
      'input': {
        'includePlatform': true,
      },
    });
  });
}
