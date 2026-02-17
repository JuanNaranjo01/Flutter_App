import 'attendance_record.dart';

/// Respuesta del endpoint de consulta de historial de asistencias
class AttendanceHistoryResponse {
  final bool success;
  final List<AttendanceRecord> records;
  final String? error;

  AttendanceHistoryResponse({
    required this.success,
    required this.records,
    this.error,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponse(
      success: json['success'] ?? false,
      records: json['records'] != null
          ? (json['records'] as List)
              .map((record) => AttendanceRecord.fromJson(record))
              .toList()
          : [],
      error: json['error'],
    );
  }

  factory AttendanceHistoryResponse.error(String errorMessage) {
    return AttendanceHistoryResponse(
      success: false,
      records: [],
      error: errorMessage,
    );
  }
}
