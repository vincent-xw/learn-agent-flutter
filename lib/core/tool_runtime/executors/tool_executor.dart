import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

abstract class ToolExecutor {
  Future<ToolResult> execute(
    ToolSpec spec,
    Map<String, Object?> input, {
    void Function(String stage, Object? payload)? onProgress,
  }
  );
}
