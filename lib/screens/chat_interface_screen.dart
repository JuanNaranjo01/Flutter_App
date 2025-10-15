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

  Future<void> _exportToCSV(List<AttendanceRecord> records) async {
    try {
      List<List<dynamic>> rows = [
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

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/asistencias_${_selectedSemester}_$_selectedCorte.csv';
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registro de Asistencias',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Consulta y filtra registros - Modelo UCEVA',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<DataProvider>(
        builder: (context, data, child) {
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

            return matchesSearch && matchesSemester && matchesCorte;
          }).toList();

          // Calcular estadísticas
          final total = filteredRecords.length;
          final present = filteredRecords.where((r) => r.asistio).length;
          final absent = total - present;
          final totalHours =
              filteredRecords.fold(0, (sum, r) => sum + r.horasAsistidas);

          // Obtener semestres únicos
          final semesters = data.attendanceRecords
              .map((r) => r.semestre)
              .toSet()
              .toList()
            ..sort();

          return Column(
            children: [
              // Estadísticas
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        title: 'Total',
                        value: total.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        title: 'Asistencias',
                        value: present.toString(),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        title: 'Faltas',
                        value: absent.toString(),
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        title: 'Horas',
                        value: totalHours.toString(),
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),

              // Filtros
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    // Búsqueda
                    TextField(
                      onChanged: (value) => setState(() => _searchTerm = value),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, código o materia...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filtros de semestre y corte
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSemester,
                            decoration: InputDecoration(
                              labelText: 'Semestre',
                              prefixIcon: const Icon(Icons.calendar_today),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: ['Todos', ...semesters]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedSemester = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCorte,
                            decoration: InputDecoration(
                              labelText: 'Corte',
                              prefixIcon: const Icon(Icons.filter_list),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Todos', child: Text('Todos')),
                              DropdownMenuItem(
                                  value: '1er Corte', child: Text('1er Corte')),
                              DropdownMenuItem(
                                  value: '2do Corte', child: Text('2do Corte')),
                              DropdownMenuItem(
                                  value: '3er Corte', child: Text('3er Corte')),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedCorte = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Botón exportar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _exportToCSV(filteredRecords),
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabla
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: filteredRecords.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron registros',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF9FAFB),
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
                              rows: filteredRecords.map((record) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(record.fecha,
                                        style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(record.codigo,
                                        style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(record.nombre,
                                        style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(record.materia,
                                        style: const TextStyle(fontSize: 12))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: record.asistio
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          record.asistio ? 'Sí' : 'No',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: record.asistio
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                        record.horasAsistidas.toString(),
                                        style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(record.semestre,
                                        style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(record.corte,
                                        style: const TextStyle(fontSize: 12))),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color.withAlpha((0.8 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }
}
