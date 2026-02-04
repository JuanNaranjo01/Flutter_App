class AttendanceRecord {
  final String fecha;
  final String codigo;
  final String nombre;
  final String materia;
  final bool asistio;
  final int horasAsistidas;
  final String semestre;
  final String corte;

  AttendanceRecord({
    required this.fecha,
    required this.codigo,
    required this.nombre,
    required this.materia,
    required this.asistio,
    required this.horasAsistidas,
    required this.semestre,
    required this.corte,
  });

  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha,
      'codigo': codigo,
      'nombre': nombre,
      'materia': materia,
      'asistio': asistio,
      'horasAsistidas': horasAsistidas,
      'semestre': semestre,
      'corte': corte,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Mapeo desde backend (get_attendance_history)
    if (json.containsKey('codigo_estudiante')) {
      return AttendanceRecord(
        fecha: json['fecha_registro'] ?? '',
        codigo: json['codigo_estudiante'] ?? '',
        nombre:
            '${json['nombre_estudiante'] ?? ''} ${json['apellidos_estudiante'] ?? ''}'
                .trim(),
        materia: json['semestre'] ?? '',
        asistio: json['estado'] == 'presente' || json['estado'] == 'tardanza',
        horasAsistidas: json['estado'] == 'presente'
            ? 2
            : (json['estado'] == 'tardanza' ? 1 : 0),
        semestre: json['semestre'] ?? 'N/A',
        corte: json['corte']?.toString() ?? 'N/A',
      );
    }

    // Mapeo desde formato antiguo
    return AttendanceRecord(
      fecha: json['fecha'] ?? '',
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      materia: json['materia'] ?? '',
      asistio: json['asistio'] ?? false,
      horasAsistidas: json['horasAsistidas'] ?? 0,
      semestre: json['semestre'] ?? '',
      corte: json['corte'] ?? '',
    );
  }
}
