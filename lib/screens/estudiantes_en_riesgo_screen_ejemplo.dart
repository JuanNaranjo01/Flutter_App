import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../models/estudiante_en_riesgo.dart';

/// 📊 Ejemplo de Pantalla: Estudiantes en Riesgo
/// Esta pantalla muestra estudiantes con ≥20% de fallas
/// usando el endpoint GET /api/reportes/estudiantes-en-riesgo
class EstudiantesEnRiesgoScreen extends StatefulWidget {
  const EstudiantesEnRiesgoScreen({super.key});

  @override
  State<EstudiantesEnRiesgoScreen> createState() =>
      _EstudiantesEnRiesgoScreenState();
}

class _EstudiantesEnRiesgoScreenState extends State<EstudiantesEnRiesgoScreen> {
  List<EstudianteEnRiesgo> _estudiantes = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _corteSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ USAR EL NUEVO ENDPOINT
      final response = await ApiService.getEstudiantesEnRiesgo(
        corte: _corteSeleccionado, // Filtro opcional
        // También se puede filtrar por:
        // idPeriodo: 1,
        // idCurso: 300,
      );

      setState(() {
        _estudiantes = response.estudiantes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar estudiantes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes en Riesgo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEstudiantes,
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
              onPressed: _cargarEstudiantes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_estudiantes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              '¡Excelente!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No hay estudiantes en riesgo de suspensión',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEstudiantes,
      child: Column(
        children: [
          // Header con contador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red[100],
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_estudiantes.length} estudiante${_estudiantes.length != 1 ? 's' : ''} en riesgo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de estudiantes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _estudiantes.length,
              itemBuilder: (context, index) {
                return _buildEstudianteCard(_estudiantes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstudianteCard(EstudianteEnRiesgo estudiante) {
    return Card(
      color: Colors.red[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y badge de porcentaje
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estudiante.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${estudiante.codigoEstudiante}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // ⭐ Badge con porcentaje de fallas
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${estudiante.porcentajeFallas.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Información del curso
            Row(
              children: [
                const Icon(Icons.book, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    estudiante.curso,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ⭐ Horas faltadas (VALOR ENTERO DEL BACKEND)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    'Horas Faltadas',
                    '${estudiante.horasFaltadas}',
                    Colors.red,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  _buildStat(
                    'Horas Totales',
                    '${estudiante.horasTotales}',
                    Colors.grey[700]!,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Detalle de asistencias
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailChip(
                  'Clases: ${estudiante.detalle.totalClases}',
                  Colors.blue,
                ),
                _buildDetailChip(
                  'Ausencias: ${estudiante.detalle.ausencias}',
                  Colors.red,
                ),
                _buildDetailChip(
                  'Tardanzas: ${estudiante.detalle.tardanzas}',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
    );
  }

  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Corte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int?>(
              title: const Text('Todos'),
              value: null,
              groupValue: _corteSeleccionado,
              onChanged: (value) {
                setState(() => _corteSeleccionado = value);
                Navigator.pop(context);
                _cargarEstudiantes();
              },
            ),
            RadioListTile<int?>(
              title: const Text('Corte 1'),
              value: 1,
              groupValue: _corteSeleccionado,
              onChanged: (value) {
                setState(() => _corteSeleccionado = value);
                Navigator.pop(context);
                _cargarEstudiantes();
              },
            ),
            RadioListTile<int?>(
              title: const Text('Corte 2'),
              value: 2,
              groupValue: _corteSeleccionado,
              onChanged: (value) {
                setState(() => _corteSeleccionado = value);
                Navigator.pop(context);
                _cargarEstudiantes();
              },
            ),
            RadioListTile<int?>(
              title: const Text('Corte 3'),
              value: 3,
              groupValue: _corteSeleccionado,
              onChanged: (value) {
                setState(() => _corteSeleccionado = value);
                Navigator.pop(context);
                _cargarEstudiantes();
              },
            ),
          ],
        ),
      ),
    );
  }
}
