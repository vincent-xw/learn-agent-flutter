import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime_context.dart';
import 'package:learn_agent_flutter/core/tool_runtime/validation/tool_input_validator.dart';

class ToolRuntime {
  ToolRuntime({
    required this.context,
    ToolInputValidator? validator,
  }) : validator = validator ?? ToolInputValidator();

  final ToolRuntimeContext context;
  final ToolInputValidator validator;

  Future<ToolResult> invoke(
    String toolId,
    Map<String, Object?> input, {
    void Function(String stage, Object? payload)? onProgress,
  }
  ) async {
    final spec = context.registry.findById(toolId);
    if (spec == null) {
      return const ToolResult(
        success: false,
        data: null,
        errorMessage: 'tool not found',
        durationMs: 0,
      );
    }

    final validationErrors = validator.validate(spec, input);
    if (validationErrors.isNotEmpty) {
      final result = ToolResult(
        success: false,
        data: {
          'errors': validationErrors,
        },
        errorMessage: validationErrors.join(', '),
        durationMs: 0,
      );
      context.logStore.add(
        ToolInvocationLog(
          toolId: toolId,
          status: InvocationStatus.failure,
          createdAt: DateTime.now(),
          durationMs: result.durationMs,
          inputSnapshot: input,
          outputSnapshot: result.data,
          errorMessage: result.errorMessage,
        ),
      );
      return result;
    }

    late final ToolResult result;
    switch (spec.executorType) {
      case ExecutorType.flutterAction:
        result = await context.flutterExecutor.execute(
          spec,
          input,
          onProgress: onProgress,
        );
        break;
      case ExecutorType.jsBridgeAction:
        result = await context.jsBridgeExecutor.execute(
          spec,
          input,
          onProgress: onProgress,
        );
        break;
    }

    context.logStore.add(
      ToolInvocationLog(
        toolId: toolId,
        status: result.success
            ? InvocationStatus.success
            : InvocationStatus.failure,
        createdAt: DateTime.now(),
        durationMs: result.durationMs,
        inputSnapshot: input,
        outputSnapshot: result.data,
        errorMessage: result.errorMessage,
      ),
    );

    return result;
  }
}
