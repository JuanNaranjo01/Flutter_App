import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../providers/data_provider.dart';
import '../services/api_services.dart';
import '../services/image_compression_service.dart';
import '../models/student.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final _codigoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Estados del flujo
  Student? _foundStudent;
  Map<int, File?> _capturedPhotos = {1: null, 2: null, 3: null, 4: null};
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // Etiquetas para las 4 fotos requeridas
  final List<String> _photoLabels = [
    'De Frente',
    'Lado Izquierdo',
    'Lado Derecho',
    'Sonriendo'
  ];

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
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
        setState(() {
          _foundStudent = response.students!.first;
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
    } on TimeoutException catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    } on SocketException catch (e) {
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

  // PASO 2: Mostrar diálogo de confirmación
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Datos del Estudiante'),
        content: _foundStudent != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Código: ${_foundStudent!.codigo}'),
                  const SizedBox(height: 8),
                  Text('Nombre: ${_foundStudent!.nombreCompleto}'),
                  const SizedBox(height: 8),
                  Text('Programa: ${_foundStudent!.programa}'),
                  const SizedBox(height: 8),
                  Text('Semestre: ${_foundStudent!.semestre}'),
                  if (_foundStudent!.tieneEmbeddings) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ Ya tiene ${_foundStudent!.numEmbeddings} fotos registradas',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ],
              )
            : const SizedBox.shrink(),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<DataProvider>(context, listen: false)
                  .setCurrentStudent(_foundStudent);
              _resetPhotos();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  // PASO 3: Capturar foto
  Future<void> _takePicture(int photoNumber) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        final file = File(photo.path);

        // Validar tamaño
        final isValid = await ImageCompressionService.validateImageSize(file);
        if (!isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ La imagen no debe exceder 2MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _capturedPhotos[photoNumber] = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // PASO 4: Registrar embeddings
  Future<void> _registerEmbeddings() async {
    final student = _foundStudent;
    if (student == null) return;

    // Validar que hay entre 3 y 5 fotos
    final photosCount = _capturedPhotos.values.where((p) => p != null).length;
    if (photosCount < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Debes capturar al menos 3 fotos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Convertir fotos a base64
      List<String> base64Images = [];
      for (final photo in _capturedPhotos.values) {
        if (photo != null) {
          final base64 =
              await ImageCompressionService.compressAndConvertToBase64(photo);
          base64Images.add(base64);
        }
      }

      // Registrar embeddings
      final response = await ApiService.registerStudentEmbeddings(
        codigoEstudiante: student.codigo,
        images: base64Images,
        forceUpdate: student.tieneEmbeddings,
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
        title: response.success
            ? const Text('✅ ¡Registro Exitoso!')
            : const Text('❌ Error en el Registro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(response.message),
            if (response.student != null) ...[
              const SizedBox(height: 12),
              Text(
                  'Fotos guardadas: ${response.student!.embeddingsSaved}/${response.student!.totalImages}'),
              if (response.student!.embeddingsFailed > 0)
                Text(
                  'Fotos fallidas: ${response.student!.embeddingsFailed}',
                  style: const TextStyle(color: Colors.orange),
                ),
            ],
            if (response.failedImages != null &&
                response.failedImages!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Fotos que fallaron:'),
              ...response.failedImages!
                  .map((f) => Text('  • Foto ${f.imageNumber}: ${f.reason}')),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
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
    setState(() {
      _foundStudent = null;
      _capturedPhotos = {1: null, 2: null, 3: null, 4: null};
      _codigoController.clear();
      _errorMessage = null;
    });
    Provider.of<DataProvider>(context, listen: false).clearCurrentStudent();
  }

  void _resetPhotos() {
    setState(() {
      _capturedPhotos = {1: null, 2: null, 3: null, 4: null};
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStudent = Provider.of<DataProvider>(context).currentStudent;

    // Si hay un estudiante seleccionado, mostrar pantalla de captura
    if (currentStudent != null) {
      return _buildCaptureScreen(currentStudent);
    }

    // Si no, mostrar pantalla de búsqueda
    return _buildSearchScreen();
  }

  Widget _buildSearchScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
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
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
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
                          'Registro de Embeddings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Registra tus datos biométricos',
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
                              prefixIcon: const Icon(Icons.card_giftcard),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _searchStudent(),
                          ),
                          const SizedBox(height: 16),
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
                                      style:
                                          TextStyle(color: Colors.red.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage == null) const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _searchStudent,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.search),
                              label: Text(_isLoading
                                  ? 'Buscando...'
                                  : 'Buscar Estudiante'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildCaptureScreen(Student student) {
    final photosCount = _capturedPhotos.values.where((p) => p != null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
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
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Captura de Fotos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Captura: $photosCount/4 fotos',
                          style: const TextStyle(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estudiante: ${student.nombreCompleto}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código: ${student.codigo}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final photoNumber = index + 1;
                      final photo = _capturedPhotos[photoNumber];

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: photo == null
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt,
                                                size: 40, color: Colors.grey),
                                            const SizedBox(height: 8),
                                            Text(
                                              _photoLabels[index],
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Stack(
                                        children: [
                                          Image.file(
                                            photo,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _takePicture(photoNumber),
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: Text(
                                    photo == null ? 'Capturar' : 'Recapturar',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_isProcessing)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          const Text('Procesando imágenes...'),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                photosCount >= 3 ? _registerEmbeddings : null,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Guardar Fotos'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor:
                                  photosCount >= 3 ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (photosCount < 3)
                          Text(
                            'Captura al menos 3 fotos para continuar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _resetForm(),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver'),
                          ),
                        ),
                      ],
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
