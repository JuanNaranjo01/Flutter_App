/// Modelo para el endpoint GET /api/reportes/estudiantes-en-riesgo
class EstudiantesEnRiesgoResponse {
  final bool success;
  final int total;
  final List<EstudianteEnRiesgo> estudiantes;

  EstudiantesEnRiesgoResponse({
    required this.success,
    required this.total,
    required this.estudiantes,
  });

  factory EstudiantesEnRiesgoResponse.fromJson(Map<String, dynamic> json) {
    return EstudiantesEnRiesgoResponse(
      success: json['success'] ?? false,
      total: json['total'] ?? 0,
      estudiantes: (json['estudiantes'] as List<dynamic>?)
              ?.map((e) => EstudianteEnRiesgo.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EstudianteEnRiesgo {
  final String codigoEstudiante;
  final String nombreCompleto;
  final String curso;
  final int horasFaltadas; // ENTERO PARA REPORTES
  final int horasTotales;
  final double porcentajeFallas;
  final DetalleRiesgo detalle;

  EstudianteEnRiesgo({
    required this.codigoEstudiante,
    required this.nombreCompleto,
    required this.curso,
    required this.horasFaltadas,
    required this.horasTotales,
    required this.porcentajeFallas,
    required this.detalle,
  });

  factory EstudianteEnRiesgo.fromJson(Map<String, dynamic> json) {
    return EstudianteEnRiesgo(
      codigoEstudiante: json['codigo_estudiante'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      curso: json['curso'] ?? '',
      horasFaltadas: json['horas_faltadas'] ?? 0,
      horasTotales: json['horas_totales'] ?? 0,
      porcentajeFallas: (json['porcentaje_fallas'] ?? 0.0).toDouble(),
      detalle: DetalleRiesgo.fromJson(json['detalle'] ?? {}),
    );
  }
}

class DetalleRiesgo {
  final int totalClases;
  final int ausencias;
  final int tardanzas;

  DetalleRiesgo({
    required this.totalClases,
    required this.ausencias,
    required this.tardanzas,
  });

  factory DetalleRiesgo.fromJson(Map<String, dynamic> json) {
    return DetalleRiesgo(
      totalClases: json['total_clases'] ?? 0,
      ausencias: json['ausencias'] ?? 0,
      tardanzas: json['tardanzas'] ?? 0,
    );
  }
}
