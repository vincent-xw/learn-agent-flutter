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
