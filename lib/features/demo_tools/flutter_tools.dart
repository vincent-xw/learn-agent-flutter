import 'package:flutter/widgets.dart';
import 'package:learn_agent_flutter/app/routes.dart';
import 'package:learn_agent_flutter/core/tool_runtime/executors/flutter_action_executor.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_models.dart';
import 'package:learn_agent_flutter/core/tool_runtime/models/tool_types.dart';

List<ToolSpec> buildFlutterToolSpecs() {
  return const [
    ToolSpec(
      id: 'app.get_env',
      title: 'Get App Environment',
      description: '返回当前 app 环境与平台信息',
      executorType: ExecutorType.flutterAction,
      inputSchema: [
        ToolInputField(
          name: 'includePlatform',
          type: ToolFieldType.boolean,
          isRequired: false,
          description: '是否返回平台字段，输入 true 或 false',
        ),
      ],
    ),
    ToolSpec(
      id: 'app.open_debug_page',
      title: 'Open Debug Page',
      description: '打开本地调试页',
      executorType: ExecutorType.flutterAction,
      inputSchema: [],
    ),
    ToolSpec(
      id: 'storage.set_value',
      title: 'Set Local Value',
      description: '写入本地 key/value',
      executorType: ExecutorType.flutterAction,
      inputSchema: [
        ToolInputField(
          name: 'key',
          type: ToolFieldType.string,
          isRequired: true,
          description: '本地存储 key',
        ),
        ToolInputField(
          name: 'value',
          type: ToolFieldType.string,
          isRequired: true,
          description: '本地存储 value',
        ),
      ],
    ),
  ];
}

Map<String, FlutterActionHandler> buildFlutterHandlers(
  GlobalKey<NavigatorState> navigatorKey,
) {
  final localStore = <String, String>{};

  return {
    'app.get_env': (input) async => {
          'appName': 'learn_agent_flutter',
          'mode': 'debug',
          'platform':
              (input['includePlatform'] == true) ? 'flutter-container' : null,
        },
    'app.open_debug_page': (input) async {
      navigatorKey.currentState?.pushNamed(AppRoutes.debug);
      return {
        'opened': AppRoutes.debug,
      };
    },
    'storage.set_value': (input) async {
      final key = input['key'] as String;
      final value = input['value'] as String;
      localStore[key] = value;
      return {
        'stored': true,
        'key': key,
        'value': value,
      };
    },
  };
}
