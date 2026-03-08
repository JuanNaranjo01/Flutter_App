class AttendanceDetail {
  final int id;
  final String fecha;
  final String hora;
  final String estado; // 'presente', 'ausente', 'tardanza'
  final String? observacion;
  final String? asignatura;
  final int? minutosTardanza;
  final bool? justificada;
  final String? horaInicioClase;
  final String? horaFinClase;
  // ✅ NUEVO (27/02/2026): Horas de falta equivalentes
  final double horasFaltaEquivalentes; // 0.0 para presente, calculado para tardanzas/ausencias
  final String? descripcionEstado; // Ej: "Tardanza (20 minutos)", "Presente", "Ausente"

  AttendanceDetail({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.estado,
    this.observacion,
    this.asignatura,
    this.minutosTardanza,
    this.justificada,
    this.horaInicioClase,
    this.horaFinClase,
    this.horasFaltaEquivalentes = 0.0,
    this.descripcionEstado,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    // El servidor envía 'id_asistencia', 'fecha_registro', 'motivo_justificacion', etc.
    final idAsistencia = json['id'] ?? json['id_asistencia'] ?? 0;
    
    // El servidor envía 'fecha_registro' en formato: "2026-02-09 04:02:01"
    final fechaRegistro = json['fecha'] ?? 
                          json['fecha_registro'] ?? 
                          json['fecha_formateada'] ?? '';
    
    // Separar fecha y hora
    String fecha = '';
    String hora = '';
    
    if (fechaRegistro.contains(' ')) {
      final parts = fechaRegistro.split(' ');
      fecha = parts[0]; // "2026-02-09"
      hora = parts.length > 1 ? parts[1] : ''; // "04:02:01"
    } else {
      fecha = fechaRegistro;
      hora = json['hora'] ?? '';
    }
    
    // Si hay fecha_formateada (ej: "09/02/2026 04:02"), usarla para fecha amigable
    final fechaFormateada = json['fecha_formateada'];
    if (fechaFormateada != null && fechaFormateada.toString().isNotEmpty) {
      if (fechaFormateada.contains(' ')) {
        final parts = fechaFormateada.split(' ');
        fecha = parts[0]; // "09/02/2026"
        if (parts.length > 1 && hora.isEmpty) {
          hora = parts[1]; // "04:02"
        }
      }
    }
    
    final estado = json['estado'] ?? 'ausente';
    final observacion = json['observacion'] ?? json['motivo_justificacion'];
    
    // ✅ NUEVO (27/02/2026): Horas de falta equivalentes y descripción del estado
    final horasFaltaRaw = json['horas_falta_equivalentes'] ?? 0;
    final horasFaltaEquivalentes = horasFaltaRaw is double 
        ? horasFaltaRaw 
        : (horasFaltaRaw is int ? horasFaltaRaw.toDouble() : 0.0);
    
    final descripcionEstado = json['descripcion_estado']?.toString();
    
    print('📝 AttendanceDetail parseado: ID=$idAsistencia, Fecha=$fecha, Hora=$hora, Estado=$estado, Horas Falta=$horasFaltaEquivalentes');
    
    return AttendanceDetail(
      id: idAsistencia is int ? idAsistencia : int.tryParse(idAsistencia.toString()) ?? 0,
      fecha: fecha,
      hora: hora,
      estado: estado.toString(),
      observacion: observacion?.toString(),
      asignatura: json['asignatura']?.toString(),
      minutosTardanza: json['minutos_tardanza'] is int 
          ? json['minutos_tardanza'] 
          : (json['minutos_tardanza'] != null ? int.tryParse(json['minutos_tardanza'].toString()) : null),
      justificada: json['justificada'] is bool ? json['justificada'] : null,
      horaInicioClase: json['hora_inicio_clase']?.toString() ?? json['hora_inicio']?.toString(),
      horaFinClase: json['hora_fin_clase']?.toString() ?? json['hora_fin']?.toString(),
      horasFaltaEquivalentes: horasFaltaEquivalentes,
      descripcionEstado: descripcionEstado,
    );
  }

  bool get isPresente => estado.toLowerCase() == 'presente';
  bool get isAusente => estado.toLowerCase() == 'ausente';
  bool get isTardanza => estado.toLowerCase() == 'tardanza';
  
  // ✅ NUEVO: Helper para mostrar descripción legible
  String get descripcionAmigable {
    if (descripcionEstado != null && descripcionEstado!.isNotEmpty) {
      return descripcionEstado!;
    }
    
    // Fallback si no viene del backend
    if (isPresente) return 'Presente';
    if (isAusente) return 'Ausente';
    if (isTardanza && minutosTardanza != null) {
      return 'Tardanza ($minutosTardanza minutos)';
    }
    return estado;
  }
  
  // ✅ NUEVO: Indica si tiene faltas
  bool get tieneFaltas => horasFaltaEquivalentes > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'hora': hora,
      'estado': estado,
      'observacion': observacion,
      'asignatura': asignatura,
      'minutos_tardanza': minutosTardanza,
      'justificada': justificada,
      'hora_inicio_clase': horaInicioClase,
      'hora_fin_clase': horaFinClase,
      'horas_falta_equivalentes': horasFaltaEquivalentes,
      'descripcion_estado': descripcionEstado,
    };
  }
}
