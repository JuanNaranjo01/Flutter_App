import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../models/reporte_estudiante.dart';

/// 📊 Ejemplo de Pantalla que usa los NUEVOS ENDPOINTS
/// Esta pantalla muestra un reporte detallado de un estudiante
/// usando el endpoint GET /api/reportes/estudiante/{codigo}
class ReporteEstudianteScreen extends StatefulWidget {
  final String codigoEstudiante;
  final String nombreEstudiante;

  const ReporteEstudianteScreen({
    super.key,
    required this.codigoEstudiante,
    required this.nombreEstudiante,
  });

  @override
  State<ReporteEstudianteScreen> createState() =>
      _ReporteEstudianteScreenState();
}

class _ReporteEstudianteScreenState extends State<ReporteEstudianteScreen> {
  ReporteEstudiante? _reporte;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ USAR EL NUEVO ENDPOINT
      final reporte = await ApiService.getReporteEstudiante(
        widget.codigoEstudiante,
        // Opcional: Filtrar por curso o periodo
        // idCurso: 300,
        // idPeriodo: 1,
      );

      setState(() {
        _reporte = reporte;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el reporte: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte de ${widget.nombreEstudiante}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReporte,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarReporte,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_reporte == null || _reporte!.cursos.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles'),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarReporte,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          ..._reporte!.cursos.map((curso) => _buildCursoCard(curso)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _reporte!.estudiante.nombreCompleto,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Código: ${_reporte!.estudiante.codigoEstudiante}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Total cursos: ${_reporte!.totalCursos}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCursoCard(CursoDetalle curso) {
    // ⭐ Determinar color según alerta de suspensión
    final bool enRiesgo = curso.alertas.suspension;
    final cardColor = enRiesgo ? Colors.red[50] : null;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del curso y alerta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    curso.curso.nombreCurso,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (enRiesgo)
                  Chip(
                    label: const Text(
                      '⚠️ EN RIESGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Intensidad horaria: ${curso.curso.intensidadHoraria} horas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),

            // Estadísticas de asistencia
            _buildStatRow('Total Clases', curso.asistencias.totalClases),
            _buildStatRow('Presentes', curso.asistencias.presentes,
                color: Colors.green),
            _buildStatRow('Tardanzas', curso.asistencias.tardanzas,
                color: Colors.orange),
            _buildStatRow('Ausencias', curso.asistencias.ausencias,
                color: Colors.red),

            const Divider(height: 24),

            // ⭐ HORAS FALTADAS (VALOR ENTERO DEL BACKEND)
            _buildStatRow(
              'Horas Faltadas',
              '${curso.horasFaltadas.totalEntero} horas',
              color: Colors.red[700],
              isBold: true,
            ),

            // Valor decimal (opcional, para referencia)
            Text(
              '(${curso.horasFaltadas.totalDecimal.toStringAsFixed(2)} horas con decimales)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),

            const SizedBox(height: 8),

            // ⭐ PORCENTAJES DEL BACKEND
            _buildStatRow(
              'Porcentaje de Asistencia',
              '${curso.porcentajes.asistencia.toStringAsFixed(2)}%',
              color: curso.porcentajes.asistencia >= 80
                  ? Colors.green
                  : Colors.orange,
              isBold: true,
            ),
            _buildStatRow(
              'Porcentaje de Fallas',
              '${curso.porcentajes.fallas.toStringAsFixed(2)}%',
              color: curso.porcentajes.fallas >= 20 ? Colors.red : Colors.green,
              isBold: true,
            ),

            // Alertas
            if (enRiesgo) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este estudiante está en riesgo de suspensión por tener ${curso.porcentajes.fallas.toStringAsFixed(2)}% de fallas (≥20%)',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value,
      {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
