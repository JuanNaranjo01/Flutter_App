import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import '../services/api_services.dart';
import '../services/video_processing_service.dart';
import '../models/student.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({
    super.key,
    this.isStudentMode = false,
  });

  final bool isStudentMode;

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  static const Color _ucevaGreen = Color(0xFF007F2F);
  static const Color _ucevaGreenDark = Color(0xFF0E4D2A);
  static const Color _ucevaGreenSoft = Color(0xFFEAF6EE);
  static const Color _ucevaGreenBorder = Color(0xFFB7DEC4);

  final _codigoController = TextEditingController();
  final _otpController = TextEditingController();

  // Estados del flujo
  Student? _foundStudent;
  List<String>? _capturedFrames; // Almacena los frames en base64
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isCapturing = false;
  bool _isOtpSending = false;
  bool _isOtpVerifying = false;
  bool _isOtpValidated = false;
  String? _otpSessionToken;
  String? _otpMessage;
  String? _errorMessage;
  int _otpRequestCooldownSeconds =
      0; // Segundos restantes para re-solicitar OTP
  Timer? _otpRequestTimer;

  // Cámara
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = -1;

  @override
  void dispose() {
    _codigoController.dispose();
    _otpController.dispose();
    _cameraController?.dispose();
    _otpRequestTimer?.cancel();
    super.dispose();
  }

  void _startOtpCooldown(int seconds, Function(VoidCallback) dialogSetState) {
    _otpRequestTimer?.cancel();
    setState(() {
      _otpRequestCooldownSeconds = seconds;
    });
    dialogSetState(() {}); // Actualiza diálogo inicial

    _otpRequestTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _otpRequestCooldownSeconds--;
      });
      dialogSetState(() {}); // Reconstruye el diálogo cada segundo

      if (_otpRequestCooldownSeconds <= 0) {
        _otpRequestTimer?.cancel();
      }
    });
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

        if (widget.isStudentMode && student.emailInstitucional.trim().isEmpty) {
          setState(() {
            _foundStudent = null;
            _errorMessage =
                'Este estudiante no tiene correo institucional registrado. No se puede continuar con el autorregistro.';
            _isLoading = false;
          });
          return;
        }

        // En modo estudiante no se permite volver a registrar si ya tiene embeddings.
        if (widget.isStudentMode && student.tieneEmbeddings) {
          setState(() {
            _foundStudent = null;
            _errorMessage =
                'Ya tienes registro facial activo. Solo se permite un registro por estudiante.';
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
            Future<void> requestOtp() async {
              dialogSetState(() {
                _isOtpSending = true;
                _otpMessage = null;
              });

              try {
                final response = await ApiService.requestStudentOtp(
                  codigoEstudiante: student.codigo,
                  emailInstitucional: student.emailInstitucional,
                );

                if (!mounted) return;

                if (response.success) {
                  dialogSetState(() {
                    _isOtpSending = false;
                    _otpMessage = response.message;
                  });
                  _startOtpCooldown(60, dialogSetState);
                } else {
                  dialogSetState(() {
                    _isOtpSending = false;
                    _otpMessage = response.message;
                  });
                }
              } catch (e) {
                if (!mounted) return;

                dialogSetState(() {
                  _isOtpSending = false;
                  _otpMessage = 'No se pudo enviar el OTP: $e';
                });
              }
            }

            Future<void> verifyOtp() async {
              final otp = _otpController.text.trim();
              if (otp.isEmpty) {
                dialogSetState(() {
                  _otpMessage = 'Ingresa el código OTP enviado al correo.';
                });
                return;
              }

              dialogSetState(() {
                _isOtpVerifying = true;
                _otpMessage = null;
              });

              try {
                final response = await ApiService.verifyStudentOtp(
                  codigoEstudiante: student.codigo,
                  otpCode: otp,
                );

                if (!mounted) return;

                dialogSetState(() {
                  _isOtpVerifying = false;
                  _isOtpValidated = true;
                  _otpSessionToken = response.otpToken;
                  _otpMessage = response.message;
                });
              } catch (e) {
                if (!mounted) return;

                dialogSetState(() {
                  _isOtpVerifying = false;
                  _otpMessage = 'OTP inválido o expirado: $e';
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
                                      color: _isOtpValidated
                                          ? Colors.green.shade500
                                          : _ucevaGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _isOtpValidated
                                          ? Icons.check_circle
                                          : Icons.email_outlined,
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
                                          'Verificación por Email',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: _ucevaGreenDark,
                                          ),
                                        ),
                                        Text(
                                          _isOtpValidated
                                              ? '✓ Completado'
                                              : 'Paso 1 de 2',
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
                              if (_isOtpValidated) ...[
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
                                  'Te enviaremos un código a:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _ucevaGreenDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    student.emailInstitucional,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _ucevaGreenDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Botón Enviar OTP
                                SizedBox(
                                  width: double.infinity,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: ElevatedButton.icon(
                                      onPressed: (_isOtpSending ||
                                              _otpRequestCooldownSeconds > 0)
                                          ? null
                                          : requestOtp,
                                      icon: _isOtpSending
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Icon(
                                              _otpRequestCooldownSeconds > 0
                                                  ? Icons.schedule
                                                  : Icons.mark_email_read,
                                            ),
                                      label: Text(
                                        _isOtpSending
                                            ? 'Enviando código...'
                                            : (_otpRequestCooldownSeconds > 0
                                                ? 'Intenta en ${_otpRequestCooldownSeconds}s'
                                                : 'Enviar código OTP'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _otpRequestCooldownSeconds > 0
                                                ? Colors.grey.shade400
                                                : _ucevaGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Campo OTP
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Código de 6 dígitos',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _ucevaGreenDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 8,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        hintText: '• • • • • •',
                                        hintStyle: TextStyle(
                                          fontSize: 20,
                                          color: _ucevaGreenBorder,
                                          letterSpacing: 6,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _ucevaGreenBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _ucevaGreen,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Botón Validar
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isOtpVerifying ? null : verifyOtp,
                                    icon: _isOtpVerifying
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
                                        : const Icon(Icons.verified),
                                    label: Text(
                                      _isOtpVerifying
                                          ? 'Verificando...'
                                          : 'Validar Código',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
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
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_otpMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _otpMessage!.toLowerCase().contains('éxito') ||
                                  _otpMessage!.toLowerCase().contains('éx') ||
                                  _otpMessage!
                                      .toLowerCase()
                                      .contains('correcto')
                              ? Colors.green.shade50
                              : _otpMessage!.toLowerCase().contains('error') ||
                                      _otpMessage!
                                          .toLowerCase()
                                          .contains('inválido')
                                  ? Colors.red.shade50
                                  : _ucevaGreenSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _otpMessage!.toLowerCase().contains('éxito') ||
                                        _otpMessage!
                                            .toLowerCase()
                                            .contains('correcto')
                                    ? Colors.green.shade200
                                    : _otpMessage!
                                                .toLowerCase()
                                                .contains('error') ||
                                            _otpMessage!
                                                .toLowerCase()
                                                .contains('inválido')
                                        ? Colors.red.shade200
                                        : _ucevaGreenBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _otpMessage!.toLowerCase().contains('éxito') ||
                                      _otpMessage!
                                          .toLowerCase()
                                          .contains('correcto')
                                  ? Icons.check_circle
                                  : _otpMessage!
                                              .toLowerCase()
                                              .contains('error') ||
                                          _otpMessage!
                                              .toLowerCase()
                                              .contains('inválido')
                                      ? Icons.error_outline
                                      : Icons.info_outline,
                              color: _otpMessage!
                                          .toLowerCase()
                                          .contains('éxito') ||
                                      _otpMessage!
                                          .toLowerCase()
                                          .contains('correcto')
                                  ? Colors.green.shade700
                                  : _otpMessage!
                                              .toLowerCase()
                                              .contains('error') ||
                                          _otpMessage!
                                              .toLowerCase()
                                              .contains('inválido')
                                      ? Colors.red.shade700
                                      : _ucevaGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _otpMessage!,
                                style: TextStyle(
                                  color: _otpMessage!
                                              .toLowerCase()
                                              .contains('éxito') ||
                                          _otpMessage!
                                              .toLowerCase()
                                              .contains('correcto')
                                      ? Colors.green.shade900
                                      : _otpMessage!
                                                  .toLowerCase()
                                                  .contains('error') ||
                                              _otpMessage!
                                                  .toLowerCase()
                                                  .contains('inválido')
                                          ? Colors.red.shade900
                                          : _ucevaGreenDark,
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
                  onPressed: widget.isStudentMode && !_isOtpValidated
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

    if (widget.isStudentMode && !_isOtpValidated) {
      _showErrorDialog(
        'Primero debes validar el OTP enviado a tu correo institucional.',
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
        forceUpdate: widget.isStudentMode ? false : student.tieneEmbeddings,
        otpToken: widget.isStudentMode ? _otpSessionToken : null,
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
    setState(() {
      _foundStudent = null;
      _capturedFrames = null;
      _codigoController.clear();
      _otpController.clear();
      _errorMessage = null;
      _otpMessage = null;
      _otpSessionToken = null;
      _isOtpValidated = false;
      _isOtpSending = false;
      _isOtpVerifying = false;
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
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                              widget.isStudentMode
                                  ? 'Captura automática con video (registro único)'
                                  : 'Captura automática con video',
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
                  child: Column(
                    children: [
                      Card(
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
                                  hintText: 'Ingresa tu código de estudiante',
                                  prefixIcon: const Icon(Icons.badge),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onSubmitted: (_) => _searchStudent(),
                              ),
                              const SizedBox(height: 16),
                              if (widget.isStudentMode)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        color: Colors.orange.shade800,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Modo estudiante: solo se permite un registro facial y no se puede actualizar.',
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontSize: 13,
                                            height: 1.35,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_errorMessage != null)
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
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                              color: Colors.red.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_errorMessage == null)
                                const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _searchStudent,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.search),
                                  label: Text(_isLoading
                                      ? 'Buscando...'
                                      : 'Buscar Estudiante'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF007f2f),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Card de instrucciones
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 28, color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Instrucciones',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInstructionItem(
                                number: '1',
                                text: 'Ingresa el código del estudiante',
                              ),
                              const SizedBox(height: 12),
                              _buildInstructionItem(
                                number: '2',
                                text: 'Verifica que sea el estudiante correcto',
                              ),
                              const SizedBox(height: 12),
                              _buildInstructionItem(
                                number: '3',
                                text: 'Posiciona la cámara centrada al rostro',
                              ),
                              const SizedBox(height: 12),
                              _buildInstructionItem(
                                number: '4',
                                text: 'Busca una buena iluminación',
                              ),
                              if (widget.isStudentMode) ...[
                                const SizedBox(height: 12),
                                _buildInstructionItem(
                                  number: '5',
                                  text:
                                      'Este modo permite un solo registro y no admite actualización de rostro',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Overlay de procesamiento
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
                        const Text(
                          'Procesando imágenes...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enviando al servidor',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
    );
  }

  Widget _buildInstructionItem({
    required String number,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF007f2f),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1B5E20),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
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
