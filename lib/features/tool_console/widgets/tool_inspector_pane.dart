import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

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
      return const Center(
        child: Text('No tool selected'),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Inspector',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              tool.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
                        if (raw == null || raw.isEmpty) {
                          continue;
                        }
                        input[field.name] = ToolInputParser.parse(field, raw);
                      }
                      widget.onSubmit(input);
                    },
              child: Text(widget.isRunning ? 'Running...' : 'Run Tool'),
            ),
          ],
        ),
      ),
    );
  }
}
