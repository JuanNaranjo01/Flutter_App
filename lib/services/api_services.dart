import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/student.dart';

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
          throw SocketException(
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

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}

class SocketException implements Exception {
  final String message;

  SocketException(this.message);

  @override
  String toString() => message;
}
