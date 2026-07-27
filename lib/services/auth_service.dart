import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../config/api_config.dart';
import '../models/teacher.dart';
import '../services/api_services.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;

  String? _pendingEmail;

  String? sessionToken;
  Map<String, dynamic>? teacherData;

  /// Iniciar sesión con Google con detección automática de VPN
  Future<AuthResult> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final hasServerAccess = await _checkServerConnectivity();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return AuthResult(
          success: false,
          message: 'Inicio de sesión cancelado',
        );
      }

      _currentUser = account;

      if (!_isInstitutionalEmail(account.email)) {
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message: 'Debes usar tu correo institucional @uceva.edu.co',
        );
      }

      if (!hasServerAccess) {
        _pendingEmail = account.email;
        return AuthResult(
          success: false,
          message: 'VPN_REQUIRED',
          needsVpn: true,
        );
      }

      try {
        final teacher = await _verifyTeacherInDatabase(account.email);

        if (teacher == null) {
          await _googleSignIn.signOut();
          _currentUser = null;
          return AuthResult(
            success: false,
            message:
                'No estás registrado como docente.\nContacta al administrador.',
          );
        }

        _pendingEmail = null;
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
          message:
              'Error de conexión con el servidor.\n\nVerifica tu conexión a internet.',
        );
      }
    } catch (e) {
      await _googleSignIn.signOut();
      _currentUser = null;
      return AuthResult(
        success: false,
        message: 'Error al iniciar sesión: ${e.toString()}',
      );
    }
  }

  Future<bool> _checkServerConnectivity() async {
    try {
      // ✅ Usar el método de ApiService
      final isHealthy = await ApiService.checkServerHealth();
      print('🔍 Servidor saludable: $isHealthy');
      return isHealthy;
    } catch (e) {
      print('❌ Error en checkServerConnectivity: $e');
      return false;
    }
  }

  /// Reintentar verificación después de activar VPN
  Future<AuthResult> retryVerification() async {
    if (_pendingEmail == null) {
      return AuthResult(
        success: false,
        message: 'No hay sesión pendiente de verificación',
      );
    }

    try {
      final hasServerAccess = await _checkServerConnectivity();

      if (!hasServerAccess) {
        return AuthResult(
          success: false,
          message: 'VPN_REQUIRED',
          needsVpn: true,
        );
      }

      final teacher = await _verifyTeacherInDatabase(_pendingEmail!);

      if (teacher == null) {
        await _googleSignIn.signOut();
        _currentUser = null;
        _pendingEmail = null;
        return AuthResult(
          success: false,
          message:
              'No estás registrado como docente.\nContacta al administrador.',
        );
      }

      _pendingEmail = null;
      return AuthResult(
        success: true,
        message: 'Inicio de sesión exitoso',
        teacher: teacher,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error durante la verificación: ${e.toString()}',
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
      final response = await ApiService.httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyTeacherEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'No se pudo conectar al servidor en 30 segundos',
          );
        },
      );

      print('📡 Respuesta verifyTeacher: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['teacher'] != null) {
          sessionToken = data['session_token'];
          teacherData = data['teacher'];
          return Teacher.fromJson(data['teacher']);
        }
      } else if (response.statusCode == 404) {
        print('❌ Docente no encontrado (404)');
        return null;
      } else {
        throw Exception(
            'Error del servidor: ${response.statusCode} - ${response.body}');
      }

      return null;
    } on TimeoutException {
      throw Exception(
          'No se pudo conectar al servidor.\n\nVerifica:\n• Servidor Flask corriendo\n• VPN activa\n• Red conectada');
    } on SocketException {
      throw Exception(
          'Error de conexión: No se puede alcanzar el servidor. ¿Tienes VPN activa?');
    } catch (e) {
      print('❌ Error en _verifyTeacherInDatabase: $e');
      rethrow;
    }
  }

  /// Cerrar sesión y limpiar token de sesión
  Future<void> signOut() async {
    await logoutTeacher();
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Método de logout para invalidar el token en el servidor
  Future<void> logoutTeacher() async {
    if (sessionToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/logout_teacher'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_token': sessionToken}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Timeout en logout');
        },
      );

      if (response.statusCode != 200) {
        // Logout fallido en servidor, continuar limpiando localmente
      }
    } catch (e) {
      // Error silencioso: siempre limpiar sesión local
    } finally {
      sessionToken = null;
      teacherData = null;
    }
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
  final bool needsVpn;

  AuthResult({
    required this.success,
    required this.message,
    this.teacher,
    this.needsVpn = false,
  });
}
