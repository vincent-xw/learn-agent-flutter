import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/protocol/models/protocol_models.dart';
import 'package:learn_agent_flutter/core/protocol/session/session_orchestrator.dart';
import 'package:learn_agent_flutter/core/protocol/session/session_state.dart';

void main() {
  test('rejects second requested event when call is active', () async {
    final orchestrator = SessionOrchestrator.fakeActiveCall(
      sessionId: 'sess_001',
      callId: 'call_001',
    );

    expect(
      () => orchestrator.acceptRequested(
        const ToolCallPayload(
          callId: 'call_002',
          toolName: 'app.get_env',
          arguments: {},
          idempotencyKey: 'idem_002',
        ),
      ),
      throwsA(isA<SessionStateException>()),
    );
  });

  test('completes requested call through runtime', () async {
    final orchestrator = SessionOrchestrator.withFakeRuntimeSuccess();

    final events = await orchestrator.handleRequested(
      sessionId: 'sess_001',
      sequenceStart: 3,
      payload: const ToolCallPayload(
        callId: 'call_001',
        toolName: 'app.get_env',
        arguments: {},
        idempotencyKey: 'idem_001',
      ),
    );

    expect(events.map((item) => item.type).toList(), [
      ProtocolEventType.toolCallStarted,
      ProtocolEventType.toolCallCompleted,
    ]);
  });
}
