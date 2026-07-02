class SessionState {
  const SessionState({
    required this.sessionId,
    this.activeCallId,
    this.lastSequence = 0,
  });

  final String sessionId;
  final String? activeCallId;
  final int lastSequence;

  bool get hasActiveCall => activeCallId != null;

  SessionState copyWith({
    String? activeCallId,
    int? lastSequence,
    bool clearActiveCall = false,
  }) {
    return SessionState(
      sessionId: sessionId,
      activeCallId: clearActiveCall ? null : (activeCallId ?? this.activeCallId),
      lastSequence: lastSequence ?? this.lastSequence,
    );
  }
}

class SessionStateException implements Exception {
  const SessionStateException(this.message);

  final String message;

  @override
  String toString() => 'SessionStateException: $message';
}
