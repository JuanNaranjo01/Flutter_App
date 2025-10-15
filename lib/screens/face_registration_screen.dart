import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/data_provider.dart';
import '../models/registered_face.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _materiaController = TextEditingController();
  final _carreraController = TextEditingController();
  final _semestreController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      }
    } catch (e) {
      // guard justo después del await / antes de usar context
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar imagen: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  void _registerFace() {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      final newFace = RegisteredFace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text,
        codigo: _codigoController.text,
        materia: _materiaController.text,
        carrera: _carreraController.text,
        semestre: _semestreController.text,
        registrationDate: DateTime.now().toString().split(' ')[0],
        confidence: 90 + (10 * (DateTime.now().millisecond / 1000)),
        imageUrl: _imageFile!.path,
      );

      Provider.of<DataProvider>(context, listen: false)
          .addRegisteredFace(newFace);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Rostro registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar formulario
      _formKey.currentState!.reset();
      setState(() {
        _imageFile = null;
      });
      _nameController.clear();
      _emailController.clear();
      _codigoController.clear();
      _materiaController.clear();
      _carreraController.clear();
      _semestreController.clear();
    } else if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, capture una foto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registro de Rostro',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Captura y registra un nuevo estudiante',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vista de cámara/imagen
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Icon(Icons.person,
                            size: 100, color: Colors.white54),
                      ),
              ),
              const SizedBox(height: 16),

              // Botones de captura
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capturar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3b82f6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Formulario
              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _codigoController,
                label: 'Código Estudiante',
                icon: Icons.badge,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _materiaController,
                label: 'Materia',
                icon: Icons.book,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _carreraController,
                label: 'Carrera',
                icon: Icons.school,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _semestreController,
                label: 'Semestre',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 24),

              // Botón de registro
              ElevatedButton(
                onPressed: _registerFace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Registrar Rostro',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingrese $label';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codigoController.dispose();
    _materiaController.dispose();
    _carreraController.dispose();
    _semestreController.dispose();
    super.dispose();
  }
}
