import 'package:learn_agent_flutter/core/protocol/models/protocol_models.dart';

class ProtocolEventEmitter {
  ProtocolEvent started({
    required String sessionId,
    required int sequence,
    required String callId,
  }) {
    return _buildResultEvent(
      sessionId: sessionId,
      sequence: sequence,
      type: ProtocolEventType.toolCallStarted,
      callId: callId,
      status: 'started',
      output: null,
      error: null,
    );
  }

  ProtocolEvent progress({
    required String sessionId,
    required int sequence,
    required String callId,
    required Object? output,
  }) {
    return _buildResultEvent(
      sessionId: sessionId,
      sequence: sequence,
      type: ProtocolEventType.toolCallProgress,
      callId: callId,
      status: 'running',
      output: output,
      error: null,
    );
  }

  ProtocolEvent completed({
    required String sessionId,
    required int sequence,
    required String callId,
    required Object? output,
  }) {
    return _buildResultEvent(
      sessionId: sessionId,
      sequence: sequence,
      type: ProtocolEventType.toolCallCompleted,
      callId: callId,
      status: 'success',
      output: output,
      error: null,
    );
  }

  ProtocolEvent failed({
    required String sessionId,
    required int sequence,
    required String callId,
    required String code,
    required String message,
  }) {
    return _buildResultEvent(
      sessionId: sessionId,
      sequence: sequence,
      type: ProtocolEventType.toolCallFailed,
      callId: callId,
      status: 'failed',
      output: null,
      error: ProtocolErrorPayload(
        code: code,
        message: message,
        retryable: false,
      ),
    );
  }

  ProtocolEvent _buildResultEvent({
    required String sessionId,
    required int sequence,
    required ProtocolEventType type,
    required String callId,
    required String status,
    required Object? output,
    required ProtocolErrorPayload? error,
  }) {
    return ProtocolEvent(
      eventId: '${type.value}-$sequence',
      sessionId: sessionId,
      sequence: sequence,
      type: type,
      timestamp: DateTime.now().toUtc(),
      payload: ToolResultPayload(
        callId: callId,
        status: status,
        output: output,
        error: error,
      ),
    );
  }
}
