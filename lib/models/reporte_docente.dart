/// Modelo para el endpoint GET /api/reportes/docente/{correo_docente}
class ReporteDocente {
  final bool success;
  final DocenteInfo docente;
  final int totalCursos;
  final List<CursoDocente> cursos;

  ReporteDocente({
    required this.success,
    required this.docente,
    required this.totalCursos,
    required this.cursos,
  });

  factory ReporteDocente.fromJson(Map<String, dynamic> json) {
    return ReporteDocente(
      success: json['success'] ?? false,
      docente: DocenteInfo.fromJson(json['docente'] ?? {}),
      totalCursos: json['total_cursos'] ?? 0,
      cursos: (json['cursos'] as List<dynamic>?)
              ?.map((c) => CursoDocente.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class DocenteInfo {
  final String nombre;
  final String correo;

  DocenteInfo({
    required this.nombre,
    required this.correo,
  });

  factory DocenteInfo.fromJson(Map<String, dynamic> json) {
    return DocenteInfo(
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
    );
  }
}

class CursoDocente {
  final String curso;
  final HorarioInfo horario;
  final MatriculaInfo matricula;
  final AsistenciasDocente asistencias;
  final EstadisticasDocente estadisticas;

  CursoDocente({
    required this.curso,
    required this.horario,
    required this.matricula,
    required this.asistencias,
    required this.estadisticas,
  });

  factory CursoDocente.fromJson(Map<String, dynamic> json) {
    return CursoDocente(
      curso: json['curso'] ?? '',
      horario: HorarioInfo.fromJson(json['horario'] ?? {}),
      matricula: MatriculaInfo.fromJson(json['matricula'] ?? {}),
      asistencias: AsistenciasDocente.fromJson(json['asistencias'] ?? {}),
      estadisticas: EstadisticasDocente.fromJson(json['estadisticas'] ?? {}),
    );
  }
}

class HorarioInfo {
  final String dia;
  final String horaInicio;
  final String horaFin;

  HorarioInfo({
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
  });

  factory HorarioInfo.fromJson(Map<String, dynamic> json) {
    return HorarioInfo(
      dia: json['dia'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
    );
  }
}

class MatriculaInfo {
  final int estudiantesMatriculados;
  final int registrosTotales;

  MatriculaInfo({
    required this.estudiantesMatriculados,
    required this.registrosTotales,
  });

  factory MatriculaInfo.fromJson(Map<String, dynamic> json) {
    return MatriculaInfo(
      estudiantesMatriculados: json['estudiantes_matriculados'] ?? 0,
      registrosTotales: json['registros_totales'] ?? 0,
    );
  }
}

class AsistenciasDocente {
  final int asistencias;
  final int conTardanza;
  final int ausencias;

  AsistenciasDocente({
    required this.asistencias,
    required this.conTardanza,
    required this.ausencias,
  });

  factory AsistenciasDocente.fromJson(Map<String, dynamic> json) {
    return AsistenciasDocente(
      asistencias: json['asistencias'] ?? 0,
      conTardanza: json['con_tardanza'] ?? 0,
      ausencias: json['ausencias'] ?? 0,
    );
  }
}

class EstadisticasDocente {
  final double porcentajeAsistencia;

  EstadisticasDocente({required this.porcentajeAsistencia});

  factory EstadisticasDocente.fromJson(Map<String, dynamic> json) {
    return EstadisticasDocente(
      porcentajeAsistencia: (json['porcentaje_asistencia'] ?? 0.0).toDouble(),
    );
  }
}
