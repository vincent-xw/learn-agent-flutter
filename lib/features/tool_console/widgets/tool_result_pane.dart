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
              'Result',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (result == null) const Text('No invocation yet'),
            if (result != null) ...[
              Text('success: ${result!.success}'),
              Text('durationMs: ${result!.durationMs}'),
              if (result!.errorMessage != null)
                Text('error: ${result!.errorMessage}'),
              const SizedBox(height: 12),
              JsonPrettyView(
                value: {
                  'data': result!.data,
                  'debugMeta': result!.debugMeta,
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
