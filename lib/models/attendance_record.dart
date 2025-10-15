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
    return AttendanceRecord(
      fecha: json['fecha'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      materia: json['materia'],
      asistio: json['asistio'],
      horasAsistidas: json['horasAsistidas'],
      semestre: json['semestre'],
      corte: json['corte'],
    );
  }
}
