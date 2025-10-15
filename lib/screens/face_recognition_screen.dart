import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/data_provider.dart';
import '../models/registered_face.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  bool _isScanning = false;
  RegisteredFace? _detectedFace;
  Timer? _scanTimer;

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _detectedFace = null;
    });

    // Simulación de detección después de 2 segundos
    _scanTimer = Timer(const Duration(seconds: 2), () {
      final faces =
          Provider.of<DataProvider>(context, listen: false).registeredFaces;
      if (faces.isNotEmpty && mounted) {
        setState(() {
          _detectedFace = faces[DateTime.now().second % faces.length];
        });
      }
    });
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    setState(() {
      _isScanning = false;
      _detectedFace = null;
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
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
              'Reconocimiento Facial',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Detección en tiempo real',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Vista de cámara simulada
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: _isScanning
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.face_retouching_natural,
                                        size: 100,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(height: 16),
                                      const CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _detectedFace == null
                                            ? 'Escaneando...'
                                            : '¡Rostro detectado!',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(
                                    Icons.videocam_off,
                                    size: 100,
                                    color: Colors.white54,
                                  ),
                          ),

                          // Overlay de detección
                          if (_isScanning && _detectedFace != null)
                            Center(
                              child: Container(
                                width: 250,
                                height: 300,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(9),
                                          bottomRight: Radius.circular(9),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _detectedFace!.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${_detectedFace!.confidence.toStringAsFixed(1)}% confianza',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
                  const SizedBox(height: 16),

                  // Botones de control
                  if (!_isScanning)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar Reconocimiento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3b82f6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _stopScanning,
                        icon: const Icon(Icons.stop),
                        label: const Text('Detener'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFef4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Panel de información del estudiante detectado
          if (_detectedFace != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(_detectedFace!.imageUrl),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detectedFace!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _detectedFace!.codigo,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_detectedFace!.confidence.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(Icons.email, 'Email', _detectedFace!.email),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.book, 'Materia', _detectedFace!.materia),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      Icons.school, 'Carrera', _detectedFace!.carrera),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.calendar_today, 'Semestre',
                      _detectedFace!.semestre),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Asistencia registrada para ${_detectedFace!.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Registrar Asistencia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
