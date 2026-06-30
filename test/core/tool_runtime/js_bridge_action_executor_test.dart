import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/bridge/mock_js_bridge_gateway.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/js_bridge_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

void main() {
  test('delegates bridge call to gateway', () async {
    final gateway = MockJsBridgeGateway();
    final executor = JsBridgeActionExecutor(gateway: gateway);

    const spec = ToolSpec(
      id: 'bridge.trace_event',
      title: 'Trace event',
      description: 'Bridge trace',
      executorType: ExecutorType.jsBridgeAction,
      inputSchema: [],
      config: {
        'bridgeMethod': 'trace_event',
      },
    );

    final result = await executor.execute(spec, {
      'event': 'home_click',
    });

    expect(result.success, isTrue);
    expect(result.debugMeta['bridgeMethod'], 'trace_event');
  });
}
