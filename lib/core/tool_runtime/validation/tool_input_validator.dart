import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

class ToolInputValidator {
  List<String> validate(ToolSpec spec, Map<String, Object?> input) {
    final errors = <String>[];

    for (final field in spec.inputSchema) {
      final value = input[field.name];

      if (field.isRequired && value == null) {
        errors.add('${field.name} is required');
        continue;
      }

      if (value == null) {
        continue;
      }

      switch (field.type) {
        case ToolFieldType.string:
          if (value is! String) {
            errors.add('${field.name} must be a string');
          }
          break;
        case ToolFieldType.number:
          if (value is! num) {
            errors.add('${field.name} must be a number');
          }
          break;
        case ToolFieldType.boolean:
          if (value is! bool) {
            errors.add('${field.name} must be a boolean');
          }
          break;
        case ToolFieldType.json:
          if (value is! Map && value is! List) {
            errors.add('${field.name} must be json compatible');
          }
          break;
      }
    }

    return errors;
  }
}
