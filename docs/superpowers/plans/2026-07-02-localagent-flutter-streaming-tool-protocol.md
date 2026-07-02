# localAgent 与 Flutter 流式 Tool 协议 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `learn-agent-flutter` 中落地一套可测试的 `localAgent -> Flutter` 流式 tool 协议核心，实现单会话单任务、事件信封解析、状态推进、tool 执行映射与事件回传。

**Architecture:** 协议实现新增一组独立的 `core/protocol` 边界，避免把协议对象直接混入现有 `tool_runtime` 模型。`SessionOrchestrator` 负责协议状态机，`ProtocolEventParser` 负责信封与载荷校验，`ProtocolEventEmitter` 负责把 runtime 生命周期转换为协议事件；现有 `ToolRuntime` 只做最小扩展以支持可选进度回调。

**Tech Stack:** Flutter, Dart, `flutter_test`, 现有 `ToolRuntime` / `ToolRegistry` / `ToolInputValidator`

---

## 文件结构

本计划将新增或修改以下文件，并固定职责边界：

- `lib/core/protocol/models/protocol_models.dart`
  - 协议事件信封、事件类型、assistant message、tool call、tool result、protocol error。
- `lib/core/protocol/parser/protocol_event_parser.dart`
  - 将原始 JSON 风格对象解析为协议模型，并做第一层字段校验。
- `lib/core/protocol/session/session_state.dart`
  - 单会话单任务状态对象与活跃调用跟踪。
- `lib/core/protocol/session/session_orchestrator.dart`
  - 维护协议时序、拒绝非法状态、调度 `ToolRuntime` 执行。
- `lib/core/protocol/emitter/protocol_event_emitter.dart`
  - 负责生成 `started / progress / completed / failed` 协议事件。
- `lib/core/tool_runtime/executors/tool_executor.dart`
  - 为执行器扩展可选进度回调参数。
- `lib/core/tool_runtime/executors/flutter_action_executor.dart`
  - 透传进度回调。
- `lib/core/tool_runtime/executors/js_bridge_action_executor.dart`
  - 透传进度回调。
- `lib/core/tool_runtime/runtime/tool_runtime.dart`
  - 为 `invoke` 增加可选 `onProgress` 支持。
- `lib/features/demo_tools/flutter_tools.dart`
  - 给至少一个本地 tool 增加进度事件样例。
- `lib/features/tool_console/tool_console_controller.dart`
  - 提供一个最小协议演示入口，能构造请求并查看返回事件。
- `test/core/protocol/protocol_event_parser_test.dart`
  - 协议事件解析测试。
- `test/core/protocol/session_orchestrator_test.dart`
  - 单会话单任务状态机测试。
- `test/core/protocol/protocol_event_emitter_test.dart`
  - 事件发射测试。
- `test/core/tool_runtime/tool_runtime_test.dart`
  - runtime 进度回调测试。
- `test/features/tool_console/tool_console_page_test.dart`
  - 调试台最小协议入口 smoke test。

## 实施原则

- 先测试，后实现。
- 每个任务只完成一个明确的协议子能力。
- 第一版严格保持单会话单任务；不要在实现阶段偷偷带入并发队列或多会话缓存。
- `tool.call.progress` 必须被协议核心支持，但不要求所有 tool 都实际产生进度事件。

### Task 1: 建立协议模型与解析器

**Files:**
- Create: `lib/core/protocol/models/protocol_models.dart`
- Create: `lib/core/protocol/parser/protocol_event_parser.dart`
- Test: `test/core/protocol/protocol_event_parser_test.dart`

- [ ] **Step 1: 先写协议解析失败与成功测试**

```dart
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
```

- [ ] **Step 2: 运行测试，确认当前失败**

Run: `rtk flutter test test/core/protocol/protocol_event_parser_test.dart`
Expected: FAIL，提示 `Target of URI doesn't exist` 或 `ProtocolEventParser` 未定义。

- [ ] **Step 3: 写最小协议模型**

`lib/core/protocol/models/protocol_models.dart`

```dart
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
    return ProtocolEventType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => throw ProtocolParseException('unknown event type: $value'),
    );
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
}
```

- [ ] **Step 4: 写最小解析器实现**

`lib/core/protocol/parser/protocol_event_parser.dart`

```dart
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
          error: payload['error'] is Map<String, Object?>
              ? ProtocolErrorPayload(
                  code: _readString(payload['error'] as Map<String, Object?>, 'code'),
                  message: _readString(payload['error'] as Map<String, Object?>, 'message'),
                  retryable: (payload['error'] as Map<String, Object?>)['retryable'] == true,
                  details: ((payload['error'] as Map<String, Object?>)['details'] as Map?)?.cast<String, Object?>() ?? const {},
                )
              : null,
        );
    }
  }

  String _readString(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value is String && value.isNotEmpty) return value;
    throw ProtocolParseException('invalid string field: $key');
  }

  int _readInt(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value is int) return value;
    throw ProtocolParseException('invalid int field: $key');
  }

  Map<String, Object?> _readMap(Map<String, Object?> raw, String key) {
    final value = raw[key];
    if (value is Map<String, Object?>) return value;
    if (value is Map) return value.cast<String, Object?>();
    throw ProtocolParseException('invalid map field: $key');
  }
}
```

- [ ] **Step 5: 运行测试，确认解析器通过**

Run: `rtk flutter test test/core/protocol/protocol_event_parser_test.dart`
Expected: PASS

- [ ] **Step 6: 提交本任务**

```bash
git add lib/core/protocol/models/protocol_models.dart lib/core/protocol/parser/protocol_event_parser.dart test/core/protocol/protocol_event_parser_test.dart
git commit -m "feat: add protocol event models and parser"
```

### Task 2: 建立单会话单任务状态机

**Files:**
- Create: `lib/core/protocol/session/session_state.dart`
- Create: `lib/core/protocol/session/session_orchestrator.dart`
- Test: `test/core/protocol/session_orchestrator_test.dart`

- [ ] **Step 1: 先写状态机测试，固定合法与非法时序**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/protocol/models/protocol_models.dart';
import 'package:learn_agent_flutter/core/protocol/session/session_orchestrator.dart';

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
```

- [ ] **Step 2: 运行测试，确认当前失败**

Run: `rtk flutter test test/core/protocol/session_orchestrator_test.dart`
Expected: FAIL，提示 `SessionOrchestrator` 未定义。

- [ ] **Step 3: 写最小会话状态对象**

`lib/core/protocol/session/session_state.dart`

```dart
class SessionState {
  const SessionState({
    required this.sessionId,
    this.activeCallId,
    this.lastSequence = 0,
  });

  final String sessionId;
  final String? activeCallId;
  final int lastSequence;

  bool get hasActiveCall => activeCallId != null;

  SessionState copyWith({
    String? activeCallId,
    int? lastSequence,
    bool clearActiveCall = false,
  }) {
    return SessionState(
      sessionId: sessionId,
      activeCallId: clearActiveCall ? null : (activeCallId ?? this.activeCallId),
      lastSequence: lastSequence ?? this.lastSequence,
    );
  }
}

class SessionStateException implements Exception {
  const SessionStateException(this.message);
  final String message;
}
```

- [ ] **Step 4: 写最小 orchestrator，实现单会话单任务推进**

`lib/core/protocol/session/session_orchestrator.dart`

```dart
import 'package:learn_agent_flutter/core/protocol/emitter/protocol_event_emitter.dart';
import 'package:learn_agent_flutter/core/protocol/models/protocol_models.dart';
import 'package:learn_agent_flutter/core/protocol/session/session_state.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime.dart';

class SessionOrchestrator {
  SessionOrchestrator({
    required this.runtime,
    required this.emitter,
    SessionState? state,
  }) : state = state ?? const SessionState(sessionId: '');

  final ToolRuntime runtime;
  final ProtocolEventEmitter emitter;
  SessionState state;

  factory SessionOrchestrator.fakeActiveCall({
    required String sessionId,
    required String callId,
  }) {
    return SessionOrchestrator(
      runtime: _FakeRuntime.success(),
      emitter: ProtocolEventEmitter(),
      state: SessionState(sessionId: sessionId, activeCallId: callId),
    );
  }

  factory SessionOrchestrator.withFakeRuntimeSuccess() {
    return SessionOrchestrator(
      runtime: _FakeRuntime.success(),
      emitter: ProtocolEventEmitter(),
      state: const SessionState(sessionId: 'sess_001'),
    );
  }

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
      emitter.started(sessionId: sessionId, sequence: sequenceStart, callId: payload.callId),
    ];

    final result = await runtime.invoke(
      payload.toolName,
      payload.arguments,
    );

    events.add(
      result.success
          ? emitter.completed(
              sessionId: sessionId,
              sequence: sequenceStart + 1,
              callId: payload.callId,
              output: result.data,
            )
          : emitter.failed(
              sessionId: sessionId,
              sequence: sequenceStart + 1,
              callId: payload.callId,
              code: 'execution_failed',
              message: result.errorMessage ?? 'unknown error',
            ),
    );

    state = state.copyWith(lastSequence: sequenceStart + 1, clearActiveCall: true);
    return events;
  }
}

class _FakeRuntime extends ToolRuntime {
  _FakeRuntime._() : super(context: throw UnimplementedError());

  factory _FakeRuntime.success() => _FakeRuntime._();

  @override
  Future<ToolResult> invoke(String toolId, Map<String, Object?> input, {void Function(String, Object?)? onProgress}) async {
    return const ToolResult(
      success: true,
      data: {'ok': true},
      errorMessage: null,
      durationMs: 1,
    );
  }
}
```

- [ ] **Step 5: 运行状态机测试，确认通过**

Run: `rtk flutter test test/core/protocol/session_orchestrator_test.dart`
Expected: PASS

- [ ] **Step 6: 提交本任务**

```bash
git add lib/core/protocol/session/session_state.dart lib/core/protocol/session/session_orchestrator.dart test/core/protocol/session_orchestrator_test.dart
git commit -m "feat: add single-session protocol orchestrator"
```

### Task 3: 建立事件发射器并给 runtime 增加进度回调

**Files:**
- Create: `lib/core/protocol/emitter/protocol_event_emitter.dart`
- Modify: `lib/core/tool_runtime/executors/tool_executor.dart`
- Modify: `lib/core/tool_runtime/executors/flutter_action_executor.dart`
- Modify: `lib/core/tool_runtime/executors/js_bridge_action_executor.dart`
- Modify: `lib/core/tool_runtime/runtime/tool_runtime.dart`
- Test: `test/core/protocol/protocol_event_emitter_test.dart`
- Test: `test/core/tool_runtime/tool_runtime_test.dart`

- [ ] **Step 1: 先写 emitter 测试和 runtime 进度测试**

```dart
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
```

```dart
test('invoke forwards progress callback', () async {
  final progressEvents = <Object?>[];

  await runtime.invoke(
    'bridge.trace_event',
    {'name': 'demo'},
    onProgress: (_, payload) => progressEvents.add(payload),
  );

  expect(progressEvents, isNotEmpty);
});
```

- [ ] **Step 2: 运行测试，确认当前失败**

Run: `rtk flutter test test/core/protocol/protocol_event_emitter_test.dart test/core/tool_runtime/tool_runtime_test.dart`
Expected: FAIL，提示 emitter 未定义或 `invoke` 参数不匹配。

- [ ] **Step 3: 写最小 emitter**

`lib/core/protocol/emitter/protocol_event_emitter.dart`

```dart
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
```

- [ ] **Step 4: 扩展 runtime 与执行器的进度回调**

`lib/core/tool_runtime/executors/tool_executor.dart`

```dart
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

abstract class ToolExecutor {
  Future<ToolResult> execute(
    ToolSpec spec,
    Map<String, Object?> input, {
    void Function(String stage, Object? payload)? onProgress,
  });
}
```

`lib/core/tool_runtime/runtime/tool_runtime.dart`

```dart
Future<ToolResult> invoke(
  String toolId,
  Map<String, Object?> input, {
  void Function(String stage, Object? payload)? onProgress,
}) async {
  // existing lookup and validation
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
}
```

`lib/core/tool_runtime/executors/flutter_action_executor.dart`

```dart
@override
Future<ToolResult> execute(
  ToolSpec spec,
  Map<String, Object?> input, {
  void Function(String stage, Object? payload)? onProgress,
}) async {
  onProgress?.call('started', {'toolId': spec.id});
  final handler = handlers[spec.id];
  if (handler == null) {
    return const ToolResult(
      success: false,
      data: null,
      errorMessage: 'handler not found',
      durationMs: 0,
    );
  }
  final result = await handler(input);
  onProgress?.call('completed', result.data);
  return result;
}
```

`lib/core/tool_runtime/executors/js_bridge_action_executor.dart`

```dart
@override
Future<ToolResult> execute(
  ToolSpec spec,
  Map<String, Object?> input, {
  void Function(String stage, Object? payload)? onProgress,
}) async {
  onProgress?.call('bridge.requested', {'toolId': spec.id});
  final response = await gateway.invoke(spec.id, input);
  onProgress?.call('bridge.completed', response);
  return ToolResult(
    success: true,
    data: response,
    errorMessage: null,
    durationMs: 1,
  );
}
```

- [ ] **Step 5: 跑测试确认 emitter 与 runtime 进度链路通过**

Run: `rtk flutter test test/core/protocol/protocol_event_emitter_test.dart test/core/tool_runtime/tool_runtime_test.dart`
Expected: PASS

- [ ] **Step 6: 提交本任务**

```bash
git add lib/core/protocol/emitter/protocol_event_emitter.dart lib/core/tool_runtime/executors/tool_executor.dart lib/core/tool_runtime/executors/flutter_action_executor.dart lib/core/tool_runtime/executors/js_bridge_action_executor.dart lib/core/tool_runtime/runtime/tool_runtime.dart test/core/protocol/protocol_event_emitter_test.dart test/core/tool_runtime/tool_runtime_test.dart
git commit -m "feat: add protocol emitter and runtime progress hooks"
```

### Task 4: 挂接最小协议演示入口

**Files:**
- Modify: `lib/features/demo_tools/flutter_tools.dart`
- Modify: `lib/features/tool_console/tool_console_controller.dart`
- Test: `test/features/tool_console/tool_console_page_test.dart`

- [ ] **Step 1: 先写 UI smoke test，固定最小协议入口文案**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/app/app.dart';

void main() {
  testWidgets('tool console renders protocol demo entry', (tester) async {
    await tester.pumpWidget(const AgentToolApp());
    await tester.pumpAndSettle();

    expect(find.text('Protocol Demo'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试，确认当前失败**

Run: `rtk flutter test test/features/tool_console/tool_console_page_test.dart`
Expected: FAIL，提示 `Protocol Demo` 未找到。

- [ ] **Step 3: 在一个 demo tool 上增加进度样例，并让 controller 能构造协议演示结果**

`lib/features/demo_tools/flutter_tools.dart`

```dart
ToolSpec(
  id: 'app.get_env',
  title: 'Get App Environment',
  description: 'Returns local app environment and build metadata.',
  executorType: ExecutorType.flutterAction,
  inputSchema: const [],
  config: const {'protocolDemoEnabled': true},
)
```

`lib/features/tool_console/tool_console_controller.dart`

```dart
Future<void> runProtocolDemo() async {
  protocolDemoEvents = [];
  notifyListeners();

  final payload = const ToolCallPayload(
    callId: 'call_demo_001',
    toolName: 'app.get_env',
    arguments: {},
    idempotencyKey: 'idem_demo_001',
  );

  final orchestrator = SessionOrchestrator(
    runtime: runtime,
    emitter: ProtocolEventEmitter(),
  );

  protocolDemoEvents = await orchestrator.handleRequested(
    sessionId: 'sess_demo_001',
    sequenceStart: 1,
    payload: payload,
  );

  notifyListeners();
}
```

- [ ] **Step 4: 在调试台暴露最小按钮或结果区入口**

```dart
TextButton(
  onPressed: controller.runProtocolDemo,
  child: const Text('Protocol Demo'),
)
```

- [ ] **Step 5: 跑 UI 测试与全量测试**

Run: `rtk flutter test test/features/tool_console/tool_console_page_test.dart`
Expected: PASS

Run: `rtk flutter test`
Expected: PASS，全量测试通过。

Run: `rtk flutter analyze`
Expected: PASS，`No issues found!`

- [ ] **Step 6: 提交本任务**

```bash
git add lib/features/demo_tools/flutter_tools.dart lib/features/tool_console/tool_console_controller.dart test/features/tool_console/tool_console_page_test.dart
git commit -m "feat: add protocol demo entry to tool console"
```

## 自检结果

### Spec coverage

- 独立协议模型：由 Task 1 完成。
- 单会话单任务状态机：由 Task 2 完成。
- `started / progress / completed / failed` 事件回传：由 Task 3 完成。
- 与现有 Flutter runtime 的映射：由 Task 2 和 Task 3 完成。
- 最小调试入口：由 Task 4 完成。

### Placeholder scan

- 已检查，计划中没有 `TODO`、`TBD`、`implement later` 等占位词。
- 每个代码步骤都给了明确文件路径、示例代码和验证命令。

### Type consistency

- 协议核心统一使用 `ProtocolEvent`、`ToolCallPayload`、`ToolResultPayload`。
- 会话状态统一由 `SessionState` 持有 `activeCallId` 和 `lastSequence`。
- runtime 统一新增 `onProgress` 可选参数，执行器接口同步修改，避免后续签名漂移。
