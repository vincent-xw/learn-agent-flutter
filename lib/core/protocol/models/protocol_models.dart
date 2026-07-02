enum ProtocolEventType {
  assistantMessage('assistant.message'),
  toolCallRequested('tool.call.requested'),
  toolCallStarted('tool.call.started'),
  toolCallProgress('tool.call.progress'),
  toolCallCompleted('tool.call.completed'),
  toolCallFailed('tool.call.failed');

  const ProtocolEventType(this.value);

  final String value;

  static ProtocolEventType fromValue(String value) {
    for (final item in ProtocolEventType.values) {
      if (item.value == value) {
        return item;
      }
    }
    throw ProtocolParseException('unknown event type: $value');
  }
}

sealed class ProtocolPayload {
  const ProtocolPayload();
}

class AssistantMessagePayload extends ProtocolPayload {
  const AssistantMessagePayload({
    required this.messageId,
    required this.role,
    required this.content,
  });

  final String messageId;
  final String role;
  final String content;
}

class ToolCallPayload extends ProtocolPayload {
  const ToolCallPayload({
    required this.callId,
    required this.toolName,
    required this.arguments,
    required this.idempotencyKey,
  });

  final String callId;
  final String toolName;
  final Map<String, Object?> arguments;
  final String idempotencyKey;
}

class ProtocolErrorPayload {
  const ProtocolErrorPayload({
    required this.code,
    required this.message,
    required this.retryable,
    this.details = const {},
  });

  final String code;
  final String message;
  final bool retryable;
  final Map<String, Object?> details;
}

class ToolResultPayload extends ProtocolPayload {
  const ToolResultPayload({
    required this.callId,
    required this.status,
    required this.output,
    required this.error,
  });

  final String callId;
  final String status;
  final Object? output;
  final ProtocolErrorPayload? error;
}

class ProtocolEvent {
  const ProtocolEvent({
    required this.eventId,
    required this.sessionId,
    required this.sequence,
    required this.type,
    required this.timestamp,
    required this.payload,
  });

  final String eventId;
  final String sessionId;
  final int sequence;
  final ProtocolEventType type;
  final DateTime timestamp;
  final ProtocolPayload payload;
}

class ProtocolParseException implements Exception {
  const ProtocolParseException(this.message);

  final String message;

  @override
  String toString() => 'ProtocolParseException: $message';
}
