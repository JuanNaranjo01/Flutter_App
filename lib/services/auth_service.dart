import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../config/api_config.dart';
import '../models/teacher.dart';

class AuthService {
  // Instancia de Google Sign In
  // NOTA: serverClientId removido temporalmente debido a ApiException: 7
  // Para usarlo, debes configurar OAuth Consent Screen en Google Cloud Console
  // Ver SOLUCION_GOOGLE_SIGNIN.md para instrucciones completas
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  GoogleSignInAccount? _currentUser;
  String? _pendingEmail; // Email pendiente de verificación

  GoogleSignInAccount? get currentUser => _currentUser;

  /// PASO 1: Iniciar sesión con Google (SIN VPN)
  /// Solo obtiene el email del usuario, NO verifica con el servidor
  Future<AuthResult> signInWithGoogle() async {
    print('🔷 PASO 1: Iniciando Google Sign-In (sin VPN)');
    try {
      // Intentar iniciar sesión con Google
      print('🔷 Llamando a _googleSignIn.signIn()...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // Usuario canceló el login
        print('❌ Usuario canceló el login');
        return AuthResult(
          success: false,
          message: 'Inicio de sesión cancelado',
        );
      }

      print('✅ Google Sign-In exitoso: ${account.email}');
      _currentUser = account;

      // Verificar que sea correo institucional
      print('🔷 Verificando si es correo institucional: ${account.email}');
      if (!_isInstitutionalEmail(account.email)) {
        print('❌ No es correo institucional');
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message:
              'Debes usar tu correo institucional @uceva.edu.co para acceder',
        );
      }
      print('✅ Es correo institucional válido');

      // Guardar email para verificar en el paso 2
      _pendingEmail = account.email;

      // Retornar éxito parcial - necesita verificación con servidor
      return AuthResult(
        success: false, // false porque aún falta verificar con servidor
        message: 'PENDING_VERIFICATION', // Código especial
        pendingEmail: account.email,
      );
    } catch (e) {
      print('❌❌❌ ERROR EN GOOGLE SIGNIN: $e');
      await _googleSignIn.signOut();
      _currentUser = null;
      return AuthResult(
        success: false,
        message: 'Error al iniciar sesión con Google: ${e.toString()}',
      );
    }
  }

  /// PASO 2: Verificar con el servidor (CON VPN)
  /// Debe llamarse después de signInWithGoogle(), cuando VPN esté activa
  Future<AuthResult> verifyWithServer() async {
    print('🔷 PASO 2: Verificando con servidor (con VPN)');
    
    if (_pendingEmail == null || _currentUser == null) {
      return AuthResult(
        success: false,
        message: 'Error: Debes iniciar sesión con Google primero',
      );
    }

    try {
      // Verificar con el backend que el docente existe en la BD
      print('🔷 Verificando docente en base de datos...');
      Teacher? teacher = await _verifyTeacherInDatabase(_pendingEmail!);
      print('🔷 Resultado de verificación: ${teacher != null ? "Encontrado" : "No encontrado"}');

      if (teacher == null) {
        print('❌ Docente no encontrado en la BD');
        await _googleSignIn.signOut();
        _currentUser = null;
        _pendingEmail = null;
        return AuthResult(
          success: false,
          message:
              'No estás registrado como docente en el sistema.\nContacta al administrador.',
        );
      }

      print('✅✅✅ VERIFICACIÓN EXITOSA: ${teacher.nombre}');
      _pendingEmail = null; // Limpiar email pendiente
      return AuthResult(
        success: true,
        message: 'Inicio de sesión exitoso',
        teacher: teacher,
      );
    } catch (e) {
      print('❌ Error al verificar con servidor: $e');
      // NO cerramos la sesión de Google aquí, solo informamos el error
      return AuthResult(
        success: false,
        message: 'Error de conexión con el servidor:\n\n$e\n\nVerifica que tengas VPN activa y el servidor corriendo.',
        requiresRetry: true, // Indicador de que puede reintentar
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
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'No se pudo conectar al servidor en 30 segundos',
          );
        },
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
    } on TimeoutException {
      print('⏱️ TIMEOUT: No se pudo conectar al servidor en 30 segundos');
      print(
          '⏱️ URL intentada: ${ApiConfig.baseUrl}${ApiConfig.verifyTeacherEndpoint}');
      print('⏱️ Verifica:');
      print('   1. Servidor Flask esté corriendo en ${ApiConfig.baseUrl}');
      print('   2. VPN o conexión de red activa');
      print('   3. Firewall no bloquee el puerto 5000');
      throw Exception(
          'No se pudo conectar al servidor.\n\nVerifica:\n• Servidor Flask corriendo\n• VPN activa\n• Red conectada');
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
  final String? pendingEmail; // Email que necesita verificación
  final bool requiresRetry; // Indica si se puede reintentar

  AuthResult({
    required this.success,
    required this.message,
    this.teacher,
    this.pendingEmail,
    this.requiresRetry = false,
  });
}
