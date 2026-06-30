import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';
import 'package:learn_agent_flutter/features/tool_console/widgets/tool_inspector_pane.dart';

void main() {
  test('parses boolean input from text', () {
    const field = ToolInputField(
      name: 'includePlatform',
      type: ToolFieldType.boolean,
      isRequired: false,
    );

    final value = ToolInputParser.parse(field, 'true');

    expect(value, isTrue);
  });
}
