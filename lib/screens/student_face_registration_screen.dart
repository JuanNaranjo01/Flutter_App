import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import '../services/api_services.dart';
import '../services/video_processing_service.dart';
import '../providers/data_provider.dart';

class StudentFaceRegistrationScreen extends StatefulWidget {
  const StudentFaceRegistrationScreen({super.key});

  @override
  State<StudentFaceRegistrationScreen> createState() => _StudentFaceRegistrationScreenState();
}

class _StudentFaceRegistrationScreenState extends State<StudentFaceRegistrationScreen> {
  List<String>? _capturedFrames; // Almacena los frames en base64
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isCapturing = false;
  String? _errorMessage;

  // Cámara
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontraron cámaras disponibles';
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
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar la cámara: $e';
      });
    }
  }

  Future<void> _startFaceRegistration() async {
    if (!_isCameraInitialized || _cameraController == null) {
      _showError('Cámara no inicializada');
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      // Captura las imágenes en bruto (XFile) durante 3 segundos, 3 fps
      final capturedImages = await VideoProcessingService.captureFramesOverTime(
        controller: _cameraController!,
        durationSeconds: 3,
        framesPerSecond: 3,
      );

      final frames = await VideoProcessingService.extractFramesFromImages(capturedImages);

      setState(() {
        _capturedFrames = frames;
        _isCapturing = false;
      });

      if (frames.isNotEmpty) {
        await _processAndRegisterFace(frames);
      } else {
        _showError('No se pudieron capturar frames del video');
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _showError('Error al capturar video: $e');
    }
  }

  Future<void> _processAndRegisterFace(List<String> frames) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final sessionToken = dataProvider.authService.sessionToken;

      if (sessionToken == null) {
        throw Exception('No hay sesión activa');
      }

      final result = await ApiService.registerStudentEmbeddingsWithToken(
        frames: frames,
        sessionToken: sessionToken,
      );

      setState(() {
        _isProcessing = false;
      });

      if (result.success) {
        _showSuccessDialog();
      } else {
        _showError(result.message);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error al procesar el rostro: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Registro Exitoso!'),
          content: const Text(
            'Tu rostro ha sido registrado correctamente en el sistema.\n\n'
            'Ahora podrás ser identificado en las sesiones de asistencia.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final dataProvider = Provider.of<DataProvider>(context, listen: false);
                await dataProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final student = dataProvider.currentStudent;

    if (student == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error: No hay estudiante logueado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Registro de Rostro'),
        backgroundColor: const Color(0xFF007f2f),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final dataProvider = Provider.of<DataProvider>(context, listen: false);
              await dataProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Información del estudiante
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFF007f2f),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      student.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Código: ${student.codigo}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.emailInstitucional,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.programa} - Semestre ${student.semestre}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instrucciones
            const Text(
              'Instrucciones para el registro:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007f2f),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Asegúrate de estar en un lugar bien iluminado\n'
              '2. Mira directamente a la cámara\n'
              '3. Mantén una expresión neutral\n'
              '4. Presiona "Registrar Rostro" y mueve la cabeza lentamente',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),

            // Vista de cámara
            if (_isCameraInitialized && _cameraController != null)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CameraPreview(_cameraController!),
                ),
              )
            else
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Text('Inicializando cámara...'),
                ),
              ),

            const SizedBox(height: 24),

            // Botón de registro
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isLoading || _isProcessing || _isCapturing || !_isCameraInitialized)
                    ? null
                    : _startFaceRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007f2f),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCapturing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Capturando video...'),
                        ],
                      )
                    : _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Procesando rostro...'),
                            ],
                          )
                        : const Text(
                            'Registrar Rostro',
                            style: TextStyle(fontSize: 16),
                          ),
              ),
            ),

            // Mensaje de error
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}