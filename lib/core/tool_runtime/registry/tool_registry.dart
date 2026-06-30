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
