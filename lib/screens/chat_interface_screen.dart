import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/data_provider.dart';
import '../models/attendance_record.dart';

class ChatInterfaceScreen extends StatefulWidget {
  const ChatInterfaceScreen({super.key});

  @override
  State<ChatInterfaceScreen> createState() => _ChatInterfaceScreenState();
}

class _ChatInterfaceScreenState extends State<ChatInterfaceScreen> {
  String _searchTerm = '';
  String _selectedSemester = 'Todos';
  String _selectedCorte = 'Todos';
  String _selectedMateria = 'Todas';

  Future<void> _exportToCSV(List<AttendanceRecord> records) async {
    try {
      final rows = <List<dynamic>>[
        [
          'Fecha',
          'Código',
          'Nombre',
          'Materia',
          'Asistió',
          'Horas',
          'Semestre',
          'Corte'
        ]
      ];

      for (var record in records) {
        rows.add([
          record.fecha,
          record.codigo,
          record.nombre,
          record.materia,
          record.asistio ? 'Sí' : 'No',
          record.horasAsistidas,
          record.semestre,
          record.corte,
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final filename = 'asistencias_$_selectedSemester'
              '_$_selectedCorte'
              '_$_selectedMateria.csv'
          .replaceAll(' ', '_');
      final path = '${directory.path}/$filename';
      final file = File(path);
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exportado: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Consumer<DataProvider>(
        builder: (context, data, child) {
          // Obtener materias únicas
          final materias = data.attendanceRecords
              .map((r) => r.materia)
              .toSet()
              .toList()
            ..sort();

          // Obtener semestres únicos
          final semestres = data.attendanceRecords
              .map((r) => r.semestre)
              .toSet()
              .toList()
            ..sort();

          // Filtrar registros
          final filteredRecords = data.attendanceRecords.where((record) {
            final matchesSearch = record.nombre
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                record.codigo
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                record.materia
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase());

            final matchesSemester = _selectedSemester == 'Todos' ||
                record.semestre == _selectedSemester;
            final matchesCorte =
                _selectedCorte == 'Todos' || record.corte == _selectedCorte;
            final matchesMateria = _selectedMateria == 'Todas' ||
                record.materia == _selectedMateria;

            return matchesSearch &&
                matchesSemester &&
                matchesCorte &&
                matchesMateria;
          }).toList();

          // Calcular estadísticas
          final total = filteredRecords.length;
          final present = filteredRecords.where((r) => r.asistio).length;
          final absent = total - present;
          final totalHours =
              filteredRecords.fold<int>(0, (sum, r) => sum + r.horasAsistidas);

          return CustomScrollView(
            slivers: [
              // App Bar con gradiente
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF9333EA), // purple-600
                          Color(0xFFA855F7), // purple-500
                        ],
                      ),
                    ),
                    child: const SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Consulta de Asistencias',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Filtra y exporta registros por semestre, corte y materia - Modelo UCEVA',
                              style: TextStyle(
                                color: Color(0xFFE9D5FF),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Contenido
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Tarjetas de estadísticas
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Registros',
                              total.toString(),
                              Icons.list_alt,
                              const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Asistencias',
                              present.toString(),
                              Icons.check_circle,
                              const [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Faltas',
                              absent.toString(),
                              Icons.cancel,
                              const [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Horas Totales',
                              totalHours.toString(),
                              Icons.schedule,
                              const [Color(0xFFF97316), Color(0xFFEA580C)],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Panel de filtros
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.05 * 255).round()),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Búsqueda
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Buscar',
                                hintText: 'Nombre, código o materia...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchTerm = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Filtros en fila
                            Row(
                              children: [
                                // Filtro Materia
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedMateria,
                                    decoration: InputDecoration(
                                      labelText: 'Materia',
                                      prefixIcon: const Icon(Icons.book),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    items: ['Todas', ...materias]
                                        .map((materia) => DropdownMenuItem(
                                              value: materia,
                                              child: Text(
                                                materia,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedMateria = value!;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Filtro Semestre
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedSemester,
                                    decoration: InputDecoration(
                                      labelText: 'Semestre',
                                      prefixIcon:
                                          const Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    items: ['Todos', ...semestres]
                                        .map((sem) => DropdownMenuItem(
                                              value: sem,
                                              child: Text(sem),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedSemester = value!;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Filtro Corte
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedCorte,
                                    decoration: InputDecoration(
                                      labelText: 'Corte',
                                      prefixIcon: const Icon(Icons.filter_list),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    items: [
                                      'Todos',
                                      '1er Corte',
                                      '2do Corte',
                                      '3er Corte'
                                    ]
                                        .map((corte) => DropdownMenuItem(
                                              value: corte,
                                              child: Text(corte),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCorte = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Botón de exportar
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _exportToCSV(filteredRecords),
                                icon: const Icon(Icons.download),
                                label: const Text('Exportar CSV'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tabla de registros
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.05 * 255).round()),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey.shade100,
                              ),
                              columns: const [
                                DataColumn(label: Text('Fecha')),
                                DataColumn(label: Text('Código')),
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Materia')),
                                DataColumn(label: Text('Asistió')),
                                DataColumn(label: Text('Horas')),
                                DataColumn(label: Text('Semestre')),
                                DataColumn(label: Text('Corte')),
                              ],
                              rows: filteredRecords.isEmpty
                                  ? [
                                      const DataRow(
                                        cells: [
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                          DataCell(Text(
                                            'No se encontraron registros',
                                            style:
                                                TextStyle(color: Colors.grey),
                                          )),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                          DataCell(Text('')),
                                        ],
                                      )
                                    ]
                                  : filteredRecords
                                      .map(
                                        (record) => DataRow(
                                          cells: [
                                            DataCell(Text(record.fecha)),
                                            DataCell(Text(record.codigo)),
                                            DataCell(Text(record.nombre)),
                                            DataCell(Text(record.materia)),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: record.asistio
                                                      ? Colors.green.shade100
                                                      : Colors.red.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  record.asistio ? 'Sí' : 'No',
                                                  style: TextStyle(
                                                    color: record.asistio
                                                        ? Colors.green.shade800
                                                        : Colors.red.shade800,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(record.horasAsistidas
                                                .toString())),
                                            DataCell(Text(record.semestre)),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  record.corte,
                                                  style: TextStyle(
                                                    color: Colors.blue.shade800,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withAlpha((0.3 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.9 * 255).round()),
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
