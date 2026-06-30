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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: ToolListPane(
                    tools: controller.tools,
                    selectedToolId: controller.selectedTool?.id,
                    query: controller.query,
                    onQueryChanged: controller.setQuery,
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
                  child: ToolResultPane(
                    result: controller.lastResult,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
