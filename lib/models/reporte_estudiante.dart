/// Modelo para el endpoint GET /api/reportes/estudiante/{codigo_estudiante}
class ReporteEstudiante {
  final bool success;
  final EstudianteInfo estudiante;
  final int totalCursos;
  final List<CursoDetalle> cursos;

  ReporteEstudiante({
    required this.success,
    required this.estudiante,
    required this.totalCursos,
    required this.cursos,
  });

  factory ReporteEstudiante.fromJson(Map<String, dynamic> json) {
    return ReporteEstudiante(
      success: json['success'] ?? false,
      estudiante: EstudianteInfo.fromJson(json['estudiante'] ?? {}),
      totalCursos: json['total_cursos'] ?? 0,
      cursos: (json['cursos'] as List<dynamic>?)
              ?.map((c) => CursoDetalle.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class EstudianteInfo {
  final String codigoEstudiante;
  final String nombreCompleto;

  EstudianteInfo({
    required this.codigoEstudiante,
    required this.nombreCompleto,
  });

  factory EstudianteInfo.fromJson(Map<String, dynamic> json) {
    return EstudianteInfo(
      codigoEstudiante: json['codigo_estudiante'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
    );
  }
}

class CursoDetalle {
  final CursoInfo curso;
  final AsistenciasInfo asistencias;
  final HorasFaltadas horasFaltadas;
  final Porcentajes porcentajes;
  final Alertas alertas;

  CursoDetalle({
    required this.curso,
    required this.asistencias,
    required this.horasFaltadas,
    required this.porcentajes,
    required this.alertas,
  });

  factory CursoDetalle.fromJson(Map<String, dynamic> json) {
    return CursoDetalle(
      curso: CursoInfo.fromJson(json['curso'] ?? {}),
      asistencias: AsistenciasInfo.fromJson(json['asistencias'] ?? {}),
      horasFaltadas: HorasFaltadas.fromJson(json['horas_faltadas'] ?? {}),
      porcentajes: Porcentajes.fromJson(json['porcentajes'] ?? {}),
      alertas: Alertas.fromJson(json['alertas'] ?? {}),
    );
  }
}

class CursoInfo {
  final int idCurso;
  final String nombreCurso;
  final int intensidadHoraria;

  CursoInfo({
    required this.idCurso,
    required this.nombreCurso,
    required this.intensidadHoraria,
  });

  factory CursoInfo.fromJson(Map<String, dynamic> json) {
    return CursoInfo(
      idCurso: json['id_curso'] ?? 0,
      nombreCurso: json['nombre_curso'] ?? '',
      intensidadHoraria: json['intensidad_horaria'] ?? 0,
    );
  }
}

class AsistenciasInfo {
  final int totalClases;
  final int presentes;
  final int tardanzas;
  final int ausencias;

  AsistenciasInfo({
    required this.totalClases,
    required this.presentes,
    required this.tardanzas,
    required this.ausencias,
  });

  factory AsistenciasInfo.fromJson(Map<String, dynamic> json) {
    return AsistenciasInfo(
      totalClases: json['total_clases'] ?? 0,
      presentes: json['presentes'] ?? 0,
      tardanzas: json['tardanzas'] ?? 0,
      ausencias: json['ausencias'] ?? 0,
    );
  }
}

class HorasFaltadas {
  final int totalEntero; // ⭐ USAR ESTE PARA REPORTES
  final double totalDecimal;

  HorasFaltadas({
    required this.totalEntero,
    required this.totalDecimal,
  });

  factory HorasFaltadas.fromJson(Map<String, dynamic> json) {
    return HorasFaltadas(
      totalEntero: json['total_entero'] ?? 0,
      totalDecimal: (json['total_decimal'] ?? 0.0).toDouble(),
    );
  }
}

class Porcentajes {
  final double asistencia;
  final double fallas;

  Porcentajes({
    required this.asistencia,
    required this.fallas,
  });

  factory Porcentajes.fromJson(Map<String, dynamic> json) {
    return Porcentajes(
      asistencia: (json['asistencia'] ?? 0.0).toDouble(),
      fallas: (json['fallas'] ?? 0.0).toDouble(),
    );
  }
}

class Alertas {
  final bool suspension;

  Alertas({required this.suspension});

  factory Alertas.fromJson(Map<String, dynamic> json) {
    return Alertas(
      suspension: json['suspension'] ?? false,
    );
  }
}
