import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../services/api_services.dart';
import '../models/attendance_response.dart';

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

      // Enviar al servidor
      final response = await ApiService.registrarAsistencia(frames: frames);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

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
              child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Confianza: ${(data.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.blue.shade900,
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

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
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
              child: Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
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
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: const Color(0xFF3b82f6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
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
                            width: 280,
                            height: 360,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _isCapturing
                                    ? Colors.greenAccent
                                    : Colors.white.withOpacity(0.7),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(180),
                            ),
                          ),
                        ),
                        // Indicador de captura
                        if (_isCapturing)
                          Positioned(
                            top: 40,
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
                          const CircularProgressIndicator(color: Colors.white),
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

          // Panel de control
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de estado
                  Icon(
                    _isProcessing
                        ? Icons.analytics
                        : _isCapturing
                            ? Icons.camera
                            : Icons.face_retouching_natural,
                    size: 48,
                    color: _isCapturing || _isProcessing
                        ? const Color(0xFF3b82f6)
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),

                  // Mensaje de estado
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón de registro
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isCapturing || _isProcessing || !_isCameraInitialized)
                          ? null
                          : _captureFramesAndRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3b82f6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Procesando...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Registrar Asistencia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Instrucciones
                  if (!_isCapturing && !_isProcessing)
                    Text(
                      'Coloca tu rostro en el óvalo y presiona el botón',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
