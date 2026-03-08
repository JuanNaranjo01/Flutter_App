class Periodo {
  final int idPeriodo;
  final int anio;
  final String semestre;
  final String nombrePeriodo;
  final String fechaInicio;
  final String fechaFin;
  final List<Corte> cortes;
  final String estado;

  Periodo({
    required this.idPeriodo,
    required this.anio,
    required this.semestre,
    required this.nombrePeriodo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.cortes,
    required this.estado,
  });

  factory Periodo.fromJson(Map<String, dynamic> json) {
    return Periodo(
      idPeriodo: json['id_periodo'] ?? 0,
      anio: json['año'] ?? 0,
      semestre: json['semestre']?.toString() ?? '',
      nombrePeriodo: json['nombre_periodo'] ?? '',
      fechaInicio: json['fecha_inicio'] ?? '',
      fechaFin: json['fecha_fin'] ?? '',
      cortes: (json['cortes'] as List<dynamic>?)
              ?.map((corte) => Corte.fromJson(corte))
              .toList() ??
          [],
      estado: json['estado'] ?? 'inactivo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_periodo': idPeriodo,
      'año': anio,
      'semestre': semestre,
      'nombre_periodo': nombrePeriodo,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'cortes': cortes.map((corte) => corte.toJson()).toList(),
      'estado': estado,
    };
  }
}

class Corte {
  final int numero;
  final String fechaInicio;
  final String fechaFin;
  final String? nombre; // ✅ NUEVO (27/02/2026): Nombre del corte ("Corte 1", "Corte 2", etc.)

  Corte({
    required this.numero,
    required this.fechaInicio,
    required this.fechaFin,
    this.nombre,
  });

  factory Corte.fromJson(Map<String, dynamic> json) {
    return Corte(
      numero: json['numero'] ?? 0,
      fechaInicio: json['fecha_inicio'] ?? '',
      fechaFin: json['fecha_fin'] ?? '',
      nombre: json['nombre']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      if (nombre != null) 'nombre': nombre,
    };
  }
  
  // ✅ NUEVO: Helper para mostrar el nombre del corte
  String get nombreAmigable => nombre ?? 'Corte $numero';
}

class PeriodoActual {
  final int idPeriodo;
  final int anio;
  final String semestre;
  final String nombrePeriodo;
  final int corteActual;
  final String fechaInicioCorte;
  final String fechaFinCorte;

  PeriodoActual({
    required this.idPeriodo,
    required this.anio,
    required this.semestre,
    required this.nombrePeriodo,
    required this.corteActual,
    required this.fechaInicioCorte,
    required this.fechaFinCorte,
  });

  factory PeriodoActual.fromJson(Map<String, dynamic> json) {
    return PeriodoActual(
      idPeriodo: json['id_periodo'] ?? 0,
      anio: json['año'] ?? 0,
      semestre: json['semestre']?.toString() ?? '',
      nombrePeriodo: json['nombre_periodo'] ?? '',
      corteActual: json['corte_actual'] ?? 1,
      fechaInicioCorte: json['fecha_inicio_corte'] ?? '',
      fechaFinCorte: json['fecha_fin_corte'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_periodo': idPeriodo,
      'año': anio,
      'semestre': semestre,
      'nombre_periodo': nombrePeriodo,
      'corte_actual': corteActual,
      'fecha_inicio_corte': fechaInicioCorte,
      'fecha_fin_corte': fechaFinCorte,
    };
  }
}
