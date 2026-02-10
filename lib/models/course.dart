class Course {
  final int id;
  final String nombre;
  final String codigo;
  final int creditos;
  final String descripcion;
  final int estudiantesRegistrados;

  Course({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.creditos,
    required this.descripcion,
    required this.estudiantesRegistrados,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // Support both snake_case and camelCase from server
    // El servidor puede enviar diferentes formatos
    try {
      print('🔍 DEBUG Course.fromJson - JSON recibido: $json');
      
      // Buscar el ID del curso
      final id = json['id'] ?? 
                 json['id_curso'] ??  // ✅ El servidor envía esto
                 json['curso_id'] ?? 
                 json['cursoId'] ?? 
                 json['courseId'] ?? 0;
      
      // Buscar el nombre del curso
      final nombre = json['nombre'] ?? 
                     json['nombre_curso'] ??  // ✅ El servidor envía esto
                     json['curso_nombre'] ?? 
                     json['name'] ?? 
                     json['courseName'] ?? 
                     json['curso'] ?? '';
      
      // Buscar el código del curso
      final codigo = json['codigo'] ?? 
                     json['codigo_curso'] ??  // ✅ El servidor envía esto
                     json['curso_codigo'] ?? 
                     json['code'] ?? 
                     json['courseCode'] ?? '';
      
      // Buscar créditos
      final creditos = json['creditos'] ?? 
                       json['credits'] ?? 0;
      
      // Buscar descripción
      final descripcion = json['descripcion'] ?? 
                          json['description'] ?? 
                          json['programa_academico'] ?? '';  // ✅ Usar programa_academico como descripción
      
      // Buscar número de estudiantes
      final estudiantes = json['estudiantes_registrados'] ?? 
                          json['total_estudiantes'] ??  // ✅ El servidor envía esto
                          json['num_estudiantes'] ??
                          json['students'] ?? 0;
      
      print('✅ DEBUG Course parseado - ID: $id, Nombre: $nombre, Código: $codigo, Estudiantes: $estudiantes');
      
      return Course(
        id: id is int ? id : int.tryParse(id.toString()) ?? 0,
        nombre: nombre.toString(),
        codigo: codigo.toString(),
        creditos: creditos is int ? creditos : int.tryParse(creditos.toString()) ?? 0,
        descripcion: descripcion.toString(),
        estudiantesRegistrados: estudiantes is int ? estudiantes : int.tryParse(estudiantes.toString()) ?? 0,
      );
    } catch (e) {
      print('❌ ERROR parseando Course: $e');
      print('❌ JSON problemático: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'creditos': creditos,
      'descripcion': descripcion,
      'estudiantes_registrados': estudiantesRegistrados,
    };
  }
}
