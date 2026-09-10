/// A check-in or check-out the employee performed while offline (or that failed
/// to reach the backend), captured locally so it can be replayed against the
/// Cloud Functions once connectivity returns.
///
/// [clientEventAt] is the real moment the employee tapped, captured at enqueue
/// time and sent on replay so the recorded attendance reflects when it actually
/// happened rather than when the queue drained.
enum PendingAttendanceKind { checkIn, checkOut }

class PendingAttendanceAction {
  const PendingAttendanceAction({
    required this.localId,
    required this.kind,
    required this.storeId,
    required this.employeeId,
    required this.clientEventAt,
    this.attendanceId,
    this.latitude,
    this.longitude,
    this.lateCheckInNote,
    this.earlyCheckOutNote,
    this.leaveNote,
    this.absentNote,
    this.qrToken,
    this.attempts = 0,
    this.lastError,
  });

  /// Locally-unique id used to find and remove this action from the queue.
  final String localId;
  final PendingAttendanceKind kind;
  final String storeId;
  final String employeeId;

  /// Epoch milliseconds of the tap.
  final int clientEventAt;

  /// Server attendance id for a check-out of an already-synced record. Null for
  /// a check-out whose check-in is still queued — the backend then resolves the
  /// open record from [employeeId].
  final String? attendanceId;

  final double? latitude;
  final double? longitude;
  final String? lateCheckInNote;
  final String? earlyCheckOutNote;
  final String? leaveNote;
  final String? absentNote;
  final String? qrToken;

  /// How many replay attempts have been made (for backoff/diagnostics).
  final int attempts;
  final String? lastError;

  DateTime get eventTime =>
      DateTime.fromMillisecondsSinceEpoch(clientEventAt);

  PendingAttendanceAction copyWith({
    String? attendanceId,
    int? attempts,
    String? lastError,
  }) {
    return PendingAttendanceAction(
      localId: localId,
      kind: kind,
      storeId: storeId,
      employeeId: employeeId,
      clientEventAt: clientEventAt,
      attendanceId: attendanceId ?? this.attendanceId,
      latitude: latitude,
      longitude: longitude,
      lateCheckInNote: lateCheckInNote,
      earlyCheckOutNote: earlyCheckOutNote,
      leaveNote: leaveNote,
      absentNote: absentNote,
      qrToken: qrToken,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'kind': kind.name,
        'storeId': storeId,
        'employeeId': employeeId,
        'clientEventAt': clientEventAt,
        if (attendanceId != null) 'attendanceId': attendanceId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (lateCheckInNote != null) 'lateCheckInNote': lateCheckInNote,
        if (earlyCheckOutNote != null) 'earlyCheckOutNote': earlyCheckOutNote,
        if (leaveNote != null) 'leaveNote': leaveNote,
        if (absentNote != null) 'absentNote': absentNote,
        if (qrToken != null) 'qrToken': qrToken,
        'attempts': attempts,
        if (lastError != null) 'lastError': lastError,
      };

  factory PendingAttendanceAction.fromJson(Map<String, dynamic> json) {
    return PendingAttendanceAction(
      localId: json['localId'] as String,
      kind: PendingAttendanceKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => PendingAttendanceKind.checkIn,
      ),
      storeId: json['storeId'] as String,
      employeeId: json['employeeId'] as String,
      clientEventAt: (json['clientEventAt'] as num).toInt(),
      attendanceId: json['attendanceId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lateCheckInNote: json['lateCheckInNote'] as String?,
      earlyCheckOutNote: json['earlyCheckOutNote'] as String?,
      leaveNote: json['leaveNote'] as String?,
      absentNote: json['absentNote'] as String?,
      qrToken: json['qrToken'] as String?,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}
