import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

class ToolInputField {
  const ToolInputField({
    required this.name,
    required this.type,
    required this.isRequired,
    this.description = '',
    this.defaultValue,
  });

  final String name;
  final ToolFieldType type;
  final bool isRequired;
  final String description;
  final Object? defaultValue;
}

class ToolSpec {
  const ToolSpec({
    required this.id,
    required this.title,
    required this.description,
    required this.executorType,
    required this.inputSchema,
    this.tags = const [],
    this.config = const {},
  });

  final String id;
  final String title;
  final String description;
  final ExecutorType executorType;
  final List<ToolInputField> inputSchema;
  final List<String> tags;
  final Map<String, Object?> config;
}

class ToolInvocation {
  ToolInvocation({
    required this.invocationId,
    required this.toolId,
    required this.input,
    required this.createdAt,
    required this.status,
  });

  final String invocationId;
  final String toolId;
  final Map<String, Object?> input;
  final DateTime createdAt;
  final InvocationStatus status;
}

class ToolResult {
  const ToolResult({
    required this.success,
    required this.data,
    required this.errorMessage,
    required this.durationMs,
    this.debugMeta = const {},
  });

  final bool success;
  final Object? data;
  final String? errorMessage;
  final int durationMs;
  final Map<String, Object?> debugMeta;
}

class ToolInvocationLog {
  ToolInvocationLog({
    required this.toolId,
    required this.status,
    required this.createdAt,
    required this.durationMs,
    required this.inputSnapshot,
    required this.outputSnapshot,
    this.errorMessage,
  });

  final String toolId;
  final InvocationStatus status;
  final DateTime createdAt;
  final int durationMs;
  final Map<String, Object?> inputSnapshot;
  final Object? outputSnapshot;
  final String? errorMessage;
}
