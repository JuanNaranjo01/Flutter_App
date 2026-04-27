class ApiConfig {
  static const String baseUrl = 'http://192.168.14.25';
  static const String apiPath = '/api';
  static const String fullApiUrl = '$baseUrl$apiPath';

  // Endpoints de autenticación
  static const String loginEndpoint = '/login';
  static const String verifyTeacherEndpoint = '/api/verify_teacher';

  // Endpoints de embeddings faciales
  static const String searchStudentEndpoint = '$apiPath/search_student';
  static const String registerEmbeddingsEndpoint =
      '$apiPath/register_student_embeddings';
  static const String studentOtpRequestEndpoint =
      '$apiPath/student/request-otp';
  static const String studentOtpVerifyEndpoint = '$apiPath/student/verify-otp';

  // Endpoints de reconocimiento y asistencia
  static const String recognizeAndMarkEndpoint = '$apiPath/recognize_mobile';
  static const String attendanceHistoryEndpoint =
      '$apiPath/get_attendance_history';

  // Endpoints generales
  static const String facesEndpoint = '/faces';
  static const String attendanceEndpoint = '/attendance';

  // ✅ NUEVOS ENDPOINTS FLUTTER - Sistema de Asistencias (27/02/2026)
  // Documentados en: GUIA_RAPIDA_FRONTEND.md y PARA_FRONTEND_README.md
  static const String flutterApiPath = '$apiPath/flutter';

  // GET /api/flutter/diagnostico-bd - Diagnóstico de BD (opcional, sin auth)
  static const String flutterDiagnosticEndpoint =
      '$flutterApiPath/diagnostico-bd';

  // POST /api/flutter/curso/{id}/estudiantes - Lista estudiantes con estadísticas
  // POST /api/flutter/curso/{id}/estudiante/{codigo}/detalle - Historial completo
  // POST /api/flutter/curso/{id}/estudiante/{codigo}/faltas - Solo faltas
  // Nota: Estos endpoints requieren session_token en el body (no en headers)

  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
