class CourseStudent {
  final String codigo;
  final String nombreCompleto;
  final String emailInstitucional;
  final String programa;
  final int semestre;
  final int asistencias; // Presentes (puntuales)
  final int tardanzas;
  final int ausencias;
  final int totalClases;
  final double porcentajeAsistencia;
  final double horasFaltadas; // Horas faltadas (incluye ausencias + tardanzas/60)
  final int minutosTardanza; // Total minutos de tardanza
  // ✅ NUEVO (27/02/2026): Cambios del backend
  final int asistenciasTotales; // Presentes + Tardanzas (porque tardanza = asistió aunque tarde)
  final int totalFaltas; // AHORA: Solo ausencias (antes incluía tardanzas)

  CourseStudent({
    required this.codigo,
    required this.nombreCompleto,
    required this.emailInstitucional,
    required this.programa,
    required this.semestre,
    required this.asistencias,
    required this.tardanzas,
    required this.ausencias,
    required this.totalClases,
    required this.porcentajeAsistencia,
    required this.horasFaltadas,
    required this.minutosTardanza,
    required this.asistenciasTotales,
    required this.totalFaltas,
  });

  factory CourseStudent.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 DEBUG CourseStudent.fromJson - JSON: $json');
      
      // ✅ ESTRUCTURA SEGÚN GUÍA DE INTEGRACIÓN (26/02/2026)
      // Campos principales
      final codigo = json['codigo_estudiante'] ?? json['codigo'] ?? '';
      final nombre = json['nombre_completo'] ?? json['nombre'] ?? '';
      final email = json['email_institucional'] ?? json['email'] ?? '';
      final programa = json['programa_academico'] ?? json['programa'] ?? '';
      final semestre = json['semestre'] ?? 0;
      
      // ✅ Estadísticas vienen en objeto 'estadisticas' (estructura plana)
      final stats = json['estadisticas'] ?? {};
      
      print('🔍 DEBUG stats completo: $stats');
      print('🔍 DEBUG total_horas_falta: ${stats['total_horas_falta']}');
      print('🔍 DEBUG horas_faltadas: ${stats['horas_faltadas']}');
      
      final totalClases = stats['total_clases'] ?? 0;
      final asistencias = stats['presentes'] ?? 0;
      final tardanzas = stats['tardanzas'] ?? 0;
      final ausencias = stats['ausencias'] ?? 0;
      
      // ✅ NUEVO (27/02/2026): Cambios del backend
      final asistenciasTotales = stats['asistencias_totales'] ?? (asistencias + tardanzas);
      final totalFaltas = stats['total_faltas'] ?? ausencias; // Ahora solo ausencias
      
      // ✅ Horas faltadas y minutos vienen DIRECTOS en estadísticas (NO anidados)
      // Estructura: { "estadisticas": { "horas_faltadas": 5.83, "minutos_tardanza": 150 } }
      // ⚠️ horas_faltadas es FLOAT porque incluye: ausencias + (minutos_tardanza/60)
      // ✅ ACTUALIZADO (27/02/2026): Buscar ambos nombres por compatibilidad
      final horasFaltadasRaw = stats['total_horas_falta'] ?? stats['horas_faltadas'] ?? 0;
      final horasFaltadas = horasFaltadasRaw is double 
          ? horasFaltadasRaw 
          : (horasFaltadasRaw is int ? horasFaltadasRaw.toDouble() : 0.0);
      
      print('🔍 DEBUG horasFaltadasRaw: $horasFaltadasRaw (tipo: ${horasFaltadasRaw.runtimeType})');
      print('🔍 DEBUG horasFaltadas final: $horasFaltadas');
      
      final minutosTardanzaRaw = stats['minutos_tardanza'] ?? 0;
      final minutosTardanza = minutosTardanzaRaw is int 
          ? minutosTardanzaRaw 
          : int.tryParse(minutosTardanzaRaw.toString()) ?? 0;
      
      // ✅ Porcentaje de asistencia (ya calculado por el backend)
      final porcentaje = stats['porcentaje_asistencia'] ?? 0.0;
      
      print('✅ CourseStudent parseado: $codigo - $nombre');
      print('   📊 Estadísticas: Presentes=$asistencias, Tardanzas=$tardanzas, Ausencias=$ausencias, Total=$totalClases');
      print('   📊 Asistencias Totales=$asistenciasTotales, Total Faltas=$totalFaltas');
      print('   ⏱️ Horas Faltadas=$horasFaltadas, Minutos Tardanza=$minutosTardanza, Asistencia=$porcentaje%');
      
      return CourseStudent(
        codigo: codigo.toString(),
        nombreCompleto: nombre.toString(),
        emailInstitucional: email.toString(),
        programa: programa.toString(),
        semestre: semestre is int ? semestre : int.tryParse(semestre.toString()) ?? 0,
        asistencias: asistencias is int ? asistencias : int.tryParse(asistencias.toString()) ?? 0,
        tardanzas: tardanzas is int ? tardanzas : int.tryParse(tardanzas.toString()) ?? 0,
        ausencias: ausencias is int ? ausencias : int.tryParse(ausencias.toString()) ?? 0,
        totalClases: totalClases is int ? totalClases : int.tryParse(totalClases.toString()) ?? 0,
        porcentajeAsistencia: porcentaje is double 
            ? porcentaje 
            : (porcentaje is int ? porcentaje.toDouble() : double.tryParse(porcentaje.toString()) ?? 0.0),
        horasFaltadas: horasFaltadas,
        minutosTardanza: minutosTardanza,
        asistenciasTotales: asistenciasTotales is int ? asistenciasTotales : int.tryParse(asistenciasTotales.toString()) ?? 0,
        totalFaltas: totalFaltas is int ? totalFaltas : int.tryParse(totalFaltas.toString()) ?? 0,
      );
    } catch (e) {
      print('❌ ERROR parseando CourseStudent: $e');
      print('❌ JSON problemático: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre_completo': nombreCompleto,
      'email_institucional': emailInstitucional,
      'programa': programa,
      'semestre': semestre,
      'asistencias': asistencias,
      'tardanzas': tardanzas,
      'ausencias': ausencias,
      'total_clases': totalClases,
      'porcentaje_asistencia': porcentajeAsistencia,
      'horas_faltadas': horasFaltadas,
      'minutos_tardanza': minutosTardanza,
      'asistencias_totales': asistenciasTotales,
      'total_faltas': totalFaltas,
    };
  }
  
  // ✅ NUEVO: Helpers para mostrar datos claramente
  int get faltasReales => totalFaltas; // Solo ausencias
  bool get tieneRetrasos => tardanzas > 0;
  String get resumenAsistencia => '$asistenciasTotales asistencias ($asistencias puntuales${tieneRetrasos ? " + $tardanzas tarde" : ""}), $faltasReales falta${faltasReales != 1 ? "s" : ""}';
}
