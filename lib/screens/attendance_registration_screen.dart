import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../services/api_services.dart';
import '../models/attendance_response.dart';
import '../providers/data_provider.dart';

class AttendanceRegistrationScreen extends StatefulWidget {
  const AttendanceRegistrationScreen({super.key});

  @override
  State<AttendanceRegistrationScreen> createState() =>
      _AttendanceRegistrationScreenState();
}

class _AttendanceRegistrationScreenState
    extends State<AttendanceRegistrationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  int _currentFrame = 0;
  String _statusMessage = 'Listo para registrar asistencia';
  List<CameraDescription>? _cameras;
  final List<AttendanceData> _registeredAttendances = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _statusMessage = 'No se encontraron cámaras disponibles';
        });
        return;
      }

      // Buscar cámara frontal
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'Listo para registrar asistencia';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error al inicializar la cámara: $e';
        });
      }
    }
  }

  Future<void> _captureFramesAndRegister() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorDialog('La cámara no está lista');
      return;
    }

    setState(() {
      _isCapturing = true;
      _currentFrame = 0;
      _statusMessage = 'Preparando captura...';
    });

    try {
      List<String> frames = [];

      // Capturar 4 frames
      for (int i = 0; i < 4; i++) {
        setState(() {
          _currentFrame = i + 1;
          _statusMessage = 'Capturando frame ${i + 1}/4...';
        });

        // Capturar imagen
        final XFile image = await _cameraController!.takePicture();

        // Convertir a base64
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        frames.add('data:image/jpeg;base64,$base64Image');

        // Esperar 500ms entre frames (excepto después del último)
        if (i < 3) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      setState(() {
        _isCapturing = false;
        _isProcessing = true;
        _statusMessage = 'Analizando rostro...';
      });

      // Obtener el token de sesión del proveedor de datos
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final sessionToken = dataProvider.authService.sessionToken;

      print(
          '🔑 Token de sesión obtenido: ${sessionToken?.substring(0, 10) ?? "NULL"}...');
      if (sessionToken == null) {
        print(
            '⚠️ WARNING: sessionToken es NULL - El servidor no recibirá el token');
      }

      // Enviar al servidor
      final response = await ApiService.registrarAsistencia(
        frames: frames,
        sessionToken: sessionToken,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Verificar si hay error de sesión expirada
      if (!response.success &&
          (response.error?.contains('Sin sesión') == true ||
              response.error?.contains('sesión expirada') == true ||
              response.error?.contains('sesión inválida') == true)) {
        // Sesión expirada - redirigir al login
        if (mounted) {
          _showErrorDialog(
            'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
            redirectToLogin: true,
          );
        }
        return;
      }

      if (response.success && response.data != null) {
        _showSuccessDialog(response.data!);
      } else {
        _showErrorDialog(response.error ?? 'Error desconocido');
      }
    } on TimeoutException catch (e) {
      setState(() {
        _isCapturing = false;
        _isProcessing = false;
      });
      _showErrorDialog(e.toString());
    } on SocketException catch (e) {
      setState(() {
        _isCapturing = false;
        _isProcessing = false;
      });
      _showErrorDialog(e.toString());
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _isProcessing = false;
      });
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  void _showSuccessDialog(AttendanceData data) {
    // Actualizar lista local
    _registeredAttendances.add(data);

    // Refrescar consultas automáticamente en background
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        dataProvider.refreshAttendanceRecords();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  color: Colors.green.shade600, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Asistencia Registrada!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Estudiante:', data.estudiante),
              const SizedBox(height: 12),
              _buildInfoRow('Código:', data.codigoEstudiante),
              const SizedBox(height: 12),
              _buildInfoRow('Programa:', data.programa),
              const SizedBox(height: 12),
              _buildInfoRow('Materia:', data.materia),
              const SizedBox(height: 12),
              _buildInfoRow('Fecha:', data.fecha),
              const SizedBox(height: 12),
              _buildInfoRow('Hora:', data.hora),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified,
                        color: Color(0xFF2E7D32), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Confianza: ${(data.confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _registeredAttendances.insert(0, data);
                _statusMessage = 'Listo para registrar asistencia';
              });
            },
            child: const Text('Aceptar', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String errorMessage, {bool redirectToLogin = false}) {
    showDialog(
      context: context,
      barrierDismissible: !redirectToLogin,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  color: Colors.red.shade600, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                redirectToLogin ? 'Sesión Expirada' : 'Error',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            errorMessage,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          if (!redirectToLogin)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          if (!redirectToLogin)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _captureFramesAndRegister();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          if (redirectToLogin)
            ElevatedButton(
              onPressed: () async {
                final dataProvider =
                    Provider.of<DataProvider>(context, listen: false);
                await dataProvider.logout();

                if (context.mounted) {
                  Navigator.of(context).pop(); // Cerrar diálogo
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ir a Login'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // App Bar con gradiente
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Registro de Asistencia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Reconocimiento facial automático',
                          style: TextStyle(
                            color: Color(0xFFD1FAE5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Camera Preview con altura fija
                SizedBox(
                  height: 400,
                  child: Container(
                    color: Colors.black,
                    child: _isCameraInitialized
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(_cameraController!),
                              // Overlay con guía facial
                              Center(
                                child: Container(
                                  width: 240,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _isCapturing
                                          ? Colors.greenAccent
                                          : Colors.white.withValues(alpha: 0.7),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(150),
                                  ),
                                ),
                              ),
                              // Indicador de captura
                              if (_isCapturing)
                                Positioned(
                                  top: 30,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Text(
                                        'Frame $_currentFrame/4',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                    color: Colors.white),
                                const SizedBox(height: 16),
                                Text(
                                  _statusMessage,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                // Panel de control pegado a la cámara
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lista de asistencias registradas
                      if (_registeredAttendances.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Asistencias Registradas',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_registeredAttendances.length}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _registeredAttendances.length,
                                  itemBuilder: (context, index) {
                                    final attendance =
                                        _registeredAttendances[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.green.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.green.shade100,
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        title: Text(
                                          attendance.estudiante,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              'Código: ${attendance.codigoEstudiante}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              '${attendance.hora} - ${(attendance.confidence * 100).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Icon(
                                          Icons.verified,
                                          color: Colors.green.shade600,
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Espaciado antes del botón
                      const SizedBox(height: 16),

                      // Botón de registro
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_isCapturing ||
                                  _isProcessing ||
                                  !_isCameraInitialized)
                              ? null
                              : _captureFramesAndRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: _isProcessing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Procesando...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Registrar Asistencia',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
