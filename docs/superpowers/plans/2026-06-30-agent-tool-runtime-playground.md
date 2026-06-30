# Agent Tool Runtime Playground Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个基于 Flutter 的学习型 tool runtime playground，支持 `flutter_action` 与 `js_bridge_action` 两类工具执行、调试台、调用日志和基础测试。

**Architecture:** 项目采用单 app 结构，按 `app / core / features / shared` 分层。runtime 核心能力放在纯 Dart 友好的 `core` 下，UI 只负责展示与交互；bridge 先使用 mock 实现，为后续迁移到企业 WebView/JsBridge 容器预留接口。

**Tech Stack:** Flutter, Dart, Material 3, `shared_preferences`, `flutter_test`

---

## 文件结构

本计划会创建以下主要文件，并将职责边界固定下来：

- `pubspec.yaml`
  - Flutter 项目依赖、环境约束、测试依赖。
- `analysis_options.yaml`
  - 分析器基础配置。
- `lib/main.dart`
  - 应用入口。
- `lib/app/app.dart`
  - 顶层 `MaterialApp`、路由注册。
- `lib/app/routes.dart`
  - 路由常量与页面路由表。
- `lib/core/tool_runtime/models/tool_models.dart`
  - `ToolSpec`、`ToolInvocation`、`ToolResult`、schema 字段模型。
- `lib/core/tool_runtime/models/tool_types.dart`
  - runtime 用到的枚举和类型别名。
- `lib/core/tool_runtime/validation/tool_input_validator.dart`
  - 输入 schema 校验器。
- `lib/core/tool_runtime/registry/tool_registry.dart`
  - tool 注册和查询。
- `lib/core/tool_runtime/executors/tool_executor.dart`
  - 执行器接口。
- `lib/core/tool_runtime/executors/flutter_action_executor.dart`
  - Flutter 本地执行器。
- `lib/core/tool_runtime/executors/js_bridge_action_executor.dart`
  - bridge 执行器。
- `lib/core/tool_runtime/runtime/tool_runtime.dart`
  - 调用协调器，串起校验、分发、日志。
- `lib/core/tool_runtime/runtime/tool_runtime_context.dart`
  - runtime 上下文，注入 registry、executors、log store。
- `lib/core/tool_runtime/logs/tool_invocation_log_store.dart`
  - 调用日志存储。
- `lib/core/bridge/bridge_gateway.dart`
  - bridge 抽象。
- `lib/core/bridge/mock_js_bridge_gateway.dart`
  - mock bridge 实现。
- `lib/features/demo_tools/demo_tools.dart`
  - 首批 demo tools 统一注册入口。
- `lib/features/demo_tools/flutter_tools.dart`
  - `flutter_action` demo tools。
- `lib/features/demo_tools/bridge_tools.dart`
  - `js_bridge_action` demo tools。
- `lib/features/tool_console/tool_console_controller.dart`
  - 调试台页面状态。
- `lib/features/tool_console/tool_console_page.dart`
  - 调试台主页面。
- `lib/features/tool_console/widgets/tool_list_pane.dart`
  - tool 列表区域。
- `lib/features/tool_console/widgets/tool_inspector_pane.dart`
  - tool 描述与参数输入区域。
- `lib/features/tool_console/widgets/tool_result_pane.dart`
  - 执行结果区域。
- `lib/features/logs/invocation_logs_page.dart`
  - 调用日志页面。
- `lib/features/debug/debug_page.dart`
  - `app.open_debug_page` 的落点页面。
- `lib/shared/widgets/json_pretty_view.dart`
  - JSON 结果展示组件。
- `test/core/tool_runtime/tool_input_validator_test.dart`
  - schema 校验单测。
- `test/core/tool_runtime/tool_registry_test.dart`
  - registry 单测。
- `test/core/tool_runtime/flutter_action_executor_test.dart`
  - `flutter_action` 执行单测。
- `test/core/tool_runtime/js_bridge_action_executor_test.dart`
  - `js_bridge_action` 执行单测。
- `test/features/tool_console/tool_console_page_test.dart`
  - 调试台 smoke test。

### Task 1: 初始化 Flutter 项目骨架

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `lib/main.dart`
- Create: `lib/app/app.dart`
- Create: `lib/app/routes.dart`
- Create: `lib/features/debug/debug_page.dart`
- Test: `test/smoke_test.dart`

- [ ] **Step 1: 写初始化 smoke test，先定义期望首页可渲染**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/app/app.dart';

void main() {
  testWidgets('app boots into tool console shell', (tester) async {
    await tester.pumpWidget(const AgentToolApp());

    expect(find.text('Agent Tool Runtime Playground'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试，确认当前失败**

Run: `flutter test test/smoke_test.dart -r expanded`
Expected: FAIL，提示 `Target of URI doesn't exist` 或 `AgentToolApp` 未定义。

- [ ] **Step 3: 写最小 Flutter 项目骨架**

`pubspec.yaml`

```yaml
name: learn_agent_flutter
description: Agent tool runtime playground built with Flutter.
publish_to: "none"

environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  shared_preferences: ^2.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

`analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml
```

`lib/main.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:learn_agent_flutter/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgentToolApp());
}
```

`lib/app/routes.dart`

```dart
class AppRoutes {
  static const String home = '/';
  static const String logs = '/logs';
  static const String debug = '/debug';
}
```

`lib/features/debug/debug_page.dart`

```dart
import 'package:flutter/material.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Debug Page'),
      ),
    );
  }
}
```

`lib/app/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/app/routes.dart';
import 'package:learn_agent_flutter/features/debug/debug_page.dart';

class AgentToolApp extends StatelessWidget {
  const AgentToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent Tool Runtime Playground',
      routes: {
        AppRoutes.home: (_) => const _AppShell(),
        AppRoutes.debug: (_) => const DebugPage(),
      },
      initialRoute: AppRoutes.home,
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Agent Tool Runtime Playground'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Tools'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 再次运行 smoke test，确认通过**

Run: `flutter test test/smoke_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: 提交本任务**

```bash
git add pubspec.yaml analysis_options.yaml lib/main.dart lib/app/app.dart lib/app/routes.dart lib/features/debug/debug_page.dart test/smoke_test.dart
git commit -m "feat: initialize flutter app shell"
```

### Task 2: 建立 runtime 模型与 schema 校验

**Files:**
- Create: `lib/core/tool_runtime/models/tool_types.dart`
- Create: `lib/core/tool_runtime/models/tool_models.dart`
- Create: `lib/core/tool_runtime/validation/tool_input_validator.dart`
- Test: `test/core/tool_runtime/tool_input_validator_test.dart`

- [ ] **Step 1: 先写 schema 校验测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';
import 'package:learn_agent_flutter/core/tool_runtime/validation/tool_input_validator.dart';

void main() {
  final validator = ToolInputValidator();

  test('returns no errors for valid input', () {
    final spec = ToolSpec(
      id: 'storage.set_value',
      title: 'Set value',
      description: 'Stores key value pair',
      executorType: ExecutorType.flutterAction,
      inputSchema: const [
        ToolInputField(name: 'key', type: ToolFieldType.string, required: true),
        ToolInputField(name: 'value', type: ToolFieldType.string, required: true),
      ],
    );

    final errors = validator.validate(spec, {
      'key': 'token',
      'value': '123',
    });

    expect(errors, isEmpty);
  });

  test('returns error when required field missing', () {
    final spec = ToolSpec(
      id: 'bridge.trace_event',
      title: 'Trace event',
      description: 'Sends trace event',
      executorType: ExecutorType.jsBridgeAction,
      inputSchema: const [
        ToolInputField(name: 'event', type: ToolFieldType.string, required: true),
      ],
    );

    final errors = validator.validate(spec, {});

    expect(errors, ['event is required']);
  });

  test('returns error when field type mismatches', () {
    final spec = ToolSpec(
      id: 'app.get_env',
      title: 'Get env',
      description: 'Returns environment',
      executorType: ExecutorType.flutterAction,
      inputSchema: const [
        ToolInputField(name: 'includePlatform', type: ToolFieldType.boolean, required: true),
      ],
    );

    final errors = validator.validate(spec, {
      'includePlatform': 'true',
    });

    expect(errors, ['includePlatform must be a boolean']);
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `flutter test test/core/tool_runtime/tool_input_validator_test.dart -r expanded`
Expected: FAIL，提示相关 runtime model 或 validator 文件不存在。

- [ ] **Step 3: 实现模型与校验器**

`lib/core/tool_runtime/models/tool_types.dart`

```dart
enum ExecutorType {
  flutterAction,
  jsBridgeAction,
}

enum ToolFieldType {
  string,
  number,
  boolean,
  json,
}

enum InvocationStatus {
  idle,
  running,
  success,
  failure,
}
```

`lib/core/tool_runtime/models/tool_models.dart`

```dart
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

class ToolInputField {
  const ToolInputField({
    required this.name,
    required this.type,
    required this.required,
    this.description = '',
    this.defaultValue,
  });

  final String name;
  final ToolFieldType type;
  final bool required;
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
```

`lib/core/tool_runtime/validation/tool_input_validator.dart`

```dart
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

class ToolInputValidator {
  List<String> validate(ToolSpec spec, Map<String, Object?> input) {
    final errors = <String>[];

    for (final field in spec.inputSchema) {
      final value = input[field.name];

      if (field.required && value == null) {
        errors.add('${field.name} is required');
        continue;
      }

      if (value == null) {
        continue;
      }

      switch (field.type) {
        case ToolFieldType.string:
          if (value is! String) errors.add('${field.name} must be a string');
        case ToolFieldType.number:
          if (value is! num) errors.add('${field.name} must be a number');
        case ToolFieldType.boolean:
          if (value is! bool) errors.add('${field.name} must be a boolean');
        case ToolFieldType.json:
          if (value is! Map<String, Object?> && value is! List<Object?>) {
            errors.add('${field.name} must be json compatible');
          }
      }
    }

    return errors;
  }
}
```

- [ ] **Step 4: 再次运行测试，确认通过**

Run: `flutter test test/core/tool_runtime/tool_input_validator_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: 提交本任务**

```bash
git add lib/core/tool_runtime/models/tool_types.dart lib/core/tool_runtime/models/tool_models.dart lib/core/tool_runtime/validation/tool_input_validator.dart test/core/tool_runtime/tool_input_validator_test.dart
git commit -m "feat: add tool models and input validator"
```

### Task 3: 建立 registry、bridge 抽象与两类 executor

**Files:**
- Create: `lib/core/tool_runtime/registry/tool_registry.dart`
- Create: `lib/core/tool_runtime/executors/tool_executor.dart`
- Create: `lib/core/tool_runtime/executors/flutter_action_executor.dart`
- Create: `lib/core/tool_runtime/executors/js_bridge_action_executor.dart`
- Create: `lib/core/bridge/bridge_gateway.dart`
- Create: `lib/core/bridge/mock_js_bridge_gateway.dart`
- Test: `test/core/tool_runtime/tool_registry_test.dart`
- Test: `test/core/tool_runtime/flutter_action_executor_test.dart`
- Test: `test/core/tool_runtime/js_bridge_action_executor_test.dart`

- [ ] **Step 1: 先写 registry 与 executor 测试**

`test/core/tool_runtime/tool_registry_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';
import 'package:learn_agent_flutter/core/tool_runtime/registry/tool_registry.dart';

void main() {
  test('finds tool by id after registration', () {
    final registry = ToolRegistry();
    const tool = ToolSpec(
      id: 'app.get_env',
      title: 'Get env',
      description: 'Returns app env',
      executorType: ExecutorType.flutterAction,
      inputSchema: [],
    );

    registry.register(tool);

    expect(registry.findById('app.get_env'), same(tool));
  });
}
```

`test/core/tool_runtime/flutter_action_executor_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

void main() {
  test('executes registered flutter handler', () async {
    final executor = FlutterActionExecutor(
      handlers: {
        'app.get_env': (input) async => {'mode': 'debug', 'input': input},
      },
    );

    const spec = ToolSpec(
      id: 'app.get_env',
      title: 'Get env',
      description: 'Returns env',
      executorType: ExecutorType.flutterAction,
      inputSchema: [],
    );

    final result = await executor.execute(spec, {'includePlatform': true});

    expect(result.success, isTrue);
    expect(result.data, {
      'mode': 'debug',
      'input': {'includePlatform': true},
    });
  });
}
```

`test/core/tool_runtime/js_bridge_action_executor_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/bridge/mock_js_bridge_gateway.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/js_bridge_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

void main() {
  test('delegates bridge call to gateway', () async {
    final gateway = MockJsBridgeGateway();
    final executor = JsBridgeActionExecutor(gateway: gateway);

    const spec = ToolSpec(
      id: 'bridge.trace_event',
      title: 'Trace event',
      description: 'Bridge trace',
      executorType: ExecutorType.jsBridgeAction,
      inputSchema: [],
      config: {'bridgeMethod': 'trace_event'},
    );

    final result = await executor.execute(spec, {'event': 'home_click'});

    expect(result.success, isTrue);
    expect(result.debugMeta['bridgeMethod'], 'trace_event');
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `flutter test test/core/tool_runtime -r expanded`
Expected: FAIL，提示 registry、executor、gateway 文件不存在。

- [ ] **Step 3: 实现 registry、bridge、executors**

`lib/core/tool_runtime/registry/tool_registry.dart`

```dart
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

class ToolRegistry {
  final Map<String, ToolSpec> _tools = {};

  void register(ToolSpec tool) {
    _tools[tool.id] = tool;
  }

  void registerAll(List<ToolSpec> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  List<ToolSpec> list() => _tools.values.toList(growable: false);

  ToolSpec? findById(String id) => _tools[id];
}
```

`lib/core/bridge/bridge_gateway.dart`

```dart
class BridgeCallResult {
  const BridgeCallResult({
    required this.success,
    required this.data,
    required this.errorMessage,
    required this.debugMeta,
  });

  final bool success;
  final Object? data;
  final String? errorMessage;
  final Map<String, Object?> debugMeta;
}

abstract class BridgeGateway {
  Future<BridgeCallResult> call(
    String method,
    Map<String, Object?> params,
  );
}
```

`lib/core/bridge/mock_js_bridge_gateway.dart`

```dart
import 'package:learn_agent_flutter/core/bridge/bridge_gateway.dart';

class MockJsBridgeGateway implements BridgeGateway {
  @override
  Future<BridgeCallResult> call(
    String method,
    Map<String, Object?> params,
  ) async {
    if (params['forceError'] == true) {
      return BridgeCallResult(
        success: false,
        data: null,
        errorMessage: 'mock bridge error',
        debugMeta: {'bridgeMethod': method, 'mock': true},
      );
    }

    return BridgeCallResult(
      success: true,
      data: {'method': method, 'params': params},
      errorMessage: null,
      debugMeta: {'bridgeMethod': method, 'mock': true},
    );
  }
}
```

`lib/core/tool_runtime/executors/tool_executor.dart`

```dart
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

abstract class ToolExecutor {
  Future<ToolResult> execute(
    ToolSpec spec,
    Map<String, Object?> input,
  );
}
```

`lib/core/tool_runtime/executors/flutter_action_executor.dart`

```dart
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/tool_executor.dart';

typedef FlutterActionHandler = Future<Object?> Function(Map<String, Object?> input);

class FlutterActionExecutor implements ToolExecutor {
  FlutterActionExecutor({
    required this.handlers,
  });

  final Map<String, FlutterActionHandler> handlers;

  @override
  Future<ToolResult> execute(ToolSpec spec, Map<String, Object?> input) async {
    final handler = handlers[spec.id];
    if (handler == null) {
      return const ToolResult(
        success: false,
        data: null,
        errorMessage: 'flutter action handler not found',
        durationMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();
    final data = await handler(input);
    stopwatch.stop();

    return ToolResult(
      success: true,
      data: data,
      errorMessage: null,
      durationMs: stopwatch.elapsedMilliseconds,
      debugMeta: {'executor': 'flutter_action'},
    );
  }
}
```

`lib/core/tool_runtime/executors/js_bridge_action_executor.dart`

```dart
import 'package:learn_agent_flutter/core/bridge/bridge_gateway.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/tool_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

class JsBridgeActionExecutor implements ToolExecutor {
  JsBridgeActionExecutor({
    required this.gateway,
  });

  final BridgeGateway gateway;

  @override
  Future<ToolResult> execute(ToolSpec spec, Map<String, Object?> input) async {
    final method = spec.config['bridgeMethod'] as String?;
    if (method == null || method.isEmpty) {
      return const ToolResult(
        success: false,
        data: null,
        errorMessage: 'bridgeMethod is missing',
        durationMs: 0,
      );
    }

    final stopwatch = Stopwatch()..start();
    final bridgeResult = await gateway.call(method, input);
    stopwatch.stop();

    return ToolResult(
      success: bridgeResult.success,
      data: bridgeResult.data,
      errorMessage: bridgeResult.errorMessage,
      durationMs: stopwatch.elapsedMilliseconds,
      debugMeta: bridgeResult.debugMeta,
    );
  }
}
```

- [ ] **Step 4: 再次运行测试，确认通过**

Run: `flutter test test/core/tool_runtime -r expanded`
Expected: PASS

- [ ] **Step 5: 提交本任务**

```bash
git add lib/core/tool_runtime/registry/tool_registry.dart lib/core/tool_runtime/executors/tool_executor.dart lib/core/tool_runtime/executors/flutter_action_executor.dart lib/core/tool_runtime/executors/js_bridge_action_executor.dart lib/core/bridge/bridge_gateway.dart lib/core/bridge/mock_js_bridge_gateway.dart test/core/tool_runtime/tool_registry_test.dart test/core/tool_runtime/flutter_action_executor_test.dart test/core/tool_runtime/js_bridge_action_executor_test.dart
git commit -m "feat: add tool registry and executors"
```

### Task 4: 建立 runtime 调度层与调用日志

**Files:**
- Create: `lib/core/tool_runtime/logs/tool_invocation_log_store.dart`
- Create: `lib/core/tool_runtime/runtime/tool_runtime_context.dart`
- Create: `lib/core/tool_runtime/runtime/tool_runtime.dart`
- Modify: `lib/core/tool_runtime/models/tool_models.dart`
- Test: `test/core/tool_runtime/tool_runtime_test.dart`

- [ ] **Step 1: 先写 runtime 调度测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/bridge/mock_js_bridge_gateway.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/js_bridge_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';
import 'package:learn_agent_flutter/core/tool_runtime/registry/tool_registry.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime_context.dart';

void main() {
  test('runtime validates input executes tool and stores log', () async {
    final registry = ToolRegistry();
    const spec = ToolSpec(
      id: 'app.get_env',
      title: 'Get env',
      description: 'Returns env',
      executorType: ExecutorType.flutterAction,
      inputSchema: [],
    );
    registry.register(spec);

    final runtime = ToolRuntime(
      context: ToolRuntimeContext(
        registry: registry,
        flutterExecutor: FlutterActionExecutor(
          handlers: {'app.get_env': (_) async => {'mode': 'debug'}},
        ),
        jsBridgeExecutor: JsBridgeActionExecutor(
          gateway: MockJsBridgeGateway(),
        ),
      ),
    );

    final result = await runtime.invoke('app.get_env', {});

    expect(result.success, isTrue);
    expect(runtime.context.logStore.items, hasLength(1));
    expect(runtime.context.logStore.items.first.toolId, 'app.get_env');
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `flutter test test/core/tool_runtime/tool_runtime_test.dart -r expanded`
Expected: FAIL，提示 runtime、context、log store 未定义。

- [ ] **Step 3: 实现调度层与日志存储**

`lib/core/tool_runtime/models/tool_models.dart` 增补日志模型：

```dart
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
```

`lib/core/tool_runtime/logs/tool_invocation_log_store.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

class ToolInvocationLogStore extends ChangeNotifier {
  final List<ToolInvocationLog> _items = [];

  List<ToolInvocationLog> get items => List.unmodifiable(_items);

  void add(ToolInvocationLog item) {
    _items.insert(0, item);
    notifyListeners();
  }
}
```

`lib/core/tool_runtime/runtime/tool_runtime_context.dart`

```dart
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/js_bridge_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/logs/tool_invocation_log_store.dart';
import 'package:learn_agent_flutter/core/tool_runtime/registry/tool_registry.dart';

class ToolRuntimeContext {
  ToolRuntimeContext({
    required this.registry,
    required this.flutterExecutor,
    required this.jsBridgeExecutor,
    ToolInvocationLogStore? logStore,
  }) : logStore = logStore ?? ToolInvocationLogStore();

  final ToolRegistry registry;
  final FlutterActionExecutor flutterExecutor;
  final JsBridgeActionExecutor jsBridgeExecutor;
  final ToolInvocationLogStore logStore;
}
```

`lib/core/tool_runtime/runtime/tool_runtime.dart`

```dart
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

  Future<ToolResult> invoke(String toolId, Map<String, Object?> input) async {
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
        data: {'errors': validationErrors},
        errorMessage: validationErrors.join(', '),
        durationMs: 0,
      );
      context.logStore.add(
        ToolInvocationLog(
          toolId: toolId,
          status: InvocationStatus.failure,
          createdAt: DateTime.now(),
          durationMs: 0,
          inputSnapshot: input,
          outputSnapshot: result.data,
          errorMessage: result.errorMessage,
        ),
      );
      return result;
    }

    final result = switch (spec.executorType) {
      ExecutorType.flutterAction => await context.flutterExecutor.execute(spec, input),
      ExecutorType.jsBridgeAction => await context.jsBridgeExecutor.execute(spec, input),
    };

    context.logStore.add(
      ToolInvocationLog(
        toolId: toolId,
        status: result.success ? InvocationStatus.success : InvocationStatus.failure,
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
```

- [ ] **Step 4: 再次运行测试，确认通过**

Run: `flutter test test/core/tool_runtime/tool_runtime_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: 提交本任务**

```bash
git add lib/core/tool_runtime/models/tool_models.dart lib/core/tool_runtime/logs/tool_invocation_log_store.dart lib/core/tool_runtime/runtime/tool_runtime_context.dart lib/core/tool_runtime/runtime/tool_runtime.dart test/core/tool_runtime/tool_runtime_test.dart
git commit -m "feat: add tool runtime and invocation logs"
```

### Task 5: 注册 demo tools 并接好 app 级依赖

**Files:**
- Create: `lib/features/demo_tools/demo_tools.dart`
- Create: `lib/features/demo_tools/flutter_tools.dart`
- Create: `lib/features/demo_tools/bridge_tools.dart`
- Modify: `lib/app/app.dart`

- [ ] **Step 1: 先写 demo tool 注册代码**

`lib/features/demo_tools/flutter_tools.dart`

```dart
import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/app/routes.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

List<ToolSpec> buildFlutterToolSpecs() {
  return const [
    ToolSpec(
      id: 'app.get_env',
      title: 'Get App Environment',
      description: '返回当前 app 环境与平台信息',
      executorType: ExecutorType.flutterAction,
      inputSchema: [
        ToolInputField(name: 'includePlatform', type: ToolFieldType.boolean, required: false),
      ],
    ),
    ToolSpec(
      id: 'app.open_debug_page',
      title: 'Open Debug Page',
      description: '打开本地调试页',
      executorType: ExecutorType.flutterAction,
      inputSchema: [],
    ),
    ToolSpec(
      id: 'storage.set_value',
      title: 'Set Local Value',
      description: '写入本地 key/value',
      executorType: ExecutorType.flutterAction,
      inputSchema: [
        ToolInputField(name: 'key', type: ToolFieldType.string, required: true),
        ToolInputField(name: 'value', type: ToolFieldType.string, required: true),
      ],
    ),
  ];
}

Map<String, FlutterActionHandler> buildFlutterHandlers(GlobalKey<NavigatorState> navigatorKey) {
  final localStore = <String, String>{};

  return {
    'app.get_env': (input) async => {
          'appName': 'learn_agent_flutter',
          'mode': 'debug',
          'includePlatform': input['includePlatform'] ?? false,
        },
    'app.open_debug_page': (input) async {
      navigatorKey.currentState?.pushNamed(AppRoutes.debug);
      return {'opened': AppRoutes.debug};
    },
    'storage.set_value': (input) async {
      final key = input['key'] as String;
      final value = input['value'] as String;
      localStore[key] = value;
      return {'stored': true, 'key': key, 'value': value};
    },
  };
}
```

`lib/features/demo_tools/bridge_tools.dart`

```dart
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

List<ToolSpec> buildBridgeToolSpecs() {
  return const [
    ToolSpec(
      id: 'bridge.trace_event',
      title: 'Bridge Trace Event',
      description: '模拟 bridge 埋点调用',
      executorType: ExecutorType.jsBridgeAction,
      inputSchema: [
        ToolInputField(name: 'event', type: ToolFieldType.string, required: true),
      ],
      config: {'bridgeMethod': 'trace_event'},
    ),
    ToolSpec(
      id: 'bridge.open_webview',
      title: 'Bridge Open WebView',
      description: '模拟 bridge 打开 webview',
      executorType: ExecutorType.jsBridgeAction,
      inputSchema: [
        ToolInputField(name: 'url', type: ToolFieldType.string, required: true),
      ],
      config: {'bridgeMethod': 'open_webview'},
    ),
  ];
}
```

`lib/features/demo_tools/demo_tools.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/features/demo_tools/bridge_tools.dart';
import 'package:learn_agent_flutter/features/demo_tools/flutter_tools.dart';

List<ToolSpec> buildAllToolSpecs() {
  return [
    ...buildFlutterToolSpecs(),
    ...buildBridgeToolSpecs(),
  ];
}

Map<String, FlutterActionHandler> buildAllFlutterHandlers(
  GlobalKey<NavigatorState> navigatorKey,
) {
  return buildFlutterHandlers(navigatorKey);
}
```

- [ ] **Step 2: 将 app 入口切换为真实 runtime 装配**

`lib/app/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/app/routes.dart';
import 'package:learn_agent_flutter/core/bridge/mock_js_bridge_gateway.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/js_bridge_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/registry/tool_registry.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime_context.dart';
import 'package:learn_agent_flutter/features/debug/debug_page.dart';
import 'package:learn_agent_flutter/features/demo_tools/demo_tools.dart';
import 'package:learn_agent_flutter/features/logs/invocation_logs_page.dart';
import 'package:learn_agent_flutter/features/tool_console/tool_console_page.dart';

class AgentToolApp extends StatefulWidget {
  const AgentToolApp({super.key});

  @override
  State<AgentToolApp> createState() => _AgentToolAppState();
}

class _AgentToolAppState extends State<AgentToolApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  late final ToolRuntime runtime;

  @override
  void initState() {
    super.initState();
    final registry = ToolRegistry()..registerAll(buildAllToolSpecs());
    runtime = ToolRuntime(
      context: ToolRuntimeContext(
        registry: registry,
        flutterExecutor: FlutterActionExecutor(
          handlers: buildAllFlutterHandlers(navigatorKey),
        ),
        jsBridgeExecutor: JsBridgeActionExecutor(
          gateway: MockJsBridgeGateway(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Agent Tool Runtime Playground',
      routes: {
        AppRoutes.home: (_) => ToolConsolePage(runtime: runtime),
        AppRoutes.logs: (_) => InvocationLogsPage(logStore: runtime.context.logStore),
        AppRoutes.debug: (_) => const DebugPage(),
      },
      initialRoute: AppRoutes.home,
    );
  }
}
```

- [ ] **Step 3: 运行现有测试，确认仍然通过**

Run: `flutter test -r expanded`
Expected: PASS

- [ ] **Step 4: 提交本任务**

```bash
git add lib/features/demo_tools/demo_tools.dart lib/features/demo_tools/flutter_tools.dart lib/features/demo_tools/bridge_tools.dart lib/app/app.dart
git commit -m "feat: register demo tools and wire runtime"
```

### Task 6: 实现调试台与日志页 UI

**Files:**
- Create: `lib/features/tool_console/tool_console_controller.dart`
- Create: `lib/features/tool_console/tool_console_page.dart`
- Create: `lib/features/tool_console/widgets/tool_list_pane.dart`
- Create: `lib/features/tool_console/widgets/tool_inspector_pane.dart`
- Create: `lib/features/tool_console/widgets/tool_result_pane.dart`
- Create: `lib/features/logs/invocation_logs_page.dart`
- Create: `lib/shared/widgets/json_pretty_view.dart`
- Test: `test/features/tool_console/tool_console_page_test.dart`

- [ ] **Step 1: 先写调试台 smoke test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/app/app.dart';

void main() {
  testWidgets('tool console renders core panes', (tester) async {
    await tester.pumpWidget(const AgentToolApp());
    await tester.pumpAndSettle();

    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Result'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `flutter test test/features/tool_console/tool_console_page_test.dart -r expanded`
Expected: FAIL，提示 `ToolConsolePage` 或子组件未定义。

- [ ] **Step 3: 实现调试台 controller 与页面**

`lib/features/tool_console/tool_console_controller.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime.dart';

class ToolConsoleController extends ChangeNotifier {
  ToolConsoleController({required this.runtime}) {
    tools = runtime.context.registry.list();
    if (tools.isNotEmpty) {
      selectedTool = tools.first;
    }
  }

  final ToolRuntime runtime;
  late final List<ToolSpec> tools;
  ToolSpec? selectedTool;
  ToolResult? lastResult;
  bool isRunning = false;

  void selectTool(ToolSpec tool) {
    selectedTool = tool;
    notifyListeners();
  }

  Future<void> run(Map<String, Object?> input) async {
    final tool = selectedTool;
    if (tool == null) return;

    isRunning = true;
    notifyListeners();

    lastResult = await runtime.invoke(tool.id, input);

    isRunning = false;
    notifyListeners();
  }
}
```

`lib/shared/widgets/json_pretty_view.dart`

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

class JsonPrettyView extends StatelessWidget {
  const JsonPrettyView({
    super.key,
    required this.value,
  });

  final Object? value;

  @override
  Widget build(BuildContext context) {
    final content = const JsonEncoder.withIndent('  ').convert(value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFF3F4F6),
      child: SelectableText(content),
    );
  }
}
```

`lib/features/tool_console/widgets/tool_list_pane.dart`

```dart
import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

class ToolListPane extends StatelessWidget {
  const ToolListPane({
    super.key,
    required this.tools,
    required this.selectedToolId,
    required this.onSelect,
  });

  final List<ToolSpec> tools;
  final String? selectedToolId;
  final ValueChanged<ToolSpec> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tools'),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              final selected = tool.id == selectedToolId;
              return ListTile(
                selected: selected,
                title: Text(tool.title),
                subtitle: Text(tool.id),
                onTap: () => onSelect(tool),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

`lib/features/tool_console/widgets/tool_inspector_pane.dart`

```dart
import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

class ToolInspectorPane extends StatefulWidget {
  const ToolInspectorPane({
    super.key,
    required this.tool,
    required this.isRunning,
    required this.onSubmit,
  });

  final ToolSpec? tool;
  final bool isRunning;
  final ValueChanged<Map<String, Object?>> onSubmit;

  @override
  State<ToolInspectorPane> createState() => _ToolInspectorPaneState();
}

class _ToolInspectorPaneState extends State<ToolInspectorPane> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void didUpdateWidget(covariant ToolInspectorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tool?.id != widget.tool?.id) {
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    if (tool == null) {
      return const Center(child: Text('No tool selected'));
    }

    return ListView(
      children: [
        const Text('Inspector'),
        const SizedBox(height: 12),
        Text(tool.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(tool.description),
        const SizedBox(height: 16),
        for (final field in tool.inputSchema)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _controllers.putIfAbsent(
                field.name,
                () => TextEditingController(),
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: field.name,
                helperText: field.description,
              ),
            ),
          ),
        FilledButton(
          onPressed: widget.isRunning
              ? null
              : () {
                  final input = <String, Object?>{};
                  for (final field in tool.inputSchema) {
                    final raw = _controllers[field.name]?.text;
                    if (raw == null || raw.isEmpty) continue;
                    input[field.name] = raw;
                  }
                  widget.onSubmit(input);
                },
          child: Text(widget.isRunning ? 'Running...' : 'Run Tool'),
        ),
      ],
    );
  }
}
```

`lib/features/tool_console/widgets/tool_result_pane.dart`

```dart
import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/shared/widgets/json_pretty_view.dart';

class ToolResultPane extends StatelessWidget {
  const ToolResultPane({
    super.key,
    required this.result,
  });

  final ToolResult? result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Result'),
        const SizedBox(height: 12),
        if (result == null) const Text('No invocation yet'),
        if (result != null) ...[
          Text('success: ${result!.success}'),
          Text('durationMs: ${result!.durationMs}'),
          if (result!.errorMessage != null) Text('error: ${result!.errorMessage}'),
          const SizedBox(height: 12),
          JsonPrettyView(value: {
            'data': result!.data,
            'debugMeta': result!.debugMeta,
          }),
        ],
      ],
    );
  }
}
```

`lib/features/logs/invocation_logs_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/core/tool_runtime/logs/tool_invocation_log_store.dart';

class InvocationLogsPage extends StatelessWidget {
  const InvocationLogsPage({
    super.key,
    required this.logStore,
  });

  final ToolInvocationLogStore logStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invocation Logs')),
      body: AnimatedBuilder(
        animation: logStore,
        builder: (context, _) {
          final items = logStore.items;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.toolId),
                subtitle: Text('${item.status.name} · ${item.durationMs}ms'),
              );
            },
          );
        },
      ),
    );
  }
}
```

`lib/features/tool_console/tool_console_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/app/routes.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime.dart';
import 'package:learn_agent_flutter/features/tool_console/tool_console_controller.dart';
import 'package:learn_agent_flutter/features/tool_console/widgets/tool_inspector_pane.dart';
import 'package:learn_agent_flutter/features/tool_console/widgets/tool_list_pane.dart';
import 'package:learn_agent_flutter/features/tool_console/widgets/tool_result_pane.dart';

class ToolConsolePage extends StatefulWidget {
  const ToolConsolePage({
    super.key,
    required this.runtime,
  });

  final ToolRuntime runtime;

  @override
  State<ToolConsolePage> createState() => _ToolConsolePageState();
}

class _ToolConsolePageState extends State<ToolConsolePage> {
  late final ToolConsoleController controller;

  @override
  void initState() {
    super.initState();
    controller = ToolConsoleController(runtime: widget.runtime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Tool Runtime Playground'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.logs),
            child: const Text('Logs'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ToolListPane(
                    tools: controller.tools,
                    selectedToolId: controller.selectedTool?.id,
                    onSelect: controller.selectTool,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: ToolInspectorPane(
                    tool: controller.selectedTool,
                    isRunning: controller.isRunning,
                    onSubmit: controller.run,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: ToolResultPane(result: controller.lastResult),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: 运行 smoke test 和全量测试**

Run: `flutter test -r expanded`
Expected: PASS

- [ ] **Step 5: 提交本任务**

```bash
git add lib/features/tool_console/tool_console_controller.dart lib/features/tool_console/tool_console_page.dart lib/features/tool_console/widgets/tool_list_pane.dart lib/features/tool_console/widgets/tool_inspector_pane.dart lib/features/tool_console/widgets/tool_result_pane.dart lib/features/logs/invocation_logs_page.dart lib/shared/widgets/json_pretty_view.dart test/features/tool_console/tool_console_page_test.dart
git commit -m "feat: build tool console and logs ui"
```

### Task 7: 完成输入类型转换与最终验证

**Files:**
- Modify: `lib/features/tool_console/widgets/tool_inspector_pane.dart`
- Modify: `lib/features/demo_tools/flutter_tools.dart`
- Modify: `lib/features/demo_tools/bridge_tools.dart`
- Test: `test/features/tool_console/tool_console_input_parse_test.dart`

- [ ] **Step 1: 先写输入类型转换测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';
import 'package:learn_agent_flutter/features/tool_console/widgets/tool_inspector_pane.dart';

void main() {
  test('parses boolean input from text', () {
    final field = const ToolInputField(
      name: 'includePlatform',
      type: ToolFieldType.boolean,
      required: false,
    );

    final value = ToolInputParser.parse(field, 'true');

    expect(value, isTrue);
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `flutter test test/features/tool_console/tool_console_input_parse_test.dart -r expanded`
Expected: FAIL，提示 `ToolInputParser` 未定义。

- [ ] **Step 3: 为 Inspector 增加类型转换，修复 boolean/number/json 输入**

`lib/features/tool_console/widgets/tool_inspector_pane.dart` 增补：

```dart
import 'dart:convert';
```

并在文件内添加：

```dart
class ToolInputParser {
  static Object? parse(ToolInputField field, String raw) {
    switch (field.type) {
      case ToolFieldType.string:
        return raw;
      case ToolFieldType.number:
        return num.parse(raw);
      case ToolFieldType.boolean:
        return raw.toLowerCase() == 'true';
      case ToolFieldType.json:
        return json.decode(raw) as Object;
    }
  }
}
```

将提交逻辑替换为：

```dart
for (final field in tool.inputSchema) {
  final raw = _controllers[field.name]?.text;
  if (raw == null || raw.isEmpty) continue;
  input[field.name] = ToolInputParser.parse(field, raw);
}
```

同时为 `bridge.trace_event`、`bridge.open_webview`、`storage.set_value` 的字段补充 `description`，让调试台有更明确的参数说明。

- [ ] **Step 4: 运行最终验证**

Run: `flutter test -r expanded`
Expected: PASS

Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: 提交本任务**

```bash
git add lib/features/tool_console/widgets/tool_inspector_pane.dart lib/features/demo_tools/flutter_tools.dart lib/features/demo_tools/bridge_tools.dart test/features/tool_console/tool_console_input_parse_test.dart
git commit -m "feat: add typed tool input parsing"
```

## 自检

### Spec 覆盖检查

- 统一 tool 定义：Task 2
- 两类执行器：Task 3
- runtime 调度与日志：Task 4
- demo tools：Task 5
- 调试台与日志页：Task 6
- 输入类型处理与最终验证：Task 7

无遗漏项。

### 占位检查

本计划未使用 `TBD`、`TODO`、`implement later` 或“后续补充细节”之类占位语句。

### 类型一致性检查

- `ExecutorType.flutterAction` / `ExecutorType.jsBridgeAction` 在模型、执行器、demo tools 中保持一致。
- `ToolRuntime.invoke(String toolId, Map<String, Object?> input)` 在 controller 和测试中保持一致。
- `ToolInvocationLogStore.items` 在 runtime 与日志页中保持一致。

无已知命名冲突。
