class ApiConfig {
  static const String baseUrl = 'http://192.168.100.99:5000';
  static const String apiPath = '/api';
  static const String fullApiUrl = '$baseUrl$apiPath';

  // Endpoints de autenticación
  static const String loginEndpoint = '/login';
  static const String verifyTeacherEndpoint = '/api/verify_teacher';

  // Endpoints de embeddings faciales
  static const String searchStudentEndpoint = '$apiPath/search_student';
  static const String registerEmbeddingsEndpoint =
      '$apiPath/register_student_embeddings';

  // Endpoints de reconocimiento y asistencia
  static const String recognizeAndMarkEndpoint = '$apiPath/recognize_mobile';
  static const String attendanceHistoryEndpoint =
      '$apiPath/get_attendance_history';

  // Endpoints generales
  static const String facesEndpoint = '/faces';
  static const String attendanceEndpoint = '/attendance';

  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
