import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';

class VideoProcessingService {
  /// Extrae 4 frames distribuidos uniformemente de una secuencia de imágenes capturadas
  /// [images]: Lista de XFile con las imágenes capturadas del video
  /// Retorna una lista de imágenes en formato base64
  static Future<List<String>> extractFramesFromImages(
      List<XFile> images) async {
    if (images.isEmpty) {
      throw Exception('No hay imágenes para procesar');
    }

    // Si hay menos de 4 imágenes, usar todas
    if (images.length <= 4) {
      return await _convertImagesToBase64(images);
    }

    // Extraer 4 frames distribuidos uniformemente
    List<XFile> selectedFrames = [];
    final step = images.length / 4;

    for (int i = 0; i < 4; i++) {
      final index = (i * step).floor();
      selectedFrames.add(images[index]);
    }

    return await _convertImagesToBase64(selectedFrames);
  }

  /// Convierte una lista de XFile a formato base64
static Future<List<String>> _convertImagesToBase64(
    List<XFile> images) async {
  List<String> base64Images = [];

  for (final image in images) {
    final file = File(image.path);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    base64Images.add('data:image/jpeg;base64,$base64Image');

    // NUEVO: borrar el archivo temporal inmediatamente después de leerlo
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // si falla el borrado no debe interrumpir el flujo, pero
      // idealmente registra el error en tus logs internos
    }
  }

  return base64Images;
}

  /// Captura frames durante un período de tiempo
  /// [controller]: Controlador de la cámara
  /// [durationSeconds]: Duración de la captura en segundos
  /// [framesPerSecond]: Frames por segundo a capturar
  /// Retorna una lista de XFile con los frames capturados
  static Future<List<XFile>> captureFramesOverTime({
    required CameraController controller,
    required int durationSeconds,
    int framesPerSecond = 3,
  }) async {
    if (!controller.value.isInitialized) {
      throw Exception('Cámara no inicializada');
    }

    List<XFile> capturedFrames = [];
    final totalFrames = durationSeconds * framesPerSecond;
    final delayBetweenFrames =
        Duration(milliseconds: (1000 / framesPerSecond).round());

    for (int i = 0; i < totalFrames; i++) {
      try {
        final XFile frame = await controller.takePicture();
        capturedFrames.add(frame);
        
        // Esperar antes de capturar el siguiente frame (excepto en el último)
        if (i < totalFrames - 1) {
          await Future.delayed(delayBetweenFrames);
        }
      } catch (e) {
        // Error capturando frame - continuar con el siguiente
      }
    }

    if (capturedFrames.isEmpty) {
      throw Exception('No se pudieron capturar frames');
    }

    return capturedFrames;
  }
}
