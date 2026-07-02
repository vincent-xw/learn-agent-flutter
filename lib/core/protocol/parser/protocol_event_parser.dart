import 'package:learn_agent_flutter/core/protocol/models/protocol_models.dart';

class ProtocolEventParser {
  ProtocolEvent parse(Map<String, Object?> raw) {
    final eventId = _readString(raw, 'event_id');
    final sessionId = _readString(raw, 'session_id');
    final sequence = _readInt(raw, 'sequence');
    final type = ProtocolEventType.fromValue(_readString(raw, 'type'));
    final timestamp = DateTime.parse(_readString(raw, 'timestamp'));
    final payload = _parsePayload(type, _readMap(raw, 'payload'));

    return ProtocolEvent(
      eventId: eventId,
      sessionId: sessionId,
      sequence: sequence,
      type: type,
      timestamp: timestamp,
      payload: payload,
    );
  }

  ProtocolPayload _parsePayload(
    ProtocolEventType type,
    Map<String, Object?> payload,
  ) {
    switch (type) {
      case ProtocolEventType.assistantMessage:
        return AssistantMessagePayload(
          messageId: _readString(payload, 'message_id'),
          role: _readString(payload, 'role'),
          content: _readString(payload, 'content'),
        );
      case ProtocolEventType.toolCallRequested:
        return ToolCallPayload(
          callId: _readString(payload, 'call_id'),
          toolName: _readString(payload, 'tool_name'),
          arguments: _readMap(payload, 'arguments'),
          idempotencyKey: _readString(payload, 'idempotency_key'),
        );
      case ProtocolEventType.toolCallStarted:
      case ProtocolEventType.toolCallProgress:
      case ProtocolEventType.toolCallCompleted:
      case ProtocolEventType.toolCallFailed:
        return ToolResultPayload(
          callId: _readString(payload, 'call_id'),
          status: _readString(payload, 'status'),
          output: payload['output'],
          error: _readOptionalError(payload['error']),
        );
    }
  }

  ProtocolErrorPayload? _readOptionalError(Object? rawError) {
    if (rawError == null) {
      return null;
    }
    if (rawError is! Map) {
      throw const ProtocolParseException('invalid error field');
    }
    final error = rawError.cast<String, Object?>();
    return ProtocolErrorPayload(
      code: _readString(error, 'code'),
      message: _readString(error, 'message'),
      retryable: _readBool(error, 'retryable'),
      details: _readOptionalMap(error, 'details'),
    );
  }

  String _readString(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw ProtocolParseException('invalid string field: $key');
  }

  int _readInt(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value is int) {
      return value;
    }
    throw ProtocolParseException('invalid int field: $key');
  }

  bool _readBool(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value is bool) {
      return value;
    }
    throw ProtocolParseException('invalid bool field: $key');
  }

  Map<String, Object?> _readMap(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    throw ProtocolParseException('invalid map field: $key');
  }

  Map<String, Object?> _readOptionalMap(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value == null) {
      return const {};
    }
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    throw ProtocolParseException('invalid map field: $key');
  }
}
