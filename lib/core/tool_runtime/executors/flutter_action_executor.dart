import 'package:learn_agent_flutter/core/tool_runtime/executors/tool_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

typedef FlutterActionHandler = Future<Object?> Function(
  Map<String, Object?> input,
);

class FlutterActionExecutor implements ToolExecutor {
  FlutterActionExecutor({
    required this.handlers,
  });

  final Map<String, FlutterActionHandler> handlers;

  @override
  Future<ToolResult> execute(
    ToolSpec spec,
    Map<String, Object?> input,
  ) async {
    final handler = handlers[spec.id];
    if (handler == null) {
      return const ToolResult(
        success: false,
        data: null,
        errorMessage: 'flutter action handler not found',
        durationMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final data = await handler(input);
      stopwatch.stop();
      return ToolResult(
        success: true,
        data: data,
        errorMessage: null,
        durationMs: stopwatch.elapsedMilliseconds,
        debugMeta: const {
          'executor': 'flutter_action',
        },
      );
    } catch (error) {
      stopwatch.stop();
      return ToolResult(
        success: false,
        data: null,
        errorMessage: error.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
        debugMeta: const {
          'executor': 'flutter_action',
        },
      );
    }
  }
}
