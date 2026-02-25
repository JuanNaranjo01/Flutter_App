import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../config/api_config.dart';
import '../models/student.dart';
import '../models/attendance_response.dart';
import '../models/attendance_history_response.dart';
import '../models/course.dart';
import '../models/course_student.dart';
import '../models/attendance_detail.dart';
import '../models/periodo.dart';
import '../models/estadisticas_corte.dart';

class ApiService {
  // Cliente HTTP con timeouts configurados
  static final _httpClient = http.Client();

  static Future<Map<String, dynamic>> login(
      String codigo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'codigo': codigo, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getRegisteredFaces() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.facesEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getAttendanceRecords() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.attendanceEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Busca un estudiante por código
  /// Retorna [SearchStudentResponse]
  static Future<SearchStudentResponse> searchStudent(String codigo,
      {int maxRetries = 2}) async {
    int retries = 0;

    while (retries <= maxRetries) {
      try {
        final response = await _httpClient
            .post(
              Uri.parse(
                  '${ApiConfig.baseUrl}${ApiConfig.searchStudentEndpoint}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'codigo': codigo}),
            )
            .timeout(
              ApiConfig.connectionTimeout,
              onTimeout: () =>
                  throw TimeoutException('Timeout en búsqueda de estudiante'),
            );

        if (response.statusCode == 200) {
          return SearchStudentResponse.fromJson(jsonDecode(response.body));
        } else if (response.statusCode == 404) {
          return SearchStudentResponse(
            success: false,
            found: false,
            message: 'Estudiante con código $codigo no encontrado en BIENESTAR',
          );
        } else {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      } on TimeoutException {
        retries++;
        if (retries > maxRetries) {
          throw TimeoutException(
              'El servidor tardó demasiado en responder. Intenta de nuevo.');
        }
      } on SocketException {
        retries++;
        if (retries > maxRetries) {
          throw const SocketException(
              'No se pudo conectar al servidor. Verifica tu conexión WiFi.');
        }
      } catch (e) {
        rethrow;
      }
    }
    throw Exception('Error desconocido en la búsqueda');
  }

  /// Registra embeddings faciales para un estudiante
  /// [codigoEstudiante]: código del estudiante
  /// [images]: lista de imágenes en formato base64 (data:image/jpeg;base64,...)
  /// [forceUpdate]: si es true, actualiza embeddings existentes
  static Future<StudentEmbeddingResponse> registerStudentEmbeddings({
    required String codigoEstudiante,
    required List<String> images,
    bool forceUpdate = false,
    int maxRetries = 2,
  }) async {
    // Validar cantidad de imágenes
    if (images.length < 3 || images.length > 5) {
      throw ArgumentError(
          'Debes capturar entre 3 y 5 fotos. Capturaste ${images.length}.');
    }

    int retries = 0;

    while (retries <= maxRetries) {
      try {
        final requestBody = {
          'codigo_estudiante': codigoEstudiante,
          'images': images,
          'force_update': forceUpdate,
        };

        final response = await _httpClient
            .post(
              Uri.parse(
                  '${ApiConfig.baseUrl}${ApiConfig.registerEmbeddingsEndpoint}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(
              ApiConfig.receiveTimeout,
              onTimeout: () => throw TimeoutException(
                  'El servidor tardó demasiado procesando las imágenes'),
            );

        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200 || response.statusCode == 201) {
          return StudentEmbeddingResponse.fromJson(responseData);
        } else if (response.statusCode == 409) {
          throw ConflictException(
            responseData['message'] ?? 'El estudiante ya tiene embeddings',
            existingEmbeddings: responseData['existing_embeddings'] ?? 0,
          );
        } else if (response.statusCode == 404) {
          throw NotFoundException(
            'Estudiante con código $codigoEstudiante no encontrado en BIENESTAR',
          );
        } else {
          throw Exception(
              'Error ${response.statusCode}: ${responseData['message']}');
        }
      } on TimeoutException {
        retries++;
        if (retries > maxRetries) {
          rethrow;
        }
      } on SocketException {
        retries++;
        if (retries > maxRetries) {
          rethrow;
        }
      } catch (e) {
        rethrow;
      }
    }

    throw Exception('Error desconocido al registrar embeddings');
  }

  /// Registra asistencia mediante reconocimiento facial
  /// [frames]: lista de 4 imágenes en formato base64 (data:image/jpeg;base64,...)
  /// [sessionToken]: token de sesión del docente autenticado
  /// Retorna [AttendanceResponse] con los datos del registro
  static Future<AttendanceResponse> registrarAsistencia({
    required List<String> frames,
    String? sessionToken,
    int maxRetries = 2,
  }) async {
    // Validar cantidad de frames
    if (frames.length != 4) {
      throw ArgumentError(
          'Se requieren exactamente 4 frames. Se recibieron ${frames.length}.');
    }

    int retries = 0;

    while (retries <= maxRetries) {
      try {
        final requestBody = {
          'images': frames,
          'device_id': 'flutter_app',
          'session_token': sessionToken,
        };

        print('📤 Enviando petición de reconocimiento con:');
        print('   - Frames: ${frames.length}');
        print('   - Device: flutter_app');
        print('   - Session Token: ${sessionToken?.substring(0, 10) ?? "NULL"}...');

        final response = await _httpClient
            .post(
              Uri.parse(
                  '${ApiConfig.baseUrl}${ApiConfig.recognizeAndMarkEndpoint}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException(
                  'El servidor tardó demasiado procesando el reconocimiento'),
            );

        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200) {
          return AttendanceResponse.fromJson(responseData);
        } else if (response.statusCode == 404) {
          // No hay sesión activa o no se reconoció el rostro
          return AttendanceResponse.error(
            responseData['error'] ?? 'Error desconocido',
          );
        } else if (response.statusCode == 400) {
          // Asistencia duplicada
          return AttendanceResponse.error(
            responseData['error'] ?? 'Error desconocido',
          );
        } else {
          return AttendanceResponse.error(
            'Error ${response.statusCode}: ${responseData['error'] ?? responseData['message']}',
          );
        }
      } on TimeoutException {
        retries++;
        if (retries > maxRetries) {
          return AttendanceResponse.error(
            'El servidor no responde. Verifica que esté en línea y que estés conectado a la misma red WiFi.',
          );
        }
      } on SocketException {
        return AttendanceResponse.error(
          'Error de conexión: No se puede conectar al servidor en ${ApiConfig.baseUrl}. Verifica que:\n\n'
          '• El servidor esté funcionando\n'
          '• Estés conectado a la misma red WiFi\n'
          '• La dirección IP sea correcta (${ApiConfig.baseUrl})',
        );
      } on http.ClientException {
        return AttendanceResponse.error(
          'Error de red: No se puede establecer conexión. Verifica tu conexión WiFi.',
        );
      } on FormatException {
        return AttendanceResponse.error(
          'Error al procesar la respuesta del servidor.',
        );
      } catch (e) {
        return AttendanceResponse.error(
          'Error inesperado: ${e.toString()}',
        );
      }
    }

    return AttendanceResponse.error(
        'Error desconocido al registrar asistencia');
  }

  /// Obtiene el historial de asistencias del docente
  /// Retorna [AttendanceHistoryResponse] con la lista de registros
  static Future<AttendanceHistoryResponse> getAttendanceHistory({
    required String emailDocente,
    String? semestre,
    String? corte,
    String? materia,
    int maxRetries = 2,
  }) async {
    int retries = 0;

    while (retries <= maxRetries) {
      try {
        final requestBody = <String, dynamic>{
          'email_docente': emailDocente,
        };

        // Agregar filtros opcionales si están presentes
        if (semestre != null && semestre != 'Todos') {
          requestBody['semestre'] = semestre;
        }
        if (corte != null && corte != 'Todos') {
          requestBody['corte'] = corte;
        }
        if (materia != null && materia != 'Todas') {
          requestBody['materia'] = materia;
        }

        final response = await _httpClient
            .post(
              Uri.parse(
                  '${ApiConfig.baseUrl}${ApiConfig.attendanceHistoryEndpoint}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(
              ApiConfig.connectionTimeout,
              onTimeout: () => throw TimeoutException(
                  'El servidor tardó demasiado en responder'),
            );

        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200) {
          return AttendanceHistoryResponse.fromJson(responseData);
        } else {
          return AttendanceHistoryResponse.error(
            responseData['error'] ?? 'Error al obtener registros',
          );
        }
      } on TimeoutException {
        retries++;
        if (retries > maxRetries) {
          return AttendanceHistoryResponse.error(
            'El servidor no responde. Verifica tu conexión.',
          );
        }
      } on SocketException {
        return AttendanceHistoryResponse.error(
          'Error de conexión: Verifica que estés conectado a la red y que el servidor esté disponible.',
        );
      } on http.ClientException {
        return AttendanceHistoryResponse.error(
          'Error de red: No se puede establecer conexión.',
        );
      } on FormatException {
        return AttendanceHistoryResponse.error(
          'Error al procesar la respuesta del servidor.',
        );
      } catch (e) {
        return AttendanceHistoryResponse.error(
          'Error inesperado: ${e.toString()}',
        );
      }
    }

    return AttendanceHistoryResponse.error(
        'Error al obtener historial de asistencias');
  }

  /// Obtiene los cursos que imparte el docente
  static Future<List<Course>> getTeacherCourses(String sessionToken) async {
    try {
      print('📚 Solicitando cursos del docente...');
      final response = await _httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/teacher/my_courses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_token': sessionToken}),
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📦 Body de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Data decodificada: $data');
        
        // El servidor envía 'cursos' en español, no 'courses'
        final List<dynamic> coursesJson = data['cursos'] ?? data['courses'] ?? [];
        print('📚 Número de cursos: ${coursesJson.length}');
        print('🔍 Cursos JSON: $coursesJson');
        
        final courses = coursesJson.map((json) {
          print('🎯 Parseando curso: $json');
          return Course.fromJson(json);
        }).toList();
        
        print('✨ Cursos parseados: ${courses.length}');
        return courses;
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada o inválida');
      } else {
        throw Exception('Error al obtener cursos: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getTeacherCourses: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Obtiene los estudiantes de un curso específico con sus estadísticas
  /// Opcionalmente filtra por periodo, semestre y corte
  static Future<List<CourseStudent>> getCourseStudents(
    String sessionToken,
    int courseId, {
    int? anio,
    String? semestre,
    int? corte,
  }) async {
    try {
      print('👥 Solicitando estudiantes del curso $courseId...');
      
      // Construir el body con filtros opcionales
      final Map<String, dynamic> requestBody = {
        'session_token': sessionToken,
      };
      
      // Agregar filtros si están presentes
      if (anio != null) requestBody['año'] = anio;
      if (semestre != null) requestBody['semestre'] = semestre;
      if (corte != null) requestBody['corte'] = corte;
      
      print('📦 Enviando filtros: $requestBody');
      
      final response = await _httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/teacher/course/$courseId/students'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta estudiantes - Status: ${response.statusCode}');
      print('📦 Body estudiantes: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Data estudiantes decodificada: $data');
        
        // El servidor puede enviar 'students', 'estudiantes' o 'alumnos'
        final List<dynamic> studentsJson = data['students'] ?? 
                                           data['estudiantes'] ?? 
                                           data['alumnos'] ?? [];
        print('👥 Número de estudiantes: ${studentsJson.length}');
        print('🔍 Estudiantes JSON: $studentsJson');
        
        final students = studentsJson
            .map((json) {
              print('🎯 Parseando estudiante: $json');
              return CourseStudent.fromJson(json);
            })
            .toList();
        
        print('✨ Estudiantes parseados: ${students.length}');
        return students;
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada o inválida');
      } else if (response.statusCode == 404) {
        throw Exception('Curso no encontrado');
      } else {
        throw Exception('Error al obtener estudiantes: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getCourseStudents: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Obtiene el historial completo de asistencia de un estudiante en un curso
  static Future<Map<String, dynamic>> getStudentAttendance(
    String sessionToken,
    int courseId,
    String studentCode,
  ) async {
    try {
      print('📊 Solicitando asistencia del estudiante $studentCode en curso $courseId...');
      final response = await _httpClient.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/teacher/course/$courseId/student/$studentCode/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_token': sessionToken}),
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta asistencia - Status: ${response.statusCode}');
      print('📦 Body asistencia: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Data asistencia decodificada: $data');
        
        // Manejar diferentes formatos de respuesta del servidor
        final attendanceData = data['attendance'] ?? 
                               data['asistencias'] ?? 
                               data['registros'] ?? [];
        
        print('📋 Registros de asistencia: ${attendanceData.runtimeType} - Length: ${attendanceData is List ? attendanceData.length : "N/A"}');
        
        // Asegurar que attendanceData sea una lista
        final List<dynamic> attendanceList = attendanceData is List 
            ? attendanceData 
            : (attendanceData != null ? [attendanceData] : []);
        
        // Calcular resumen si no viene del servidor
        final summary = data['summary'] ?? data['resumen'] ?? {};
        final calculatedSummary = summary.isEmpty && attendanceList.isNotEmpty
            ? _calculateSummary(attendanceList)
            : summary;
        
        return {
          'student': data['student'] ?? data['estudiante'] ?? {},
          'course': data['course'] ?? data['curso'] ?? {},
          'attendance': attendanceList
              .map((json) => AttendanceDetail.fromJson(json))
              .toList(),
          'summary': calculatedSummary,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada o inválida');
      } else if (response.statusCode == 404) {
        throw Exception('Estudiante o curso no encontrado');
      } else {
        throw Exception('Error al obtener asistencia: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getStudentAttendance: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Obtiene solo las ausencias de un estudiante en un curso
  static Future<Map<String, dynamic>> getStudentAbsences(
    String sessionToken,
    int courseId,
    String studentCode,
  ) async {
    try {
      print('📊 Solicitando ausencias del estudiante $studentCode en curso $courseId...');
      final response = await _httpClient.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/teacher/course/$courseId/student/$studentCode/absences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_token': sessionToken}),
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta ausencias - Status: ${response.statusCode}');
      print('📦 Body ausencias: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Data ausencias decodificada: $data');
        
        // Manejar diferentes formatos de respuesta del servidor
        final absencesData = data['absences'] ?? 
                            data['ausencias'] ?? 
                            data['faltas'] ?? [];
        
        print('📋 Registros de ausencias: ${absencesData.runtimeType} - Length: ${absencesData is List ? absencesData.length : "N/A"}');
        
        // Asegurar que absencesData sea una lista
        final List<dynamic> absencesList = absencesData is List 
            ? absencesData 
            : (absencesData != null ? [absencesData] : []);
        
        // Calcular resumen si no viene del servidor
        final summary = data['summary'] ?? data['resumen'] ?? {};
        final calculatedSummary = summary.isEmpty && absencesList.isNotEmpty
            ? _calculateSummary(absencesList)
            : summary;
        
        return {
          'student': data['student'] ?? data['estudiante'] ?? {},
          'course': data['course'] ?? data['curso'] ?? {},
          'absences': absencesList
              .map((json) => AttendanceDetail.fromJson(json))
              .toList(),
          'summary': calculatedSummary,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada o inválida');
      } else if (response.statusCode == 404) {
        throw Exception('Estudiante o curso no encontrado');
      } else {
        throw Exception('Error al obtener ausencias: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getStudentAbsences: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }
  /// Calcula el resumen de asistencias cuando el servidor no lo envía
  static Map<String, dynamic> _calculateSummary(List<dynamic> attendanceList) {
    int presentes = 0;
    int ausentes = 0;
    int tardanzas = 0;
    
    for (var record in attendanceList) {
      final estado = (record['estado'] ?? record['status'] ?? '').toString().toLowerCase();
      
      if (estado == 'presente' || estado == 'present' || estado == 'asistio') {
        presentes++;
      } else if (estado == 'tardanza' || estado == 'tarde' || estado == 'late' || estado == 'retraso') {
        tardanzas++;
      } else if (estado == 'ausente' || estado == 'absent' || estado == 'falta') {
        ausentes++;
      }
    }
    
    // Las tardanzas se consideran asistencias para el porcentaje (llegó aunque tarde)
    final total = presentes + ausentes + tardanzas;
    final asistenciasEfectivas = presentes + tardanzas;
    final porcentajeAsistencia = total > 0 ? (asistenciasEfectivas / total * 100) : 0.0;
    
    return {
      'asistencias': presentes,  // ✅ Usar 'asistencias' para consistencia con frontend
      'presentes': presentes,     // Mantener por compatibilidad
      'ausencias': ausentes,      // ✅ Cambiar 'ausentes' a 'ausencias' para consistencia
      'tardanzas': tardanzas,
      'total_clases': total,
      'porcentaje_asistencia': porcentajeAsistencia,
    };
  }

  /// Obtiene todos los periodos académicos
  /// [anio] - Filtrar por año opcional
  /// [semestre] - Filtrar por semestre opcional (1 o 2)
  /// [estado] - Filtrar por estado opcional (activo, inactivo)
  static Future<List<Periodo>> getPeriodos({
    int? anio,
    String? semestre,
    String? estado,
  }) async {
    try {
      print('📅 Solicitando periodos académicos...');
      
      // Construir query params
      final Map<String, String> queryParams = {};
      if (anio != null) queryParams['año'] = anio.toString();
      if (semestre != null) queryParams['semestre'] = semestre;
      if (estado != null) queryParams['estado'] = estado;
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/periodos')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta periodos - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> periodosJson = data['periodos'] ?? [];
        
        return periodosJson
            .map((json) => Periodo.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener periodos: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getPeriodos: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Obtiene el periodo académico actual
  static Future<PeriodoActual?> getPeriodoActual() async {
    try {
      print('📅 Solicitando periodo actual...');
      
      final response = await _httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/periodo_actual'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta periodo actual - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['periodo_actual'] != null) {
          return PeriodoActual.fromJson(data['periodo_actual']);
        }
        return null;
      } else {
        throw Exception('Error al obtener periodo actual: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getPeriodoActual: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Obtiene asistencias de un estudiante filtradas por corte
  /// [codigoEstudiante] - Código del estudiante (requerido)
  /// [idCurso] - ID del curso opcional
  /// [anio] - Año del periodo opcional
  /// [semestre] - Semestre opcional (1 o 2)
  /// [corte] - Número de corte opcional (1, 2 o 3)
  static Future<List<AsistenciaCorte>> getAsistenciasPorCorte({
    required String codigoEstudiante,
    int? idCurso,
    int? anio,
    String? semestre,
    int? corte,
  }) async {
    try {
      print('📊 Solicitando asistencias por corte para $codigoEstudiante...');
      
      // Construir query params
      final Map<String, String> queryParams = {
        'codigo_estudiante': codigoEstudiante,
      };
      if (idCurso != null) queryParams['id_curso'] = idCurso.toString();
      if (anio != null) queryParams['año'] = anio.toString();
      if (semestre != null) queryParams['semestre'] = semestre;
      if (corte != null) queryParams['corte'] = corte.toString();
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/asistencias_por_corte')
          .replace(queryParameters: queryParams);
      
      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta asistencias por corte - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> asistenciasJson = data['asistencias'] ?? [];
        
        return asistenciasJson
            .map((json) => AsistenciaCorte.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener asistencias por corte: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getAsistenciasPorCorte: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Obtiene estadísticas de asistencia de un estudiante por corte
  /// [codigoEstudiante] - Código del estudiante (requerido)
  /// [idCurso] - ID del curso opcional
  static Future<List<EstadisticasCorte>> getEstadisticasPorCorte({
    required String codigoEstudiante,
    int? idCurso,
  }) async {
    try {
      print('📈 Solicitando estadísticas por corte para $codigoEstudiante...');
      
      // Construir query params
      final Map<String, String> queryParams = {};
      if (idCurso != null) queryParams['id_curso'] = idCurso.toString();
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/estadisticas_por_corte/$codigoEstudiante')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta estadísticas por corte - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> estadisticasJson = data['estadisticas'] ?? [];
        
        return estadisticasJson
            .map((json) => EstadisticasCorte.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener estadísticas por corte: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getEstadisticasPorCorte: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }
}

// Excepciones personalizadas
class ConflictException implements Exception {
  final String message;
  final int existingEmbeddings;

  ConflictException(this.message, {required this.existingEmbeddings});

  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);

  @override
  String toString() => message;
}
