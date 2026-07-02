import 'package:learn_agent_flutter/core/protocol/emitter/protocol_event_emitter.dart';
import 'package:learn_agent_flutter/core/protocol/models/protocol_models.dart';
import 'package:learn_agent_flutter/core/protocol/session/session_state.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime.dart';

class SessionOrchestrator {
  SessionOrchestrator({
    this.runtime,
    ProtocolEventEmitter? emitter,
    SessionState? state,
  })  : emitter = emitter ?? ProtocolEventEmitter(),
        runtimeInvoker = null,
        state = state ?? const SessionState(sessionId: '');

  SessionOrchestrator._({
    required this.runtimeInvoker,
    required this.state,
  })  : runtime = null,
        emitter = ProtocolEventEmitter();

  factory SessionOrchestrator.fakeActiveCall({
    required String sessionId,
    required String callId,
  }) {
    return SessionOrchestrator._(
      runtimeInvoker: (_, __) async => const ToolResult(
        success: true,
        data: {'ok': true},
        errorMessage: null,
        durationMs: 1,
      ),
      state: SessionState(sessionId: sessionId, activeCallId: callId),
    );
  }

  factory SessionOrchestrator.withFakeRuntimeSuccess() {
    return SessionOrchestrator._(
      runtimeInvoker: (_, __) async => const ToolResult(
        success: true,
        data: {'ok': true},
        errorMessage: null,
        durationMs: 1,
      ),
      state: const SessionState(sessionId: 'sess_001'),
    );
  }

  final ToolRuntime? runtime;
  final ProtocolEventEmitter emitter;
  final Future<ToolResult> Function(
    String toolName,
    Map<String, Object?> arguments,
  )? runtimeInvoker;
  SessionState state;

  void acceptRequested(ToolCallPayload payload) {
    if (state.hasActiveCall) {
      throw const SessionStateException('session already has active call');
    }
    state = state.copyWith(activeCallId: payload.callId);
  }

  Future<List<ProtocolEvent>> handleRequested({
    required String sessionId,
    required int sequenceStart,
    required ToolCallPayload payload,
  }) async {
    acceptRequested(payload);

    final events = <ProtocolEvent>[
      emitter.started(
        sessionId: sessionId,
        sequence: sequenceStart,
        callId: payload.callId,
      ),
    ];

    var nextSequence = sequenceStart + 1;
    final liveRuntime = runtime;
    final invoker = runtimeInvoker;
    late final ToolResult result;

    if (liveRuntime != null) {
      result = await liveRuntime.invoke(
        payload.toolName,
        payload.arguments,
        onProgress: (_, progressPayload) {
          events.add(
            emitter.progress(
              sessionId: sessionId,
              sequence: nextSequence++,
              callId: payload.callId,
              output: progressPayload,
            ),
          );
        },
      );
    } else if (invoker != null) {
      result = await invoker(payload.toolName, payload.arguments);
    } else {
      result = const ToolResult(
        success: false,
        data: null,
        errorMessage: 'runtime is not configured',
        durationMs: 0,
      );
    }

    events.add(
      result.success
          ? emitter.completed(
              sessionId: sessionId,
              sequence: nextSequence,
              callId: payload.callId,
              output: result.data,
            )
          : emitter.failed(
              sessionId: sessionId,
              sequence: nextSequence,
              callId: payload.callId,
              code: 'execution_failed',
              message: result.errorMessage ?? 'unknown error',
            ),
    );

    state = state.copyWith(
      lastSequence: nextSequence,
      clearActiveCall: true,
    );

    return events;
  }
}
