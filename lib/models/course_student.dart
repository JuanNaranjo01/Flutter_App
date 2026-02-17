class CourseStudent {
  final String codigo;
  final String nombreCompleto;
  final String emailInstitucional;
  final String programa;
  final int semestre;
  final int asistencias;
  final int ausencias;
  final double porcentajeAsistencia;

  CourseStudent({
    required this.codigo,
    required this.nombreCompleto,
    required this.emailInstitucional,
    required this.programa,
    required this.semestre,
    required this.asistencias,
    required this.ausencias,
    required this.porcentajeAsistencia,
  });

  factory CourseStudent.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 DEBUG CourseStudent.fromJson - JSON: $json');
      
      // Buscar código del estudiante
      final codigo = json['codigo'] ?? 
                     json['codigo_estudiante'] ??  // ✅ El servidor envía esto
                     json['student_code'] ?? 
                     json['codigo_estudiante'] ?? '';
      
      // Buscar nombre completo
      final nombre = json['nombre_completo'] ??  // ✅ El servidor envía esto
                     json['nombre'] ?? 
                     json['full_name'] ?? 
                     json['name'] ?? '';
      
      // Buscar email (puede no venir en la lista)
      final email = json['email_institucional'] ?? 
                    json['email'] ?? 
                    json['correo'] ?? '';
      
      // Buscar programa
      final programa = json['programa'] ?? 
                       json['programa_academico'] ??  // ✅ El servidor envía esto
                       json['program'] ?? 
                       json['carrera'] ?? '';
      
      // Buscar semestre
      final semestre = json['semestre'] ?? 
                       json['semester'] ?? 0;
      
      // ✅ Las estadísticas vienen en un objeto anidado 'estadisticas'
      final stats = json['estadisticas'] ?? {};
      
      // Buscar asistencias (presentes)
      final asistencias = stats['presentes'] ??  // ✅ El servidor envía esto
                          stats['asistencias'] ?? 
                          json['asistencias'] ?? 
                          json['attendances'] ?? 
                          json['presente'] ?? 0;
      
      // Buscar tardanzas
      final tardanzas = stats['tardanzas'] ?? 
                        stats['tardy'] ?? 
                        json['tardanzas'] ?? 0;
      
      // Buscar ausencias
      final ausencias = stats['ausencias'] ??  // ✅ El servidor envía esto
                        json['ausencias'] ?? 
                        json['absences'] ?? 
                        json['faltas'] ?? 0;
      
      // Buscar total de clases
      final totalClases = stats['total_clases'] ??  // ✅ El servidor envía esto
                         json['total_clases'] ?? 0;
      
      // Calcular porcentaje de asistencia
      // Las tardanzas ya están incluidas en el campo 'asistencias' del servidor
      // NO sumar tardanzas nuevamente para evitar porcentajes mayores a 100%
      final porcentajeFallas = stats['porcentaje_fallas'] ?? 0.0;
      final porcentaje = totalClases > 0
          ? ((asistencias / totalClases) * 100)
          : (100.0 - porcentajeFallas);
      
      print('✅ CourseStudent parseado: $codigo - $nombre (Asist: $asistencias, Tard: $tardanzas, Ausenc: $ausencias, Total: $totalClases)');
      
      return CourseStudent(
        codigo: codigo.toString(),
        nombreCompleto: nombre.toString(),
        emailInstitucional: email.toString(),
        programa: programa.toString(),
        semestre: semestre is int ? semestre : int.tryParse(semestre.toString()) ?? 0,
        asistencias: asistencias is int ? asistencias : int.tryParse(asistencias.toString()) ?? 0,
        ausencias: ausencias is int ? ausencias : int.tryParse(ausencias.toString()) ?? 0,
        porcentajeAsistencia: porcentaje is double ? porcentaje : 
                              (porcentaje is int ? porcentaje.toDouble() : 
                               double.tryParse(porcentaje.toString()) ?? 0.0),
      );
    } catch (e) {
      print('❌ ERROR parseando CourseStudent: $e');
      print('❌ JSON problemático: $json');
      rethrow;
    }
  }

  int get totalClases => asistencias + ausencias;

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre_completo': nombreCompleto,
      'email_institucional': emailInstitucional,
      'programa': programa,
      'semestre': semestre,
      'asistencias': asistencias,
      'ausencias': ausencias,
      'porcentaje_asistencia': porcentajeAsistencia,
    };
  }
}
