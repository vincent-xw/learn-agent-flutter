import 'package:flutter/widgets.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/features/demo_tools/bridge_tools.dart';
import 'package:learn_agent_flutter/features/demo_tools/flutter_tools.dart';

List<ToolSpec> buildAllToolSpecs() {
  return [
    ...buildFlutterToolSpecs(),
    ...buildBridgeToolSpecs(),
  ];
}

Map<String, FlutterActionHandler> buildAllFlutterHandlers(
  GlobalKey<NavigatorState> navigatorKey,
) {
  return buildFlutterHandlers(navigatorKey);
}
