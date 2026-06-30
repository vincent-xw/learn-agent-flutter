import 'package:flutter/foundation.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/runtime/tool_runtime.dart';

class ToolConsoleController extends ChangeNotifier {
  ToolConsoleController({
    required this.runtime,
  }) {
    _allTools = runtime.context.registry.list();
    _filteredTools = List<ToolSpec>.from(_allTools);
    if (_filteredTools.isNotEmpty) {
      selectedTool = _filteredTools.first;
    }
  }

  final ToolRuntime runtime;
  late final List<ToolSpec> _allTools;
  late List<ToolSpec> _filteredTools;
  ToolSpec? selectedTool;
  ToolResult? lastResult;
  bool isRunning = false;
  String query = '';

  List<ToolSpec> get tools => List.unmodifiable(_filteredTools);

  void setQuery(String value) {
    query = value;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      _filteredTools = List<ToolSpec>.from(_allTools);
    } else {
      _filteredTools = _allTools.where((tool) {
        return tool.id.toLowerCase().contains(normalized) ||
            tool.title.toLowerCase().contains(normalized);
      }).toList(growable: false);
    }
    if (_filteredTools.isNotEmpty &&
        !_filteredTools.any((tool) => tool.id == selectedTool?.id)) {
      selectedTool = _filteredTools.first;
    }
    notifyListeners();
  }

  void selectTool(ToolSpec tool) {
    selectedTool = tool;
    notifyListeners();
  }

  Future<void> run(Map<String, Object?> input) async {
    final tool = selectedTool;
    if (tool == null) {
      return;
    }

    isRunning = true;
    notifyListeners();

    lastResult = await runtime.invoke(tool.id, input);

    isRunning = false;
    notifyListeners();
  }
}
