import 'package:flutter_test/flutter_test.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';
import 'package:learn_agent_flutter/core/tool_runtime/validation/tool_input_validator.dart';

void main() {
  final validator = ToolInputValidator();

  test('returns no errors for valid input', () {
    const spec = ToolSpec(
      id: 'storage.set_value',
      title: 'Set value',
      description: 'Stores key value pair',
      executorType: ExecutorType.flutterAction,
      inputSchema: [
        ToolInputField(
          name: 'key',
          type: ToolFieldType.string,
          isRequired: true,
        ),
        ToolInputField(
          name: 'value',
          type: ToolFieldType.string,
          isRequired: true,
        ),
      ],
    );

    final errors = validator.validate(spec, {
      'key': 'token',
      'value': '123',
    });

    expect(errors, isEmpty);
  });

  test('returns error when required field missing', () {
    const spec = ToolSpec(
      id: 'bridge.trace_event',
      title: 'Trace event',
      description: 'Sends trace event',
      executorType: ExecutorType.jsBridgeAction,
      inputSchema: [
        ToolInputField(
          name: 'event',
          type: ToolFieldType.string,
          isRequired: true,
        ),
      ],
    );

    final errors = validator.validate(spec, {});

    expect(errors, ['event is required']);
  });

  test('returns error when field type mismatches', () {
    const spec = ToolSpec(
      id: 'app.get_env',
      title: 'Get env',
      description: 'Returns environment',
      executorType: ExecutorType.flutterAction,
      inputSchema: [
        ToolInputField(
          name: 'includePlatform',
          type: ToolFieldType.boolean,
          isRequired: true,
        ),
      ],
    );

    final errors = validator.validate(spec, {
      'includePlatform': 'true',
    });

    expect(errors, ['includePlatform must be a boolean']);
  });
}
