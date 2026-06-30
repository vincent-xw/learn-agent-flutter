import 'package:flutter/material.dart';
import 'package:learn_agent_flutter/core/tool_runtime/logs/tool_invocation_log_store.dart';
import 'package:learn_agent_flutter/shared/widgets/json_pretty_view.dart';

class InvocationLogsPage extends StatelessWidget {
  const InvocationLogsPage({
    super.key,
    required this.logStore,
  });

  final ToolInvocationLogStore logStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invocation Logs'),
      ),
      body: AnimatedBuilder(
        animation: logStore,
        builder: (context, _) {
          final items = logStore.items;
          if (items.isEmpty) {
            return const Center(
              child: Text('No logs yet'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ExpansionTile(
                  title: Text(item.toolId),
                  subtitle: Text('${item.status.name} · ${item.durationMs}ms'),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('time: ${item.createdAt.toIso8601String()}'),
                    ),
                    const SizedBox(height: 8),
                    JsonPrettyView(
                      value: {
                        'input': item.inputSnapshot,
                        'output': item.outputSnapshot,
                        'error': item.errorMessage,
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
