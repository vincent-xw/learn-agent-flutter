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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      routes: {
        AppRoutes.home: (_) => ToolConsolePage(runtime: runtime),
        AppRoutes.logs: (_) => InvocationLogsPage(
              logStore: runtime.context.logStore,
            ),
        AppRoutes.debug: (_) => const DebugPage(),
      },
      initialRoute: AppRoutes.home,
    );
  }
}
