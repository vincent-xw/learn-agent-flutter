import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/protocol/models/protocol_models.dart';
import 'package:learn_agent_flutter/core/protocol/parser/protocol_event_parser.dart';

void main() {
  final parser = ProtocolEventParser();

  test('parses tool.call.requested event', () {
    final event = parser.parse({
      'event_id': 'evt_001',
      'session_id': 'sess_001',
      'sequence': 1,
      'type': 'tool.call.requested',
      'timestamp': '2026-07-02T12:00:00Z',
      'payload': {
        'call_id': 'call_001',
        'tool_name': 'app.open_debug_page',
        'arguments': {'source': 'agent'},
        'idempotency_key': 'idem_001',
      },
    });

    expect(event.type, ProtocolEventType.toolCallRequested);
    expect(event.payload, isA<ToolCallPayload>());
  });

  test('throws when sequence is missing', () {
    expect(
      () => parser.parse({
        'event_id': 'evt_001',
        'session_id': 'sess_001',
        'type': 'tool.call.requested',
        'timestamp': '2026-07-02T12:00:00Z',
        'payload': {},
      }),
      throwsA(isA<ProtocolParseException>()),
    );
  });
}
