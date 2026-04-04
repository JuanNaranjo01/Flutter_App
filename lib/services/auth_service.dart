import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../config/api_config.dart';
import '../models/teacher.dart';
import '../models/student.dart';

class AuthService {
  // Instancia de Google Sign In
  // NOTA: serverClientId removido temporalmente debido a ApiException: 7
  // Para usarlo, debes configurar OAuth Consent Screen en Google Cloud Console
  // Ver SOLUCION_GOOGLE_SIGNIN.md para instrucciones completas
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;

  String? _pendingEmail;

  // Variables globales para gestión de token de sesión
  String? sessionToken;
  Map<String, dynamic>? teacherData;
  Map<String, dynamic>? studentData;

  /// Iniciar sesión con Google con detección automática de VPN
  Future<AuthResult> signInWithGoogle() async {
    print('🔷 Iniciando login con detección automática...');
    try {
      // 1. Cerrar sesión previa para forzar selección de cuenta
      await _googleSignIn.signOut();
      print('🔷 Sesión previa cerrada - Se mostrará selector de cuenta');

      // 2. Verificar si tenemos acceso al servidor ANTES de Google Sign-In
      print('🔷 Verificando acceso al servidor...');
      final hasServerAccess = await _checkServerConnectivity();
      print(hasServerAccess
          ? '✅ Servidor accesible'
          : '⚠️ Servidor no accesible');

      // 3. Iniciar sesión con Google (ahora siempre preguntará)
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        print('❌ Usuario canceló el login');
        return AuthResult(
          success: false,
          message: 'Inicio de sesión cancelado',
        );
      }

      print('✅ Google Sign-In exitoso: ${account.email}');
      _currentUser = account;

      // 3. Verificar correo institucional
      if (!_isInstitutionalEmail(account.email)) {
        print('❌ No es correo institucional');
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message: 'Debes usar tu correo institucional @uceva.edu.co',
        );
      }

      print('✅ Email institucional válido');

      // 4. Si NO hay acceso al servidor, guardar email y pedir VPN
      if (!hasServerAccess) {
        print('⚠️ Sin acceso al servidor - Se requiere VPN');
        _pendingEmail = account.email;
        return AuthResult(
          success: false,
          message: 'VPN_REQUIRED',
          needsVpn: true,
        );
      }

      // 5. Si hay acceso, verificar directamente
      print('🔷 Verificando docente en base de datos...');
      try {
        final teacher = await _verifyTeacherInDatabase(account.email);

        if (teacher == null) {
          print('❌ Docente no encontrado en BD');
          await _googleSignIn.signOut();
          _currentUser = null;
          return AuthResult(
            success: false,
            message:
                'No estás registrado como docente.\nContacta al administrador.',
          );
        }

        print('✅✅✅ LOGIN EXITOSO: ${teacher.nombre}');
        _pendingEmail = null; // Limpiar
        return AuthResult(
          success: true,
          message: 'Inicio de sesión exitoso',
          teacher: teacher,
        );
      } catch (e) {
        print('❌ Error al verificar con servidor: $e');
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message:
              'Error de conexión con el servidor.\n\nVerifica tu conexión a internet.',
        );
      }
    } catch (e) {
      print('❌ ERROR EN SIGNIN: $e');
      await _googleSignIn.signOut();
      _currentUser = null;
      return AuthResult(
        success: false,
        message: 'Error al iniciar sesión: ${e.toString()}',
      );
    }
  }

  /// Iniciar sesión como estudiante con Google
  Future<AuthResult> signInAsStudent() async {
    print('🔷 Iniciando login de estudiante con detección automática...');
    try {
      // 1. Cerrar sesión previa para forzar selección de cuenta
      await _googleSignIn.signOut();
      print('🔷 Sesión previa cerrada - Se mostrará selector de cuenta');

      // 2. Verificar si tenemos acceso al servidor ANTES de Google Sign-In
      print('🔷 Verificando acceso al servidor...');
      final hasServerAccess = await _checkServerConnectivity();
      print(hasServerAccess
          ? '✅ Servidor accesible'
          : '⚠️ Servidor no accesible');

      // 3. Iniciar sesión con Google (ahora siempre preguntará)
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        print('❌ Usuario canceló el login');
        return AuthResult(
          success: false,
          message: 'Inicio de sesión cancelado',
        );
      }

      print('✅ Google Sign-In exitoso: ${account.email}');
      _currentUser = account;

      // 3. Verificar correo institucional
      if (!_isInstitutionalEmail(account.email)) {
        print('❌ No es correo institucional');
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message: 'Debes usar tu correo institucional @uceva.edu.co',
        );
      }

      print('✅ Email institucional válido');

      // 4. Si NO hay acceso al servidor, guardar email y pedir VPN
      if (!hasServerAccess) {
        print('⚠️ Sin acceso al servidor - Se requiere VPN');
        _pendingEmail = account.email;
        return AuthResult(
          success: false,
          message: 'VPN_REQUIRED',
          needsVpn: true,
        );
      }

      // 5. Si hay acceso, verificar directamente
      print('🔷 Verificando estudiante en base de datos...');
      try {
        final student = await _verifyStudentInDatabase(account.email);

        if (student == null) {
          print('❌ Estudiante no encontrado en BD');
          await _googleSignIn.signOut();
          _currentUser = null;
          return AuthResult(
            success: false,
            message:
                'No estás registrado como estudiante.\nContacta al administrador.',
          );
        }

        print('✅✅✅ LOGIN ESTUDIANTE EXITOSO: ${student.nombreCompleto}');
        _pendingEmail = null; // Limpiar
        return AuthResult(
          success: true,
          message: 'Inicio de sesión exitoso',
          student: student,
        );
      } catch (e) {
        print('❌ Error al verificar con servidor: $e');
        await _googleSignIn.signOut();
        _currentUser = null;
        return AuthResult(
          success: false,
          message:
              'Error de conexión con el servidor.\n\nVerifica tu conexión a internet.',
        );
      }
    } catch (e) {
      print('❌ ERROR EN SIGNIN ESTUDIANTE: $e');
      await _googleSignIn.signOut();
      _currentUser = null;
      return AuthResult(
        success: false,
        message: 'Error al iniciar sesión: ${e.toString()}',
      );
    }
  }

  /// Verificar si el servidor está accesible (detecta si necesita VPN)
  Future<bool> _checkServerConnectivity() async {
    try {
      print('🔵 Probando conectividad a: ${ApiConfig.baseUrl}');
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/health'))
          .timeout(const Duration(seconds: 5));
      print('🟢 Servidor respondió: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('🔴 Servidor no accesible: $e');
      return false; // No hay acceso al servidor
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

    print('🔷 Reintentando verificación para: $_pendingEmail');

    try {
      // Verificar conectividad nuevamente
      final hasServerAccess = await _checkServerConnectivity();

      if (!hasServerAccess) {
        print('⚠️ Servidor aún no accesible');
        return AuthResult(
          success: false,
          message: 'VPN_REQUIRED',
          needsVpn: true,
        );
      }

      print('✅ Servidor accesible - Verificando docente...');
      // Verificar en el servidor
      final teacher = await _verifyTeacherInDatabase(_pendingEmail!);

      if (teacher == null) {
        print('❌ Docente no encontrado en BD');
        await _googleSignIn.signOut();
        _currentUser = null;
        _pendingEmail = null;
        return AuthResult(
          success: false,
          message:
              'No estás registrado como docente.\nContacta al administrador.',
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
      print('❌ Error durante la verificación: $e');
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
          
          // ✅ GUARDAR TOKEN Y DATOS DEL PROFESOR
          sessionToken = data['session_token'];
          teacherData = data['teacher'];
          
          if (sessionToken != null) {
            print('✅ Token de sesión guardado: ${sessionToken!.substring(0, 10)}...');
            print('✅ Token expira en: ${data['token_expires_in_hours']} horas');
          }
          
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

  /// Verificar que el estudiante existe en la base de datos
  /// Consulta el endpoint del backend que verifica la tabla "estudiantes"
  Future<Student?> _verifyStudentInDatabase(String email) async {
    try {
      print(
          '🔵 Intentando conectar a: ${ApiConfig.baseUrl}/api/verify_student');
      print('🔵 Email: $email');

      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/api/verify_student'),
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

        // Si el estudiante existe, crear objeto Student
        if (data['success'] == true && data['student'] != null) {
          print('✅ Estudiante encontrado en la base de datos');
          
          // ✅ GUARDAR TOKEN Y DATOS DEL ESTUDIANTE
          sessionToken = data['session_token'];
          studentData = data['student'];
          
          if (sessionToken != null) {
            print('✅ Token de sesión guardado: ${sessionToken!.substring(0, 10)}...');
            print('✅ Token expira en: ${data['token_expires_in_hours']} horas');
          }
          
          return Student.fromJson(data['student']);
        } else {
          print(
              '❌ Respuesta exitosa pero estudiante no encontrado en la respuesta');
        }
      } else if (response.statusCode == 404) {
        print('❌ Estudiante no encontrado (404)');
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
          '⏱️ URL intentada: ${ApiConfig.baseUrl}/api/verify_student');
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
      print('🔴 ERROR GENERAL al verificar estudiante: $e');
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
    if (sessionToken == null) {
      print('⚠️ No hay token de sesión para invalidar');
      return;
    }

    try {
      print('🔷 Invalidando token de sesión en el servidor...');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/logout_teacher'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_token': sessionToken}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Timeout al hacer logout - Limpiando sesión local de todos modos');
          throw TimeoutException('Timeout en logout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Logout exitoso: ${data['message']}');
      } else {
        print('⚠️ Error en logout del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error al hacer logout en servidor: $e');
    } finally {
      // Limpiar sesión local siempre
      sessionToken = null;
      teacherData = null;
      print('✅ Sesión local limpiada');
    }
  }

  /// Método de logout para invalidar el token en el servidor (estudiante)
  Future<void> logoutStudent() async {
    if (sessionToken == null) {
      print('⚠️ No hay token de sesión para invalidar');
      return;
    }

    try {
      print('🔷 Invalidando token de sesión de estudiante en el servidor...');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/logout_student'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_token': sessionToken}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Timeout al hacer logout de estudiante - Limpiando sesión local de todos modos');
          throw TimeoutException('Timeout en logout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Logout estudiante exitoso: ${data['message']}');
      } else {
        print('⚠️ Error en logout del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error al hacer logout de estudiante en servidor: $e');
    } finally {
      // Limpiar sesión local siempre
      sessionToken = null;
      studentData = null;
      print('✅ Sesión estudiante local limpiada');
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
  final Student? student;
  final bool needsVpn;

  AuthResult({
    required this.success,
    required this.message,
    this.teacher,
    this.student,
    this.needsVpn = false,
  });
}
