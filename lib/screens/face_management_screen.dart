import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/data_provider.dart';

class FaceManagementScreen extends StatefulWidget {
  const FaceManagementScreen({super.key});

  @override
  State<FaceManagementScreen> createState() => _FaceManagementScreenState();
}

class _FaceManagementScreenState extends State<FaceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportFacesToCSV() async {
    final data = Provider.of<DataProvider>(context, listen: false);
    final faces = data.registeredFaces
        .where((face) =>
            face.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            face.codigo.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();

    try {
      List<List<dynamic>> rows = [
        [
          'ID',
          'Nombre',
          'Código',
          'Email',
          'Carrera',
          'Semestre',
          'Materia',
          'Fecha Registro',
          'Confianza'
        ]
      ];

      for (var face in faces) {
        rows.add([
          face.id,
          face.name,
          face.codigo,
          face.email,
          face.carrera,
          face.semestre,
          face.materia,
          face.registrationDate,
          face.confidence,
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/rostros_registrados.csv';
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

  Future<void> _exportHistoryToCSV() async {
    final data = Provider.of<DataProvider>(context, listen: false);
    final records = data.attendanceRecords
        .where((record) =>
            record.nombre.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            record.codigo.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();

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
      final path = '${directory.path}/historial_asistencias.csv';
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
              'Gestión de Rostros',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Administra rostros y consulta historial',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3b82f6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3b82f6),
          tabs: [
            Tab(
              icon: const Icon(Icons.people),
              text:
                  'Rostros (${Provider.of<DataProvider>(context).registeredFaces.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text:
                  'Historial (${Provider.of<DataProvider>(context).attendanceRecords.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Búsqueda y exportar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchTerm = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, código o carrera...',
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _tabController.index == 0
                        ? _exportFacesToCSV
                        : _exportHistoryToCSV,
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

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFacesTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacesTab() {
    return Consumer<DataProvider>(
      builder: (context, data, child) {
        final filteredFaces = data.registeredFaces
            .where((face) =>
                face.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                face.codigo.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                face.carrera.toLowerCase().contains(_searchTerm.toLowerCase()))
            .toList();

        if (filteredFaces.isEmpty) {
          return const Center(
            child: Text(
              'No se encontraron rostros registrados',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor:
                    const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
                columns: const [
                  DataColumn(label: Text('Foto')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Carrera')),
                  DataColumn(label: Text('Semestre')),
                  DataColumn(label: Text('Confianza')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: filteredFaces.map((face) {
                  return DataRow(
                    cells: [
                      DataCell(
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(face.imageUrl),
                        ),
                      ),
                      DataCell(Text(face.name,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(face.codigo,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(face.email,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(face.carrera,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(face.semestre,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${face.confidence.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmar eliminación'),
                                content: Text(
                                    '¿Estás seguro de eliminar a ${face.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      data.removeRegisteredFace(face.id);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Rostro eliminado'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    },
                                    child: const Text('Eliminar',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<DataProvider>(
      builder: (context, data, child) {
        final filteredHistory = data.attendanceRecords
            .where((record) =>
                record.nombre
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                record.codigo
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                record.materia
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()))
            .toList();

        if (filteredHistory.isEmpty) {
          return const Center(
            child: Text(
              'No se encontró historial',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor:
                    const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
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
                rows: filteredHistory.map((record) {
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
                            borderRadius: BorderRadius.circular(4),
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
                      DataCell(Text(record.horasAsistidas.toString(),
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
        );
      },
    );
  }
}
