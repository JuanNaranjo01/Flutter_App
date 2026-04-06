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
import '../models/reporte_estudiante.dart';
import '../models/resumen_estudiante.dart';
import '../models/estudiante_en_riesgo.dart';
import '../models/reporte_docente.dart';
import '../models/calculo_horas.dart';

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

        // TEMP_DEBUG_START: retirar este bloque cuando se valide en QA
        print('📥 Respuesta registro asistencia: status=${response.statusCode}');
        print('📦 Body registro asistencia: ${response.body}');
        // TEMP_DEBUG_END

        if (response.statusCode == 200) {
          return AttendanceResponse.fromJson(responseData);
        } else if (response.statusCode == 404) {
          final errorMessage = (responseData['error'] ??
                  responseData['message'] ??
                  'No se pudo registrar la asistencia')
              .toString();
          return AttendanceResponse.error(
            errorMessage,
          );
        } else if (response.statusCode == 400) {
          final rawError = (responseData['error'] ??
                  responseData['message'] ??
                  'Solicitud inválida')
              .toString();
          final lowerError = rawError.toLowerCase();

          if (lowerError.contains('rostro') ||
              lowerError.contains('face') ||
              lowerError.contains('no se detect')) {
            return AttendanceResponse.error(
              'No se detectó un rostro válido. Intenta acercarte a la cámara, mejorar la iluminación y evitar movimientos bruscos.',
            );
          }

          return AttendanceResponse.error(
            rawError,
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

  /// ✅ NUEVO: Obtiene los estudiantes de un curso con estadísticas de asistencia
  /// Usa el endpoint: POST /api/flutter/curso/{id}/estudiantes
  /// Documentado en: GUIA_RAPIDA_FRONTEND.md y PARA_FRONTEND_README.md
  /// 
  /// FILTROS OPCIONALES:
  /// - Sin filtros: Muestra periodo actual automáticamente
  /// - [anio] + [semestre]: Filtra estudiantes de ese periodo
  /// - [corte]: Filtra por corte específico (requiere año y semestre)
  /// - [fecha]: Muestra solo asistencias de esa fecha exacta (formato: 'YYYY-MM-DD')
  static Future<List<CourseStudent>> getCourseStudents(
    String sessionToken,
    int courseId, {
    int? anio,
    String? semestre,
    int? corte,
    String? fecha,
  }) async {
    try {
      print('👥 Solicitando estudiantes del curso $courseId (Endpoint Flutter)...');
      
      // Construir el body con filtros opcionales
      final Map<String, dynamic> requestBody = {
        'session_token': sessionToken,
      };
      
      // Agregar filtros si están presentes
      if (anio != null) requestBody['año'] = anio;
      if (semestre != null) requestBody['semestre'] = semestre;
      if (corte != null) requestBody['corte'] = corte;
      if (fecha != null) requestBody['fecha'] = fecha;
      
      print('📦 Enviando filtros: $requestBody');
      
      // ✅ NUEVO ENDPOINT: /api/flutter/curso/{id}/estudiantes
      final response = await _httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/flutter/curso/$courseId/estudiantes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta estudiantes - Status: ${response.statusCode}');
      print('📦 Body estudiantes: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Data estudiantes decodificada: $data');
        
        // ✅ El nuevo endpoint envía 'estudiantes' (estructura documentada)
        final List<dynamic> studentsJson = data['estudiantes'] ?? data['students'] ?? [];
        print('👥 Número de estudiantes: ${studentsJson.length}');
        
        // 🔍 DEBUG: Verificar primer estudiante para ver estructura
        if (studentsJson.isNotEmpty) {
          print('🔍 DEBUG Primer estudiante completo: ${studentsJson[0]}');
          final firstStats = studentsJson[0]['estadisticas'] ?? {};
          print('🔍 DEBUG Estadísticas del primero: $firstStats');
          print('🔍 DEBUG Claves disponibles: ${firstStats.keys.toList()}');
        }
        
        final students = studentsJson
            .map((json) {
              return CourseStudent.fromJson(json);
            })
            .toList();
        
        print('✨ Estudiantes parseados: ${students.length}');
        return students;
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada o inválida');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes acceso a este curso');
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

  /// ✅ NUEVO: Obtiene el historial COMPLETO de asistencia de un estudiante
  /// Usa el endpoint: POST /api/flutter/curso/{id}/estudiante/{codigo}/detalle
  /// Documentado en: GUIA_RAPIDA_FRONTEND.md y PARA_FRONTEND_README.md
  /// 
  /// Incluye: TODOS los registros (presentes, tardanzas y ausencias)
  /// FILTROS OPCIONALES: año, semestre, corte, fecha
  static Future<Map<String, dynamic>> getStudentAttendance(
    String sessionToken,
    int courseId,
    String studentCode, {
    int? anio,
    String? semestre,
    int? corte,
    String? fecha,
  }) async {
    try {
      print('📊 Solicitando detalle del estudiante $studentCode en curso $courseId (Endpoint Flutter)...');
      
      // Construir el body con filtros opcionales
      final Map<String, dynamic> requestBody = {
        'session_token': sessionToken,
      };
      
      // Agregar filtros si están presentes
      if (anio != null) requestBody['año'] = anio;
      if (semestre != null) requestBody['semestre'] = semestre;
      if (corte != null) requestBody['corte'] = corte;
      if (fecha != null) requestBody['fecha'] = fecha;
      
      print('📦 Enviando filtros: $requestBody');
      
      // ✅ NUEVO ENDPOINT: /api/flutter/curso/{id}/estudiante/{codigo}/detalle
      final response = await _httpClient.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/flutter/curso/$courseId/estudiante/$studentCode/detalle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta detalle - Status: ${response.statusCode}');
      print('📦 Body detalle: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Data detalle decodificada: $data');
        
        // ✅ El nuevo endpoint envía 'asistencias' (estructura documentada)
        final attendanceData = data['asistencias'] ?? [];
        
        print('📋 Registros de asistencia: ${attendanceData.runtimeType} - Length: ${attendanceData is List ? attendanceData.length : "N/A"}');
        
        // Asegurar que attendanceData sea una lista
        final List<dynamic> attendanceList = attendanceData is List 
            ? attendanceData 
            : (attendanceData != null ? [attendanceData] : []);
        
        // El backend siempre envía el resumen calculado
        final summary = data['resumen'] ?? {};
        
        return {
          'student': data['estudiante'] ?? {},
          'attendance': attendanceList
              .map((json) => AttendanceDetail.fromJson(json))
              .toList(),
          'summary': summary,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada o inválida');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes acceso a este curso');
      } else if (response.statusCode == 404) {
        throw Exception('Estudiante o curso no encontrado');
      } else {
        throw Exception('Error al obtener detalle: ${response.statusCode}');
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

  /// ✅ NUEVO: Obtiene SOLO LAS FALTAS (tardanzas + ausencias) de un estudiante
  /// Usa el endpoint: POST /api/flutter/curso/{id}/estudiante/{codigo}/faltas
  /// Documentado en: GUIA_RAPIDA_FRONTEND.md y PARA_FRONTEND_README.md
  /// 
  /// Incluye: SOLO tardanzas y ausencias (NO incluye presentes)
  /// FILTROS OPCIONALES: año, semestre, corte, fecha
  static Future<Map<String, dynamic>> getStudentAbsences(
    String sessionToken,
    int courseId,
    String studentCode, {
    int? anio,
    String? semestre,
    int? corte,
    String? fecha,
  }) async {
    try {
      print('📊 Solicitando faltas del estudiante $studentCode en curso $courseId (Endpoint Flutter)...');
      
      // Construir el body con filtros opcionales
      final Map<String, dynamic> requestBody = {
        'session_token': sessionToken,
      };
      
      // Agregar filtros si están presentes
      if (anio != null) requestBody['año'] = anio;
      if (semestre != null) requestBody['semestre'] = semestre;
      if (corte != null) requestBody['corte'] = corte;
      if (fecha != null) requestBody['fecha'] = fecha;
      
      print('📦 Enviando filtros: $requestBody');
      
      // ✅ NUEVO ENDPOINT: /api/flutter/curso/{id}/estudiante/{codigo}/faltas
      final response = await _httpClient.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/flutter/curso/$courseId/estudiante/$studentCode/faltas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta faltas - Status: ${response.statusCode}');
      print('📦 Body faltas: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Data faltas decodificada: $data');
        
        // ✅ El nuevo endpoint envía 'faltas' (estructura documentada)
        final absencesData = data['faltas'] ?? [];
        
        print('📋 Registros de faltas: ${absencesData.runtimeType} - Length: ${absencesData is List ? absencesData.length : "N/A"}');
        
        // Asegurar que absencesData sea una lista
        final List<dynamic> absencesList = absencesData is List 
            ? absencesData 
            : (absencesData != null ? [absencesData] : []);
        
        // El backend siempre envía el resumen calculado
        final summary = data['resumen'] ?? {};
        
        return {
          'student': data['estudiante'] ?? {},
          'absences': absencesList
              .map((json) => AttendanceDetail.fromJson(json))
              .toList(),
          'summary': summary,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada o inválida');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes acceso a este curso');
      } else if (response.statusCode == 404) {
        throw Exception('Estudiante o curso no encontrado');
      } else {
        throw Exception('Error al obtener faltas: ${response.statusCode}');
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

  /// ✅ NUEVO: Diagnóstico de la base de datos (Endpoint Flutter - Opcional)
  /// Usa el endpoint: GET /api/flutter/diagnostico-bd
  /// Documentado en: GUIA_RAPIDA_FRONTEND.md y PARA_FRONTEND_README.md
  /// 
  /// IMPORTANTE: NO requiere autenticación (es solo para debugging)
  /// Útil para verificar el estado de la BD antes de usar los otros endpoints
  static Future<Map<String, dynamic>> getDiagnosticoBD() async {
    try {
      print('🔍 Solicitando diagnóstico de BD (Endpoint Flutter)...');
      
      final response = await _httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.flutterDiagnosticEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta diagnóstico - Status: ${response.statusCode}');
      print('📦 Body diagnóstico: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Diagnóstico completado: $data');
        
        // Revisar si hay warnings
        final warnings = data['warnings'];
        if (warnings != null && warnings.toString().isNotEmpty && warnings != 'null') {
          print('⚠️ ADVERTENCIAS EN BD: $warnings');
        } else {
          print('✅ BD sin problemas');
        }
        
        // ✅ NUEVO (27/02/2026): Log de periodos disponibles
        if (data.containsKey('periodos_disponibles')) {
          final periodos = data['periodos_disponibles'] as List;
          print('📅 Periodos disponibles: ${periodos.length}');
        }
        
        return data;
      } else {
        throw Exception('Error en diagnóstico: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getDiagnosticoBD: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// ✅ NUEVO (27/02/2026): Obtiene periodos disponibles desde el diagnóstico
  /// Útil para construir selectores de periodo/corte con fechas correctas
  static Future<List<Periodo>> getPeriodosDisponibles() async {
    try {
      print('📅 Solicitando periodos disponibles desde diagnóstico...');
      
      final diagnostico = await getDiagnosticoBD();
      
      if (diagnostico.containsKey('periodos_disponibles')) {
        final periodosJson = diagnostico['periodos_disponibles'] as List;
        final periodos = periodosJson
            .map((json) => Periodo.fromJson(json))
            .toList();
        
        print('✅ ${periodos.length} periodo(s) disponible(s)');
        return periodos;
      } else {
        print('⚠️ No se encontró "periodos_disponibles" en el diagnóstico');
        return [];
      }
    } catch (e) {
      print('❌ Error obteniendo periodos disponibles: $e');
      throw Exception('Error: ${e.toString()}');
    }
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

  // ========================================
  // 📡 NUEVOS ENDPOINTS DE REPORTES
  // ========================================

  /// 1️⃣ Reporte Detallado de Estudiante
  /// GET /api/reportes/estudiante/{codigo_estudiante}
  /// Query params opcionales: id_curso, id_periodo
  static Future<ReporteEstudiante> getReporteEstudiante(
    String codigoEstudiante, {
    int? idCurso,
    int? idPeriodo,
  }) async {
    try {
      print('📊 Solicitando reporte detallado del estudiante $codigoEstudiante...');
      
      // Construir query params
      final Map<String, String> queryParams = {};
      if (idCurso != null) queryParams['id_curso'] = idCurso.toString();
      if (idPeriodo != null) queryParams['id_periodo'] = idPeriodo.toString();
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/reportes/estudiante/$codigoEstudiante')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Respuesta reporte estudiante - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReporteEstudiante.fromJson(data);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Estudiante no encontrado');
      } else {
        throw Exception('Error al obtener reporte: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getReporteEstudiante: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// 2️⃣ Resumen Ejecutivo de Estudiante
  /// GET /api/reportes/estudiante/{codigo_estudiante}/resumen
  static Future<ResumenEstudiante> getResumenEstudiante(
    String codigoEstudiante,
  ) async {
    try {
      print('📊 Solicitando resumen ejecutivo del estudiante $codigoEstudiante...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/reportes/estudiante/$codigoEstudiante/resumen');
      
      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Respuesta resumen estudiante - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResumenEstudiante.fromJson(data);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Estudiante no encontrado');
      } else {
        throw Exception('Error al obtener resumen: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getResumenEstudiante: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// 3️⃣ Estudiantes en Riesgo (≥20% de fallas)
  /// GET /api/reportes/estudiantes-en-riesgo
  /// Query params opcionales: id_periodo, corte, id_curso
  static Future<EstudiantesEnRiesgoResponse> getEstudiantesEnRiesgo({
    int? idPeriodo,
    int? corte,
    int? idCurso,
  }) async {
    try {
      print('⚠️ Solicitando estudiantes en riesgo...');
      
      // Construir query params
      final Map<String, String> queryParams = {};
      if (idPeriodo != null) queryParams['id_periodo'] = idPeriodo.toString();
      if (corte != null) queryParams['corte'] = corte.toString();
      if (idCurso != null) queryParams['id_curso'] = idCurso.toString();
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/reportes/estudiantes-en-riesgo')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Respuesta estudiantes en riesgo - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EstudiantesEnRiesgoResponse.fromJson(data);
      } else {
        throw Exception('Error al obtener estudiantes en riesgo: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getEstudiantesEnRiesgo: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// 4️⃣ Reporte para Docente
  /// GET /api/reportes/docente/{correo_docente}
  static Future<ReporteDocente> getReporteDocente(
    String correoDocente,
  ) async {
    try {
      print('👨‍🏫 Solicitando reporte del docente $correoDocente...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/reportes/docente/$correoDocente');
      
      final response = await _httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Respuesta reporte docente - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReporteDocente.fromJson(data);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Docente no encontrado');
      } else {
        throw Exception('Error al obtener reporte docente: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en getReporteDocente: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// 5️⃣ Calcular Horas (Herramienta)
  /// POST /api/calculos/horas-faltadas
  static Future<CalculoHorasResponse> calcularHorasFaltadas({
    required double horasAusencias,
    required int minutosTardanza,
  }) async {
    try {
      print('🧮 Calculando horas faltadas...');
      
      final request = CalculoHorasRequest(
        horasAusencias: horasAusencias,
        minutosTardanza: minutosTardanza,
      );
      
      final response = await _httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/calculos/horas-faltadas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      print('📡 Respuesta cálculo horas - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CalculoHorasResponse.fromJson(data);
      } else {
        throw Exception('Error al calcular horas: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado.');
    } catch (e) {
      print('❌ Error en calcularHorasFaltadas: $e');
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
