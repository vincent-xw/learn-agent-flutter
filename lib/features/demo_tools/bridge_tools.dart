import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

List<ToolSpec> buildBridgeToolSpecs() {
  return const [
    ToolSpec(
      id: 'bridge.trace_event',
      title: 'Bridge Trace Event',
      description: '模拟通过 bridge 分发埋点事件',
      executorType: ExecutorType.jsBridgeAction,
      inputSchema: [
        ToolInputField(
          name: 'event',
          type: ToolFieldType.string,
          isRequired: true,
          description: '埋点事件名',
        ),
      ],
      config: {
        'bridgeMethod': 'trace_event',
      },
    ),
    ToolSpec(
      id: 'bridge.open_webview',
      title: 'Bridge Open WebView',
      description: '模拟通过 bridge 分发打开 webview 的能力',
      executorType: ExecutorType.jsBridgeAction,
      inputSchema: [
        ToolInputField(
          name: 'url',
          type: ToolFieldType.string,
          isRequired: true,
          description: '目标 URL',
        ),
      ],
      config: {
        'bridgeMethod': 'open_webview',
      },
    ),
  ];
}
