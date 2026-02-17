import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageCompressionService {
  /// Comprime una imagen a un máximo de 800x800px con calidad 85%
  /// y la convierte a base64 con formato data:image/jpeg;base64,...
  static Future<String> compressAndConvertToBase64(File imageFile) async {
    try {
      // Leer la imagen
      List<int> imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));

      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Redimensionar si es necesario (máximo 800x800)
      if (image.width > 800 || image.height > 800) {
        image = img.copyResizeCropSquare(
          image,
          size: 800,
          interpolation: img.Interpolation.linear,
        );
      }

      // Codificar como JPEG con calidad 85%
      List<int> compressedBytes = img.encodeJpg(image, quality: 85);

      // Convertir a base64
      String base64String = base64Encode(compressedBytes);

      // Retornar con prefijo data:image/jpeg;base64,
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Error comprimiendo imagen: $e');
    }
  }

  /// Valida que la imagen no sea mayor a 2MB
  static Future<bool> validateImageSize(File imageFile, {int maxMB = 2}) async {
    try {
      int fileSizeInBytes = await imageFile.length();
      int maxSizeInBytes = maxMB * 1024 * 1024;
      return fileSizeInBytes <= maxSizeInBytes;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el tamaño en MB de un archivo
  static Future<double> getFileSizeInMB(File file) async {
    try {
      int fileSizeInBytes = await file.length();
      return fileSizeInBytes / (1024 * 1024);
    } catch (e) {
      return 0;
    }
  }
}
