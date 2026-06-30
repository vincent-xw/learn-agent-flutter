class BridgeCallResult {
  const BridgeCallResult({
    required this.success,
    required this.data,
    required this.errorMessage,
    required this.debugMeta,
  });

  final bool success;
  final Object? data;
  final String? errorMessage;
  final Map<String, Object?> debugMeta;
}

abstract class BridgeGateway {
  Future<BridgeCallResult> call(
    String method,
    Map<String, Object?> params,
  );
}
