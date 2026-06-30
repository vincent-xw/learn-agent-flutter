import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';

class ToolListPane extends StatelessWidget {
  const ToolListPane({
    super.key,
    required this.tools,
    required this.selectedToolId,
    required this.query,
    required this.onQueryChanged,
    required this.onSelect,
  });

  final List<ToolSpec> tools;
  final String? selectedToolId;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ToolSpec> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: onQueryChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search tools',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  final selected = tool.id == selectedToolId;
                  return Card(
                    color: selected ? const Color(0xFFE0F2FE) : null,
                    child: ListTile(
                      title: Text(tool.title),
                      subtitle: Text(tool.id),
                      onTap: () => onSelect(tool),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
