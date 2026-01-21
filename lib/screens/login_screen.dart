import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  bool _showingVerificationDialog = false;

  @override
  void dispose() {
    super.dispose();
  }

  /// Manejar el login completo (Google + Verificación)
  Future<void> _handleGoogleLogin() async {
    print('🟢 Iniciando proceso de login...');
    setState(() => _isLoading = true);

    try {
      // PASO 1: Google Sign-In
      print('🟢 PASO 1: Google Sign-In');
      final googleResult = await _authService.signInWithGoogle();

      if (!mounted) return;

      // Si canceló o error
      if (!googleResult.success &&
          googleResult.message != 'NEEDS_SERVER_VERIFICATION') {
        setState(() => _isLoading = false);
        _showError(googleResult.message);
        return;
      }

      // Si Google Sign-In exitoso, intentar verificar automáticamente
      if (googleResult.message == 'NEEDS_SERVER_VERIFICATION') {
        print(
            '🟢 Google Sign-In exitoso, intentando verificación automática...');

        // Intentar verificar automáticamente (funciona si están en la universidad)
        final verifyResult = await _authService.verifyTeacherWithServer();

        if (!mounted) return;

        setState(() => _isLoading = false);

        if (verifyResult.success && verifyResult.teacher != null) {
          // ✅ Verificación automática exitosa (están en la universidad)
          print('✅ Verificación automática exitosa');
          final dataProvider =
              Provider.of<DataProvider>(context, listen: false);
          dataProvider.loginWithTeacher(verifyResult.teacher!);
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // ❌ Verificación falló - mostrar diálogo para activar VPN
          print('❌ Verificación automática falló, mostrando diálogo VPN');
          await _showServerVerificationDialog(googleResult.pendingEmail!);
        }
      }
    } catch (e) {
      print('❌ Error en _handleGoogleLogin: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error inesperado: ${e.toString()}');
      }
    }
  }

  /// Verificar con el servidor
  Future<void> _verifyWithServer() async {
    print('🟢 PASO 2: Verificando con servidor...');
    setState(() => _isLoading = true);

    try {
      final result = await _authService.verifyTeacherWithServer();

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.success && result.teacher != null) {
        // Login exitoso - cerrar diálogo y navegar
        if (_showingVerificationDialog) {
          Navigator.of(context).pop();
          _showingVerificationDialog = false;
        }

        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        dataProvider.loginWithTeacher(result.teacher!);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Error de verificación - mostrar y permitir reintentar
        _showError(result.message);
      }
    } catch (e) {
      print('❌ Error en _verifyWithServer: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error: ${e.toString()}');
      }
    }
  }

  /// Mostrar diálogo de verificación con servidor
  Future<void> _showServerVerificationDialog(String email) async {
    _showingVerificationDialog = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Error de Conexión'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ Autenticación con Google exitosa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: $email',
              style: const TextStyle(color: Colors.blue),
            ),
            const Divider(height: 24),
            const Text(
              '🔐 No se pudo conectar al servidor:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Si estás en CASA:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('  → Activa la VPN y presiona "Reintentar"'),
                  SizedBox(height: 8),
                  Text(
                    '🏢 Si estás en la UNIVERSIDAD:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('  → Verifica tu conexión WiFi'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'La app intentó conectarse automáticamente pero no pudo alcanzar el servidor.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _authService.cancelPendingVerification();
              Navigator.of(context).pop(false);
            },
            child: const Text('CANCELAR'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    _showingVerificationDialog = false;

    // Si el usuario presionó "Verificar Cuenta"
    if (result == true && mounted) {
      await _verifyWithServer();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2563EB), // blue-600
              Color(0xFF3B82F6), // blue-500
              Color(0xFF60A5FA), // blue-400
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo y título
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.2 * 255).round()),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 56,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'AsistenciaGuard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sistema de Control de Asistencias UCEVA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFBFDBFE), // blue-200
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Card con formulario
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Iniciar Sesión',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Usa tu correo institucional @uceva.edu.co',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Botón de Google Login
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleGoogleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1F2937),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2563EB),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://www.google.com/favicon.ico',
                                        width: 20,
                                        height: 20,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.login,
                                            size: 20,
                                            color: Color(0xFF2563EB),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Continuar con Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // Información importante
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Solo docentes registrados en la base de datos pueden acceder',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[900],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  const Text(
                    '© 2025 AsistenciaGuard - UCEVA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBFDBFE),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
