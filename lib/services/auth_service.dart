import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../config/api_config.dart';
import '../models/teacher.dart';

class AuthService {
  // Instancia de Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;

  /// Iniciar sesión con Google
  /// Retorna Teacher si el correo está autorizado, null si no
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Intentar iniciar sesión con Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // Usuario canceló el login
        return AuthResult(
          success: false,
          message: 'Inicio de sesión cancelado',
        );
      }

      _currentUser = account;

      // Verificar que sea correo institucional
      if (!_isInstitutionalEmail(account.email)) {
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message:
              'Debes usar tu correo institucional @uceva.edu.co para acceder',
        );
      }

      // Verificar con el backend que el docente existe en la BD
      Teacher? teacher;
      try {
        teacher = await _verifyTeacherInDatabase(account.email);
      } catch (e) {
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message:
              'Error de conexión con el servidor:\n\n$e\n\nVerifica que tengas VPN activa.',
        );
      }

      if (teacher == null) {
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message:
              'No estás registrado como docente en el sistema.\nContacta al administrador.',
        );
      }

      return AuthResult(
        success: true,
        message: 'Inicio de sesión exitoso',
        teacher: teacher,
      );
    } catch (e) {
      await _googleSignIn.signOut();
      _currentUser = null;
      return AuthResult(
        success: false,
        message: 'Error al iniciar sesión: ${e.toString()}',
      );
    }
  }

  /// Verificar si el correo es institucional
  bool _isInstitutionalEmail(String email) {
    return email.toLowerCase().endsWith('@uceva.edu.co');
  }

  /// Verificar que el docente existe en la base de datos
  /// Consulta el endpoint del backend que verifica la tabla "docentes"
  Future<Teacher?> _verifyTeacherInDatabase(String email) async {
    try {
      print(
          '🔵 Intentando conectar a: ${ApiConfig.baseUrl}${ApiConfig.verifyTeacherEndpoint}');
      print('🔵 Email: $email');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyTeacherEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      print('🟢 Respuesta del servidor - Código: ${response.statusCode}');
      print('🟢 Respuesta del servidor - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Si el docente existe, crear objeto Teacher
        if (data['success'] == true && data['teacher'] != null) {
          print('✅ Docente encontrado en la base de datos');
          return Teacher.fromJson(data['teacher']);
        } else {
          print(
              '❌ Respuesta exitosa pero docente no encontrado en la respuesta');
        }
      } else if (response.statusCode == 404) {
        print('❌ Docente no encontrado (404)');
        return null;
      } else {
        print('⚠️ Respuesta inesperada del servidor: ${response.statusCode}');
        throw Exception(
            'Error del servidor: ${response.statusCode} - ${response.body}');
      }

      return null;
    } on TimeoutException catch (e) {
      print('⏱️ TIMEOUT: No se pudo conectar al servidor en 10 segundos');
      print(
          '⏱️ Verifica que el servidor esté corriendo y que tengas conexión VPN');
      throw Exception(
          'Timeout: No se pudo conectar al servidor. Verifica tu conexión VPN.');
    } on SocketException catch (e) {
      print('🔴 ERROR DE RED: $e');
      throw Exception(
          'Error de conexión: No se puede alcanzar el servidor. ¿Tienes VPN activa?');
    } catch (e) {
      print('🔴 ERROR GENERAL al verificar docente: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Verificar si hay una sesión activa
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Intentar iniciar sesión silenciosamente (si ya hay sesión guardada)
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser;
    } catch (e) {
      return null;
    }
  }
}

/// Clase para representar el resultado de la autenticación
class AuthResult {
  final bool success;
  final String message;
  final Teacher? teacher;

  AuthResult({
    required this.success,
    required this.message,
    this.teacher,
  });
}
