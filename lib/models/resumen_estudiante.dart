/// Modelo para el endpoint GET /api/reportes/estudiante/{codigo_estudiante}/resumen
class ResumenEstudiante {
  final bool success;
  final List<ResumenPeriodo> data;

  ResumenEstudiante({
    required this.success,
    required this.data,
  });

  factory ResumenEstudiante.fromJson(Map<String, dynamic> json) {
    return ResumenEstudiante(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((p) => ResumenPeriodo.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class ResumenPeriodo {
  final PeriodoInfo periodo;
  final AcademicoInfo academico;
  final AsistenciasResumen asistencias;
  final HorasResumen horas;
  final PromediosResumen promedios;
  final AlertasResumen alertas;

  ResumenPeriodo({
    required this.periodo,
    required this.academico,
    required this.asistencias,
    required this.horas,
    required this.promedios,
    required this.alertas,
  });

  factory ResumenPeriodo.fromJson(Map<String, dynamic> json) {
    return ResumenPeriodo(
      periodo: PeriodoInfo.fromJson(json['periodo'] ?? {}),
      academico: AcademicoInfo.fromJson(json['academico'] ?? {}),
      asistencias: AsistenciasResumen.fromJson(json['asistencias'] ?? {}),
      horas: HorasResumen.fromJson(json['horas'] ?? {}),
      promedios: PromediosResumen.fromJson(json['promedios'] ?? {}),
      alertas: AlertasResumen.fromJson(json['alertas'] ?? {}),
    );
  }
}

class PeriodoInfo {
  final int idPeriodo;

  PeriodoInfo({required this.idPeriodo});

  factory PeriodoInfo.fromJson(Map<String, dynamic> json) {
    return PeriodoInfo(
      idPeriodo: json['id_periodo'] ?? 0,
    );
  }
}

class AcademicoInfo {
  final int cursosMatriculados;

  AcademicoInfo({required this.cursosMatriculados});

  factory AcademicoInfo.fromJson(Map<String, dynamic> json) {
    return AcademicoInfo(
      cursosMatriculados: json['cursos_matriculados'] ?? 0,
    );
  }
}

class AsistenciasResumen {
  final int totalClases;
  final int asistencias;
  final int tardanzas;
  final int ausencias;

  AsistenciasResumen({
    required this.totalClases,
    required this.asistencias,
    required this.tardanzas,
    required this.ausencias,
  });

  factory AsistenciasResumen.fromJson(Map<String, dynamic> json) {
    return AsistenciasResumen(
      totalClases: json['total_clases'] ?? 0,
      asistencias: json['asistencias'] ?? 0,
      tardanzas: json['tardanzas'] ?? 0,
      ausencias: json['ausencias'] ?? 0,
    );
  }
}

class HorasResumen {
  final int horasFaltadasTotal; // ENTERO PARA REPORTES
  final int horasTotalesPeriodo;

  HorasResumen({
    required this.horasFaltadasTotal,
    required this.horasTotalesPeriodo,
  });

  factory HorasResumen.fromJson(Map<String, dynamic> json) {
    return HorasResumen(
      horasFaltadasTotal: json['horas_faltadas_total'] ?? 0,
      horasTotalesPeriodo: json['horas_totales_periodo'] ?? 0,
    );
  }
}

class PromediosResumen {
  final double porcentajeAsistencia;
  final double porcentajeFallas;

  PromediosResumen({
    required this.porcentajeAsistencia,
    required this.porcentajeFallas,
  });

  factory PromediosResumen.fromJson(Map<String, dynamic> json) {
    return PromediosResumen(
      porcentajeAsistencia: (json['porcentaje_asistencia'] ?? 0.0).toDouble(),
      porcentajeFallas: (json['porcentaje_fallas'] ?? 0.0).toDouble(),
    );
  }
}

class AlertasResumen {
  final bool tieneAlertaSuspension;

  AlertasResumen({required this.tieneAlertaSuspension});

  factory AlertasResumen.fromJson(Map<String, dynamic> json) {
    return AlertasResumen(
      tieneAlertaSuspension: json['tiene_alerta_suspension'] ?? false,
    );
  }
}
