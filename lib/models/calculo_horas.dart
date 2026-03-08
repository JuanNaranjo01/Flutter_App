/// Modelo para el endpoint POST /api/calculos/horas-faltadas
class CalculoHorasRequest {
  final double horasAusencias;
  final int minutosTardanza;

  CalculoHorasRequest({
    required this.horasAusencias,
    required this.minutosTardanza,
  });

  Map<String, dynamic> toJson() {
    return {
      'horas_ausencias': horasAusencias,
      'minutos_tardanza': minutosTardanza,
    };
  }
}

class CalculoHorasResponse {
  final bool success;
  final ResultadoCalculo resultado;

  CalculoHorasResponse({
    required this.success,
    required this.resultado,
  });

  factory CalculoHorasResponse.fromJson(Map<String, dynamic> json) {
    return CalculoHorasResponse(
      success: json['success'] ?? false,
      resultado: ResultadoCalculo.fromJson(json['resultado'] ?? {}),
    );
  }
}

class ResultadoCalculo {
  final double horasTardanzaEquivalentes;
  final double horasTotalDecimal;
  final int horasTotalEntero; // ⭐ Para reportes oficiales
  final String explicacion;

  ResultadoCalculo({
    required this.horasTardanzaEquivalentes,
    required this.horasTotalDecimal,
    required this.horasTotalEntero,
    required this.explicacion,
  });

  factory ResultadoCalculo.fromJson(Map<String, dynamic> json) {
    return ResultadoCalculo(
      horasTardanzaEquivalentes:
          (json['horas_tardanza_equivalentes'] ?? 0.0).toDouble(),
      horasTotalDecimal: (json['horas_total_decimal'] ?? 0.0).toDouble(),
      horasTotalEntero: json['horas_total_entero'] ?? 0,
      explicacion: json['explicacion'] ?? '',
    );
  }
}
