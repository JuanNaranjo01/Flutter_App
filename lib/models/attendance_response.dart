/// Modelo para la respuesta del endpoint de registro de asistencia
class AttendanceResponse {
  final bool success;
  final String message;
  final AttendanceData? data;
  final String? error;

  AttendanceResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : ((json['estudiante'] != null ||
                json['codigo_estudiante'] != null ||
                json['materia'] != null ||
                json['fecha'] != null ||
                json['hora'] != null)
            ? json
            : null);

    return AttendanceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: dataJson != null ? AttendanceData.fromJson(dataJson) : null,
      error: json['error'],
    );
  }

  factory AttendanceResponse.error(String errorMessage) {
    return AttendanceResponse(
      success: false,
      message: '',
      error: errorMessage,
    );
  }
}

/// Datos del registro de asistencia exitoso
class AttendanceData {
  final String estudiante;
  final String codigoEstudiante;
  final String programa;
  final double confidence;
  final int sesionId;
  final String materia;
  final String fecha;
  final String hora;

  AttendanceData({
    required this.estudiante,
    required this.codigoEstudiante,
    required this.programa,
    required this.confidence,
    required this.sesionId,
    required this.materia,
    required this.fecha,
    required this.hora,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      estudiante: json['estudiante'] ?? '',
      codigoEstudiante: json['codigo_estudiante'] ?? '',
      programa: json['programa'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      sesionId: json['sesion_id'] ?? 0,
      materia: json['materia'] ?? '',
      fecha: json['fecha'] ?? '',
      hora: json['hora'] ?? '',
    );
  }
}
