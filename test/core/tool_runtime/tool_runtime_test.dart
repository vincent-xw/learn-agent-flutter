import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/bridge/mock_js_bridge_gateway.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/js_bridge_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';
import 'package:learn_agent_flutter/core/tool_runtime/registry/tool_registry.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime_context.dart';

void main() {
  test('runtime validates input executes tool and stores log', () async {
    final registry = ToolRegistry();
    const spec = ToolSpec(
      id: 'app.get_env',
      title: 'Get env',
      description: 'Returns env',
      executorType: ExecutorType.flutterAction,
      inputSchema: [],
    );
    registry.register(spec);

    final runtime = ToolRuntime(
      context: ToolRuntimeContext(
        registry: registry,
        flutterExecutor: FlutterActionExecutor(
          handlers: {
            'app.get_env': (_) async => {
                  'mode': 'debug',
                },
          },
        ),
        jsBridgeExecutor: JsBridgeActionExecutor(
          gateway: MockJsBridgeGateway(),
        ),
      ),
    );

    final result = await runtime.invoke('app.get_env', {});

    expect(result.success, isTrue);
    expect(runtime.context.logStore.items, hasLength(1));
    expect(runtime.context.logStore.items.first.toolId, 'app.get_env');
  });

  test('invoke forwards progress callback', () async {
    final registry = ToolRegistry();
    const spec = ToolSpec(
      id: 'app.get_env',
      title: 'Get env',
      description: 'Returns env',
      executorType: ExecutorType.flutterAction,
      inputSchema: [],
    );
    registry.register(spec);

    final runtime = ToolRuntime(
      context: ToolRuntimeContext(
        registry: registry,
        flutterExecutor: FlutterActionExecutor(
          handlers: {
            'app.get_env': (_) async => {
                  'mode': 'debug',
                },
          },
        ),
        jsBridgeExecutor: JsBridgeActionExecutor(
          gateway: MockJsBridgeGateway(),
        ),
      ),
    );

    final progressEvents = <Object?>[];

    await runtime.invoke(
      'app.get_env',
      const {},
      onProgress: (_, payload) => progressEvents.add(payload),
    );

    expect(progressEvents, isNotEmpty);
  });
}
