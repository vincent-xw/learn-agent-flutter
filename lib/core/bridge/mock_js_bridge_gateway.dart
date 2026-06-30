import 'package:learn_agent_flutter/core/bridge/bridge_gateway.dart';

class MockJsBridgeGateway implements BridgeGateway {
  @override
  Future<BridgeCallResult> call(
    String method,
    Map<String, Object?> params,
  ) async {
    if (params['forceError'] == true) {
      return BridgeCallResult(
        success: false,
        data: null,
        errorMessage: 'mock bridge error',
        debugMeta: {
          'bridgeMethod': method,
          'mock': true,
        },
      );
    }

    return BridgeCallResult(
      success: true,
      data: {
        'method': method,
        'params': params,
      },
      errorMessage: null,
      debugMeta: {
        'bridgeMethod': method,
        'mock': true,
      },
    );
  }
}
