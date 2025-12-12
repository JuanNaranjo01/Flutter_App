# 👨‍💻 DOCUMENTACIÓN TÉCNICA - Registro de Embeddings Faciales

Documentación completa para desarrolladores sobre la arquitectura, API y detalles técnicos del sistema.

---

## 📐 Arquitectura del Proyecto

```
lib/
├── config/
│   └── api_config.dart              # Configuración centralizada
├── models/
│   ├── student.dart                 # Modelos de estudiante
│   ├── registered_face.dart
│   ├── attendance_record.dart
│   └── teacher.dart
├── providers/
│   └── data_provider.dart           # Estado global (Provider)
├── screens/
│   ├── face_registration_screen.dart # Flujo de 5 pantallas
│   ├── dashboard_screen.dart
│   ├── face_recognition_screen.dart
│   ├── login_screen.dart
│   └── chat_interface_screen.dart
├── services/
│   ├── api_services.dart            # Cliente HTTP
│   └── image_compression_service.dart # Procesamiento de imágenes
└── main.dart                         # Entry point
```

---

## 🔌 API Reference

### 1. Configuración (api_config.dart)

```dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.100.99:5000';
  static const String apiPath = '/api';
  static const String fullApiUrl = '$baseUrl$apiPath';
  
  // Endpoints
  static const String searchStudentEndpoint = '$apiPath/search_student';
  static const String registerEmbeddingsEndpoint = '$apiPath/register_student_embeddings';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
```

### 2. Servicio de API (api_services.dart)

#### searchStudent()

**Propósito:** Buscar un estudiante por código.

**Signature:**
```dart
static Future<SearchStudentResponse> searchStudent(
  String codigo,
  {int maxRetries = 2}
)
```

**Parámetros:**
- `codigo` (String, required): Código de estudiante
- `maxRetries` (int, optional): Máximo reintentos en timeout (default: 2)

**Request:**
```json
{
  "codigo": "1234567890"
}
```

**Respuesta Exitosa (200):**
```dart
SearchStudentResponse(
  success: true,
  found: true,
  count: 1,
  students: [
    Student(
      codigo: "1234567890",
      nombreCompleto: "Juan Pérez García",
      nombre: "Juan",
      apellidos: "Pérez García",
      emailInstitucional: "juan.perez@uceva.edu.co",
      emailPersonal: "juan@gmail.com",
      programa: "Ingeniería de Sistemas",
      semestre: 5,
      movil: "3001234567",
      telefonos: "555-1234",
      tieneEmbeddings: false,
      numEmbeddings: 0,
    )
  ]
)
```

**Respuesta No Encontrado (200):**
```dart
SearchStudentResponse(
  success: true,
  found: false,
  message: "No se encontraron estudiantes con esos criterios"
)
```

**Excepciones:**
- `TimeoutException` - Timeout después de 2 reintentos
- `SocketException` - Error de red después de 2 reintentos
- `Exception` - Error genérico del servidor

**Uso:**
```dart
try {
  final response = await ApiService.searchStudent("1234567890");
  if (response.found) {
    // Estudiante encontrado
    final student = response.students!.first;
  } else {
    // Mostrar error
    print(response.message);
  }
} on TimeoutException catch (e) {
  // Manejar timeout
}
```

---

#### registerStudentEmbeddings()

**Propósito:** Registrar imágenes faciales para un estudiante.

**Signature:**
```dart
static Future<StudentEmbeddingResponse> registerStudentEmbeddings({
  required String codigoEstudiante,
  required List<String> images,
  bool forceUpdate = false,
  int maxRetries = 2,
})
```

**Parámetros:**
- `codigoEstudiante` (String, required): Código del estudiante
- `images` (List<String>, required): Array de imágenes en base64
- `forceUpdate` (bool, optional): Actualizar si ya tiene embeddings
- `maxRetries` (int, optional): Máximo reintentos en timeout

**Request:**
```json
{
  "codigo_estudiante": "1234567890",
  "images": [
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  ],
  "force_update": false
}
```

**Validaciones Locales:**
- Cantidad de imágenes: 3-5 (ArgumentError si no)
- Cada imagen ya debe estar en base64 con prefijo `data:image/jpeg;base64,`

**Respuesta Exitosa (200/201):**
```dart
StudentEmbeddingResponse(
  success: true,
  message: "Embeddings registrados correctamente (4/4)",
  student: StudentInfo(
    codigo: "1234567890",
    nombre: "Juan",
    apellido: "Pérez García",
    nombreCompleto: "Juan Pérez García",
    programa: "Ingeniería de Sistemas",
    idUsuario: 123,
    embeddingsSaved: 4,
    embeddingsFailed: 0,
    totalImages: 4,
  ),
  failedImages: null
)
```

**Respuesta Éxito Parcial (200/201):**
```dart
StudentEmbeddingResponse(
  success: true,
  message: "Embeddings registrados correctamente (3/4)",
  student: StudentInfo(...),
  failedImages: [
    FailedImage(
      imageNumber: 2,
      reason: "No se detectó rostro"
    )
  ]
)
```

**Error 409 - Conflicto:**
```
Lanza: ConflictException(
  message: "El estudiante ya tiene 3 embeddings registrados...",
  existingEmbeddings: 3
)
```

**Error 404 - No Encontrado:**
```
Lanza: NotFoundException(
  message: "Estudiante con código 1234567890 no encontrado en BIENESTAR"
)
```

**Excepciones:**
- `ArgumentError` - Cantidad inválida de imágenes
- `ConflictException` - Ya tiene embeddings (código 409)
- `NotFoundException` - Estudiante no existe (código 404)
- `TimeoutException` - Timeout después de 2 reintentos
- `SocketException` - Error de red después de 2 reintentos
- `Exception` - Error genérico del servidor

**Uso:**
```dart
try {
  final response = await ApiService.registerStudentEmbeddings(
    codigoEstudiante: "1234567890",
    images: base64Images,
    forceUpdate: false,
  );
  
  if (response.success) {
    // Éxito
    print('Guardadas: ${response.student!.embeddingsSaved}');
    if (response.failedImages != null) {
      // Mostrar advertencia de fallos parciales
    }
  }
} on ConflictException catch (e) {
  // Manejar: "Ya tiene embeddings"
  // Mostrar opción para actualizar (forceUpdate=true)
} on NotFoundException catch (e) {
  // Manejar: "No encontrado"
  // Volver a búsqueda
}
```

---

### 3. Servicio de Compresión de Imágenes

#### compressAndConvertToBase64()

**Propósito:** Comprimir imagen a 800x800px, calidad 85%, y convertir a base64.

**Signature:**
```dart
static Future<String> compressAndConvertToBase64(File imageFile)
```

**Parámetros:**
- `imageFile` (File, required): Archivo de imagen

**Proceso:**
1. Decodifica imagen (soporta JPG, PNG, etc.)
2. Redimensiona a máximo 800x800px (aspecto cuadrado)
3. Codifica como JPEG con calidad 85%
4. Convierte a base64
5. Agrega prefijo `data:image/jpeg;base64,`

**Retorno:**
```
"data:image/jpeg;base64,/9j/4AAQSkZJRg..."
```

**Excepciones:**
- `Exception` - No se pudo decodificar o procesar

**Uso:**
```dart
try {
  File imageFile = File(photo.path);
  String base64Image = await ImageCompressionService.compressAndConvertToBase64(imageFile);
  // base64Image está listo para enviar
} catch (e) {
  // Mostrar error
}
```

---

#### validateImageSize()

**Propósito:** Validar que imagen no exceda 2MB.

**Signature:**
```dart
static Future<bool> validateImageSize(
  File imageFile,
  {int maxMB = 2}
)
```

**Parámetros:**
- `imageFile` (File, required): Archivo de imagen
- `maxMB` (int, optional): Máximo tamaño en MB (default: 2)

**Retorno:**
- `true` - Imagen cumple límite
- `false` - Imagen excede límite o error

**Uso:**
```dart
bool isValid = await ImageCompressionService.validateImageSize(imageFile);
if (!isValid) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Imagen muy grande'))
  );
  return;
}
```

---

#### getFileSizeInMB()

**Propósito:** Obtener tamaño de archivo en MB.

**Signature:**
```dart
static Future<double> getFileSizeInMB(File file)
```

**Retorno:**
- `double` - Tamaño en MB (ej: 2.5)

**Uso:**
```dart
double sizeMB = await ImageCompressionService.getFileSizeInMB(imageFile);
print('Tamaño: ${sizeMB.toStringAsFixed(2)} MB');
```

---

## 🎬 Flujo de Control - FaceRegistrationScreen

```
INICIO
  │
  ├─ Widget Build
  │  │
  │  ├─ currentStudent == null
  │  │  └─ _buildSearchScreen()
  │  │
  │  └─ currentStudent != null
  │     └─ _buildCaptureScreen()
  │
  ├─ PANTALLA BÚSQUEDA
  │  │
  │  ├─ _searchStudent()
  │  │  ├─ Validar código no vacío
  │  │  ├─ ApiService.searchStudent()
  │  │  │  ├─ ÉXITO: Mostrar diálogo confirmación
  │  │  │  └─ ERROR: Mostrar mensaje error
  │  │  │
  │  │  └─ _showConfirmationDialog()
  │  │     ├─ [Cancelar] → _resetForm()
  │  │     └─ [Continuar] → setCurrentStudent() + _resetPhotos()
  │  │
  │  └─ Ir a PANTALLA CAPTURA
  │
  ├─ PANTALLA CAPTURA
  │  │
  │  ├─ _takePicture(photoNumber)
  │  │  ├─ picker.pickImage()
  │  │  ├─ Validar tamaño (≤2MB)
  │  │  │  └─ OK: Guardar en _capturedPhotos[photoNumber]
  │  │  │  └─ NO: Mostrar error "Imagen > 2MB"
  │  │  │
  │  │  └─ setState() → actualizar UI con preview
  │  │
  │  ├─ _registerEmbeddings()
  │  │  ├─ Validar cantidad (3-5 fotos)
  │  │  │  └─ NO: Mostrar error
  │  │  │
  │  │  ├─ ImageCompressionService.compressAndConvertToBase64() × N
  │  │  │  └─ Obtener array de base64
  │  │  │
  │  │  ├─ ApiService.registerStudentEmbeddings()
  │  │  │  ├─ ÉXITO (200/201): _showResultDialog(response)
  │  │  │  ├─ CONFLICTO (409): _showConflictDialog()
  │  │  │  ├─ NO ENCONTRADO (404): _showErrorDialog()
  │  │  │  └─ ERROR: _showErrorDialog()
  │  │  │
  │  │  └─ _showResultDialog() o _showErrorDialog()
  │  │
  │  └─ [Finalizar] → _resetForm() → Volver PANTALLA BÚSQUEDA
  │
  └─ FIN
```

---

## 🔄 State Management (Provider)

### DataProvider

**Propiedades:**
```dart
Teacher? _currentTeacher          // Profesor autenticado
bool _isAuthenticated             // Estado autenticación
List<RegisteredFace> _registeredFaces  // Rostros registrados
List<AttendanceRecord> _attendanceRecords  // Asistencias
Student? _currentStudent          // Estudiante en registro
```

**Métodos relevantes para embeddings:**
```dart
void setCurrentStudent(Student? student) {
  _currentStudent = student;
  notifyListeners();
}

void clearCurrentStudent() {
  _currentStudent = null;
  notifyListeners();
}

Student? get currentStudent => _currentStudent;
```

**Uso en FaceRegistrationScreen:**
```dart
// Leer estado
final currentStudent = Provider.of<DataProvider>(context).currentStudent;

// Actualizar estado
Provider.of<DataProvider>(context, listen: false).setCurrentStudent(student);
```

---

## 📊 Modelos de Datos

### Student

```dart
class Student {
  final String codigo;
  final String nombreCompleto;
  final String nombre;
  final String apellidos;
  final String emailInstitucional;
  final String emailPersonal;
  final String programa;
  final int semestre;
  final String movil;
  final String telefonos;
  final bool tieneEmbeddings;
  final int numEmbeddings;
  
  factory Student.fromJson(Map<String, dynamic> json) { ... }
}
```

**Mapeado de campos:**
```
JSON Server ←→ Dart Class
codigo ←→ codigo
nombre_completo ←→ nombreCompleto
nombre ←→ nombre
apellidos ←→ apellidos
email_institucional ←→ emailInstitucional
email_personal ←→ emailPersonal
programa ←→ programa
semestre ←→ semestre
movil ←→ movil
telefonos ←→ telefonos
tiene_embeddings ←→ tieneEmbeddings
num_embeddings ←→ numEmbeddings
```

### StudentEmbeddingResponse

```dart
class StudentEmbeddingResponse {
  final bool success;
  final String message;
  final StudentInfo? student;
  final List<FailedImage>? failedImages;
  
  factory StudentEmbeddingResponse.fromJson(Map<String, dynamic> json) { ... }
}
```

---

## 🧪 Testing

### Unidades a testear:

1. **ImageCompressionService**
```dart
test('compressAndConvertToBase64 devuelve base64 válido', () async {
  // Crear archivo test
  // Llamar método
  // Verificar formato data:image/jpeg;base64,
});

test('validateImageSize rechaza imagen > 2MB', () async {
  // Crear archivo > 2MB
  // Llamar método
  // Verificar retorna false
});
```

2. **ApiService**
```dart
test('searchStudent llama endpoint correcto', () async {
  // Mock HTTP client
  // Llamar searchStudent()
  // Verificar URL y body
});

test('registerStudentEmbeddings maneja error 409', () async {
  // Mock respuesta 409
  // Verificar lanza ConflictException
});
```

3. **FaceRegistrationScreen**
```dart
testWidgets('muestra pantalla búsqueda inicialmente', (tester) async {
  // Build widget
  // Verificar presencia de TextField y botón búsqueda
});

testWidgets('navega a captura después de confirmación', (tester) async {
  // Mock API response
  // Realizar búsqueda
  // Confirmar
  // Verificar aparece grid 2x2
});
```

---

## 🚨 Manejo de Errores - Códigos

### HTTP Status Codes

```
200 OK              → Éxito
201 Created         → Éxito (recurso creado)
400 Bad Request     → Validación fallida (no implementado)
404 Not Found       → Estudiante no existe → NotFoundException
409 Conflict        → Ya tiene embeddings → ConflictException
500 Server Error    → Error servidor → Exception genérica
```

### Excepciones Personalizadas

```dart
class ConflictException implements Exception {
  final String message;
  final int existingEmbeddings;
  
  ConflictException(this.message, {required this.existingEmbeddings});
}

class NotFoundException implements Exception {
  final String message;
  
  NotFoundException(this.message);
}

class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
}

class SocketException implements Exception {
  final String message;
  
  SocketException(this.message);
}
```

### Catch Precedence

```dart
try {
  // Operación
} on TimeoutException catch (e) {
  // Intentar reintentar (até 2x)
} on SocketException catch (e) {
  // Verificar conexión
} on ConflictException catch (e) {
  // Ofrecerforce_update
} on NotFoundException catch (e) {
  // Volver a búsqueda
} on ArgumentError catch (e) {
  // Validación local fallida
} catch (e) {
  // Error genérico
}
```

---

## ⚡ Optimizaciones Implementadas

1. **Compresión de imágenes**
   - Reduce tamaño de ~5MB a ~100-200KB
   - Calidad preservada (85%)
   - Aspecto cuadrado (800x800) ideal para facial recognition

2. **Reintentos automáticos**
   - Hasta 2 reintentos en timeout
   - Evita falsos negativos por conexión temporal

3. **Timeouts configurables**
   - Búsqueda: 15s (rápido)
   - Embeddings: 60s (procesamiento)
   - Previene bloqueos indefinidos

4. **State management local**
   - Uso de Provider evita dependencias circulares
   - currentStudent persiste durante flujo
   - clearCurrentStudent() al terminar

---

## 🔐 Seguridad

### Validaciones Implementadas:

```dart
// 1. Validación local de código
if (_codigoController.text.isEmpty) { ... }

// 2. Validación de tamaño de imagen
if (!await ImageCompressionService.validateImageSize(file)) { ... }

// 3. Validación de cantidad de fotos
if (images.length < 3 || images.length > 5) {
  throw ArgumentError(...);
}

// 4. Timeout para evitar requests infinitos
http.post(...).timeout(Duration(seconds: 60))

// 5. Reintentos limitados (máximo 2)
while (retries <= maxRetries) { ... }
```

### No Implementado (Fuera de Alcance):
- ❌ Cifrado de imágenes cliente
- ❌ SSL Pinning
- ❌ Almacenamiento seguro local
- ❌ Biometría del dispositivo

---

## 📈 Métricas de Rendimiento

**Tiempos esperados:**
- Búsqueda: 1-2 segundos (servidor rápido)
- Captura de foto: < 1 segundo
- Compresión de 4 fotos: 2-5 segundos
- Envío de 4 fotos comprimidas: 10-30 segundos
- Procesamiento total: 15-40 segundos

**Tamaño de datos:**
- Foto original: 2-5MB
- Foto comprimida (800x800, q85): 100-300KB
- 4 fotos base64 en request: 400-1200KB

---

## 📚 Referencias

- [Flutter HTTP](https://pub.dev/packages/http)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [Image Package](https://pub.dev/packages/image)
- [Provider](https://pub.dev/packages/provider)
- [Material Design 3](https://m3.material.io/)

---

**Versión:** 1.0.0  
**Última actualización:** 11 de Diciembre de 2025  
**Autor:** Sistema de Implementación Automática
