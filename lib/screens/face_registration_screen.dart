import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:io';
import '../services/api_services.dart';
import '../services/video_processing_service.dart';
import '../models/student.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({
    super.key,
    this.isStudentMode = false,
    this.onStudentAuthenticated,
    this.onStudentReset,
  });

  final bool isStudentMode;
  final VoidCallback? onStudentAuthenticated;
  final VoidCallback? onStudentReset;

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  static const Color _ucevaGreen = Color(0xFF007F2F);
  static const Color _ucevaGreenDark = Color(0xFF0E4D2A);
  static const Color _ucevaGreenSoft = Color(0xFFEAF6EE);
  static const Color _ucevaGreenBorder = Color(0xFFB7DEC4);

  final _codigoController = TextEditingController();

  // Estados del flujo
  Student? _foundStudent;
  List<String>? _capturedFrames; // Almacena los frames en base64
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isCapturing = false;
  String? _errorMessage;
  bool _isGoogleSigningIn = false;
  bool _studentVerificationChecked = false;
  String? _studentVerificationError;

  // Cámara
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = -1;

  @override
  void dispose() {
    _codigoController.dispose();
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

      if (_currentCameraIndex < 0 || _currentCameraIndex >= _cameras!.length) {
        final frontIndex = _cameras!.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
        _currentCameraIndex = frontIndex >= 0 ? frontIndex : 0;
      }

      final selectedCamera = _cameras![_currentCameraIndex];

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar la cámara: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_isCapturing || _isProcessing) return;
    if (_cameras == null || _cameras!.length < 2) return;

    try {
      final nextIndex = (_currentCameraIndex + 1) % _cameras!.length;

      await _cameraController?.dispose();
      _cameraController = null;

      setState(() {
        _isCameraInitialized = false;
        _currentCameraIndex = nextIndex;
      });

      await _initializeCamera();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cambiar cámara: $e';
      });
    }
  }

  // PASO 1: Buscar estudiante
  Future<void> _searchStudent() async {
    // Plan B: en modo estudiante no pedimos código, usamos Google Sign-In
    if (widget.isStudentMode) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final GoogleSignIn googleSignIn =
            GoogleSignIn(scopes: ['email', 'profile']);
        print('googleSignIn: attempting signOut to force account chooser');
        try {
          await googleSignIn.signOut();
          print('googleSignIn: signOut successful');
        } catch (e) {
          print('googleSignIn: signOut error: $e');
        }
        print('googleSignIn: calling signIn() to show account chooser');
        final account = await googleSignIn.signIn();
        print('googleSignIn: signIn returned account=${account?.email}');
        if (account == null) {
          setState(() {
            _errorMessage = 'Cancelaste el inicio de sesión';
            _isLoading = false;
          });
          return;
        }

        final email = account.email;
        print('✅ Google Sign-In (student mode): $email');

        final response = await ApiService.verifyStudentByEmail(email: email);

        if (!mounted) return;

        if (response['success'] == true && response['student'] != null) {
          // Mapear a Student - el backend solo devuelve campos básicos
          final studentJson = response['student'];
          final nombre = studentJson['nombre'] ?? '';
          final apellidos = studentJson['apellidos'] ?? '';
          
          // Construir Student con valores por defecto para campos faltantes
          final student = Student(
            codigo: studentJson['codigo'] ?? '',
            nombreCompleto: '$nombre $apellidos'.trim(),
            nombre: nombre,
            apellidos: apellidos,
            emailInstitucional: studentJson['email_institucional'] ?? '',
            emailPersonal: '',
            programa: '',
            semestre: 0,
            movil: '',
            telefonos: '',
            tieneEmbeddings: false, // El backend no devuelve este campo
            numEmbeddings: 0,
          );

          setState(() {
            _foundStudent = student;
            _isLoading = false;
            _studentVerificationChecked = true; // ya está verificado por email
          });

          widget.onStudentAuthenticated?.call();
          _showConfirmationDialog();
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Email no encontrado';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }

      return;
    }

    // Modo no estudiante: comportamiento previo (buscar por código)
    if (_codigoController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa el código del estudiante';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.searchStudent(_codigoController.text);

      if (!mounted) return;

      if (response.found &&
          response.students != null &&
          response.students!.isNotEmpty) {
        final student = response.students!.first;

        if (student.emailInstitucional.trim().isEmpty) {
          setState(() {
            _foundStudent = null;
            _errorMessage =
                'Este estudiante no tiene correo institucional registrado. No se puede continuar con el autorregistro.';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _foundStudent = student;
          _isLoading = false;
        });
        _showConfirmationDialog();
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Estudiante no encontrado en BIENESTAR';
          _isLoading = false;
        });
      }
    } on SocketException catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    } on TimeoutException catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // PASO 2: Mostrar diálogo de confirmación y luego inicializar cámara
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final student = _foundStudent;

        if (student == null) {
          return const SizedBox.shrink();
        }

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            Future<void> verifyStudentWithGoogle() async {
              dialogSetState(() {
                _isGoogleSigningIn = true;
                _studentVerificationError = null;
              });

              try {
                final GoogleSignIn googleSignIn = GoogleSignIn(
                  scopes: ['email', 'profile'],
                );

                // Realizar Google Sign In
                final account = await googleSignIn.signIn();
                if (account == null) {
                  dialogSetState(() {
                    _isGoogleSigningIn = false;
                    _studentVerificationError =
                        'Cancelaste el inicio de sesión';
                  });
                  return;
                }

                final email = account.email;
                print('✅ Google Sign-In exitoso: $email');

                // Llamar al backend para verificar que este correo está en la BD
                final response = await ApiService.verifyStudentEmail(
                  email: email,
                  codigoEstudiante: student.codigo,
                );

                if (!mounted) return;

                if (response['success'] == true) {
                  dialogSetState(() {
                    _isGoogleSigningIn = false;
                    _studentVerificationChecked = true;
                  });
                } else {
                  dialogSetState(() {
                    _isGoogleSigningIn = false;
                    _studentVerificationError =
                        response['message'] ?? 'Email no válido';
                  });
                }
              } catch (e) {
                if (!mounted) return;

                dialogSetState(() {
                  _isGoogleSigningIn = false;
                  _studentVerificationError = 'Error: ${e.toString()}';
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: widget.isStudentMode
                  ? null
                  : const Text('Confirmar Registro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isStudentMode) ...[
                      Text(
                        student.nombreCompleto,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Se iniciará el registro facial de este estudiante.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (student.tieneEmbeddings) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.amber.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ya tiene fotos registradas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${student.numEmbeddings} foto(s) registrada(s)',
                                    style: TextStyle(
                                      color: Colors.amber.shade700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.isStudentMode) ...[
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: _ucevaGreen.withOpacity(0.2),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _ucevaGreenSoft,
                                const Color(0xFFDDF0E4),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con progreso
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _studentVerificationChecked
                                          ? Colors.green.shade500
                                          : _ucevaGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _studentVerificationChecked
                                          ? Icons.check_circle
                                          : Icons.account_circle,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Verificación con Google',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: _ucevaGreenDark,
                                          ),
                                        ),
                                        Text(
                                          _studentVerificationChecked
                                              ? '✓ Verificado'
                                              : 'Inicia sesión con tu correo institucional',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _ucevaGreen,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_studentVerificationChecked) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.verified_user,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Verificación completada correctamente',
                                          style: TextStyle(
                                            color: Colors.green.shade900,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Haz clic en el botón para iniciar sesión con Google usando tu correo institucional:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _ucevaGreenDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Botón Google Sign In
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isGoogleSigningIn
                                        ? null
                                        : verifyStudentWithGoogle,
                                    icon: _isGoogleSigningIn
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.login),
                                    label: Text(
                                      _isGoogleSigningIn
                                          ? 'Iniciando sesión...'
                                          : 'Iniciar sesión con Google',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _ucevaGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_studentVerificationError != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _studentVerificationError!,
                                            style: TextStyle(
                                              color: Colors.red.shade900,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetForm();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      widget.isStudentMode && !_studentVerificationChecked
                          ? null
                          : () {
                              Navigator.pop(context);
                              _initializeCamera();
                            },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3b82f6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // PASO 3: Capturar frames con cuenta regresiva
  Future<void> _captureFrames() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorDialog('La cámara no está lista');
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capturar frames durante 3 segundos
      final frames = await VideoProcessingService.captureFramesOverTime(
        controller: _cameraController!,
        durationSeconds: 3,
        framesPerSecond: 3,
      );

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      // Extraer 4 frames distribuidos uniformemente
      final base64Frames =
          await VideoProcessingService.extractFramesFromImages(frames);

      if (!mounted) return;

      setState(() {
        _capturedFrames = base64Frames;
      });

      // Automáticamente proceder a registrar embeddings
      _registerEmbeddings();
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _showErrorDialog('Error al capturar frames: $e');
    }
  }

  // PASO 4: Registrar embeddings
  Future<void> _registerEmbeddings() async {
    final student = _foundStudent;
    if (student == null || _capturedFrames == null) return;

    if (widget.isStudentMode && !_studentVerificationChecked) {
      _showErrorDialog(
        'Primero debes verificar tu identidad con Google.',
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Registrar embeddings con los frames capturados
      final response = await ApiService.registerStudentEmbeddings(
        codigoEstudiante: student.codigo,
        images: _capturedFrames!,
        forceUpdate: !widget.isStudentMode,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Mostrar resultado
      _showResultDialog(response);
    } on ConflictException catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showConflictDialog(e.message, e.existingEmbeddings);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  // PASO 5: Mostrar resultado
  void _showResultDialog(StudentEmbeddingResponse response) {
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
                color: response.success
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                response.success ? Icons.check_circle : Icons.error_outline,
                color: response.success
                    ? Colors.green.shade600
                    : Colors.red.shade600,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                response.success
                    ? '¡Registro Exitoso!'
                    : 'Error en el Registro',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(response.message),
              if (response.student != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fotos guardadas: ${response.student!.embeddingsSaved}/${response.student!.totalImages}',
                        style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (response.student!.embeddingsFailed > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Fotos fallidas: ${response.student!.embeddingsFailed}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (response.failedImages != null &&
                  response.failedImages!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Fotos que fallaron:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...response.failedImages!.map((f) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text('• Foto ${f.imageNumber}: ${f.reason}'),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _showConflictDialog(String message, int existingCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Embeddings Existentes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text('Embeddings registrados: $existingCount'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (!widget.isStudentMode)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Intentar con force_update = true (será manejado por _registerEmbeddings)
              },
              child: const Text('Actualizar'),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _cameraController?.dispose();
    widget.onStudentReset?.call();
    setState(() {
      _foundStudent = null;
      _capturedFrames = null;
      _codigoController.clear();
      _errorMessage = null;
      _isGoogleSigningIn = false;
      _studentVerificationChecked = false;
      _studentVerificationError = null;
      // Removed OTP-related state (switched to Google Sign In flow)
      _cameraController = null;
      _isCameraInitialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si hay estudiante confirmado, mostrar pantalla con cámara
    if (_foundStudent != null) {
      return _buildCameraScreen();
    }
    // Si no, mostrar pantalla de búsqueda
    return _buildSearchScreen();
  }

  Widget _buildSearchScreen() {
    if (widget.isStudentMode) {
      return _buildStudentLoginScreen();
    }
    return _buildTeacherSearchScreen();
  }

  // Pantalla de login para modo estudiante
  Widget _buildStudentLoginScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF007f2f), Color(0xFF009938)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícono principal
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Registro Facial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión con tu correo\ninstitucional para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Card del botón
                  Card(
                    elevation: 12,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade700, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Botón Google
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _searchStudent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1F2937),
                                elevation: 2,
                                side: BorderSide(
                                    color: Colors.grey.shade300, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF007f2f)),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.network(
                                          'https://www.google.com/favicon.ico',
                                          width: 20,
                                          height: 20,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.login,
                                                      size: 20,
                                                      color: Color(0xFF4285F4)),
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
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Usa tu correo @uceva.edu.co',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
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

  // Pantalla de búsqueda para modo docente (sin cambios)
  Widget _buildTeacherSearchScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF007f2f), Color(0xFF009938)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text(
                              'Registro de Embeddings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Captura automática con video',
                              style: TextStyle(
                                color: Color(0xFFBFDBFE),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buscar Estudiante',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _codigoController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Ingresa el código del estudiante',
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _searchStudent(),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red.shade900),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_errorMessage!,
                                        style: TextStyle(
                                            color: Colors.red.shade900)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _searchStudent,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.search),
                              label: Text(
                                  _isLoading ? 'Buscando...' : 'Buscar Estudiante'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007f2f),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        const Text('Procesando imágenes...',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Enviando al servidor',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007f2f),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _resetForm,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro de Embeddings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _foundStudent?.nombreCompleto ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Vista de cámara
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
                                    : Colors.white.withValues(alpha: 0.7),
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
                                child: const Text(
                                  'CAPTURANDO...',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if ((_cameras?.length ?? 0) > 1)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _switchCamera,
                                icon: const Icon(
                                  Icons.flip_camera_android,
                                  color: Colors.white,
                                ),
                                tooltip: 'Cambiar cámara',
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Inicializando cámara...',
                            style: TextStyle(color: Colors.white),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Info del estudiante
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _foundStudent?.codigo ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _foundStudent?.programa ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Instrucciones
                  if (!_isCapturing && !_isProcessing)
                    Text(
                      'Posiciona tu rostro dentro del óvalo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (!_isCapturing && !_isProcessing)
                    const SizedBox(height: 12),

                  // Botón de captura
                  if (_isProcessing)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Procesando y enviando al servidor...'),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isCameraInitialized && !_isCapturing
                            ? _captureFrames
                            : null,
                        icon: Icon(
                          _isCapturing ? Icons.check_circle : Icons.camera_alt,
                          size: 28,
                        ),
                        label: Text(
                          _isCapturing ? 'Capturando...' : 'Registrar Rostro',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCapturing
                              ? Colors.green
                              : const Color(0xFF3b82f6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
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
