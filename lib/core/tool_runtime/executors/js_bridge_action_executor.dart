import 'package:learn_agent_flutter/core/bridge/bridge_gateway.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/tool_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

class JsBridgeActionExecutor implements ToolExecutor {
  JsBridgeActionExecutor({
    required this.gateway,
  });

  final BridgeGateway gateway;

  @override
  Future<ToolResult> execute(
    ToolSpec spec,
    Map<String, Object?> input,
  ) async {
    final method = spec.config['bridgeMethod'] as String?;
    if (method == null || method.isEmpty) {
      return const ToolResult(
        success: false,
        data: null,
        errorMessage: 'bridgeMethod is missing',
        durationMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();
    final bridgeResult = await gateway.call(method, input);
    stopwatch.stop();

    return ToolResult(
      success: bridgeResult.success,
      data: bridgeResult.data,
      errorMessage: bridgeResult.errorMessage,
      durationMs: stopwatch.elapsedMilliseconds,
      debugMeta: bridgeResult.debugMeta,
    );
  }
}
