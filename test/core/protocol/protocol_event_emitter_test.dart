import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/protocol/emitter/protocol_event_emitter.dart';
import 'package:learn_agent_flutter/core/protocol/models/protocol_models.dart';

void main() {
  final emitter = ProtocolEventEmitter();

  test('builds progress event with output payload', () {
    final event = emitter.progress(
      sessionId: 'sess_001',
      sequence: 5,
      callId: 'call_001',
      output: {'stage': 'validating'},
    );

    expect(event.type, ProtocolEventType.toolCallProgress);
    expect((event.payload as ToolResultPayload).output, {'stage': 'validating'});
  });
}
