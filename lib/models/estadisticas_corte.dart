class EstadisticasCorte {
  final String curso;
  final int anio;
  final String semestre;
  final String periodo;
  final int corte;
  final int totalRegistros;
  final int presentes;
  final int tardanzas;
  final int ausentes;
  final double porcentajeAsistencia;
  final double horasFaltadas;
  final bool alertaSuspension;

  EstadisticasCorte({
    required this.curso,
    required this.anio,
    required this.semestre,
    required this.periodo,
    required this.corte,
    required this.totalRegistros,
    required this.presentes,
    required this.tardanzas,
    required this.ausentes,
    required this.porcentajeAsistencia,
    required this.horasFaltadas,
    required this.alertaSuspension,
  });

  factory EstadisticasCorte.fromJson(Map<String, dynamic> json) {
    return EstadisticasCorte(
      curso: json['curso'] ?? '',
      anio: json['año'] ?? 0,
      semestre: json['semestre']?.toString() ?? '',
      periodo: json['periodo'] ?? '',
      corte: json['corte'] ?? 0,
      totalRegistros: json['total_registros'] ?? 0,
      presentes: json['presentes'] ?? 0,
      tardanzas: json['tardanzas'] ?? 0,
      ausentes: json['ausentes'] ?? 0,
      porcentajeAsistencia: (json['porcentaje_asistencia'] ?? 0.0).toDouble(),
      horasFaltadas: (json['horas_faltadas'] ?? 0.0).toDouble(),
      alertaSuspension: json['alerta_suspension'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curso': curso,
      'año': anio,
      'semestre': semestre,
      'periodo': periodo,
      'corte': corte,
      'total_registros': totalRegistros,
      'presentes': presentes,
      'tardanzas': tardanzas,
      'ausentes': ausentes,
      'porcentaje_asistencia': porcentajeAsistencia,
      'horas_faltadas': horasFaltadas,
      'alerta_suspension': alertaSuspension,
    };
  }
}

class AsistenciaCorte {
  final int idAsistencia;
  final String fecha;
  final String estado;
  final String curso;
  final String periodo;
  final int corte;
  final int? anio;
  final String? semestre;

  AsistenciaCorte({
    required this.idAsistencia,
    required this.fecha,
    required this.estado,
    required this.curso,
    required this.periodo,
    required this.corte,
    this.anio,
    this.semestre,
  });

  factory AsistenciaCorte.fromJson(Map<String, dynamic> json) {
    return AsistenciaCorte(
      idAsistencia: json['id_asistencia'] ?? 0,
      fecha: json['fecha'] ?? '',
      estado: json['estado'] ?? '',
      curso: json['curso'] ?? '',
      periodo: json['periodo'] ?? '',
      corte: json['corte'] ?? 0,
      anio: json['año'],
      semestre: json['semestre']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_asistencia': idAsistencia,
      'fecha': fecha,
      'estado': estado,
      'curso': curso,
      'periodo': periodo,
      'corte': corte,
      'año': anio,
      'semestre': semestre,
    };
  }
}
