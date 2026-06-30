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
