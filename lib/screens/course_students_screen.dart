import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/course_student.dart';
import '../services/api_services.dart';
import '../providers/data_provider.dart';
import 'student_attendance_detail_screen.dart';

class CourseStudentsScreen extends StatefulWidget {
  final Course course;

  const CourseStudentsScreen({super.key, required this.course});

  @override
  State<CourseStudentsScreen> createState() => _CourseStudentsScreenState();
}

class _CourseStudentsScreenState extends State<CourseStudentsScreen> {
  List<CourseStudent> _students = [];
  List<CourseStudent> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _sortBy = 'nombre'; // nombre, asistencia, ausencias

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final sessionToken = dataProvider.authService.sessionToken;

      if (sessionToken == null) {
        throw Exception('SESIÓN_INVÁLIDA');
      }

      final students = await ApiService.getCourseStudents(
        sessionToken,
        widget.course.id,
      );

      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
        _applySortAndFilter();
      });
    } catch (e) {
      String friendlyMessage = 'No se pudieron cargar los estudiantes';
      
      // Convertir errores técnicos en mensajes amigables
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('sesión') || errorStr.contains('session') || errorStr.contains('401')) {
        friendlyMessage = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      } else if (errorStr.contains('conexión') || errorStr.contains('connection') || errorStr.contains('socket')) {
        friendlyMessage = 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      } else if (errorStr.contains('timeout')) {
        friendlyMessage = 'El servidor tardó demasiado en responder. Intenta nuevamente.';
      } else if (errorStr.contains('404')) {
        friendlyMessage = 'El curso no se encontró en el sistema.';
      } else if (errorStr.contains('500') || errorStr.contains('error del servidor')) {
        friendlyMessage = 'Error en el servidor. Intenta más tarde.';
      }
      
      setState(() {
        _errorMessage = friendlyMessage;
        _isLoading = false;
      });
    }
  }

  void _applySortAndFilter() {
    setState(() {
      // Filtrar
      _filteredStudents = _students.where((student) {
        final query = _searchQuery.toLowerCase();
        return student.nombreCompleto.toLowerCase().contains(query) ||
            student.codigo.toLowerCase().contains(query) ||
            student.programa.toLowerCase().contains(query);
      }).toList();

      // Ordenar
      switch (_sortBy) {
        case 'nombre':
          _filteredStudents.sort((a, b) => 
            a.nombreCompleto.compareTo(b.nombreCompleto));
          break;
        case 'asistencia':
          _filteredStudents.sort((a, b) => 
            b.porcentajeAsistencia.compareTo(a.porcentajeAsistencia));
          break;
        case 'ausencias':
          _filteredStudents.sort((a, b) => 
            b.ausencias.compareTo(a.ausencias));
          break;
      }
    });
  }

  Future<void> _exportReport() async {
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final sessionToken = dataProvider.authService.sessionToken;
      final teacher = dataProvider.currentTeacher;

      if (sessionToken == null || teacher == null) {
        throw Exception('No hay sesión activa');
      }

      // Mostrar diálogo de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando informe...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generar contenido del informe
      final buffer = StringBuffer();
      buffer.writeln('=' * 80);
      buffer.writeln('INFORME DE ASISTENCIA - ${widget.course.nombre.toUpperCase()}');
      buffer.writeln('=' * 80);
      buffer.writeln('');
      buffer.writeln('INFORMACIÓN DEL CURSO:');
      buffer.writeln('  Nombre: ${widget.course.nombre}');
      buffer.writeln('  Código: ${widget.course.codigo}');
      buffer.writeln('  Total Estudiantes: ${widget.course.estudiantesRegistrados}');
      buffer.writeln('');
      buffer.writeln('INFORMACIÓN DEL DOCENTE:');
      buffer.writeln('  Nombre: ${teacher.nombre}');
      buffer.writeln('  Código: ${teacher.codigo}');
      buffer.writeln('  Email: ${teacher.email}');
      buffer.writeln('');
      buffer.writeln('FECHA DE GENERACIÓN: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
      buffer.writeln('=' * 80);
      buffer.writeln('');

      // Información de cada estudiante con cálculo de horas perdidas
      for (var student in _filteredStudents) {
        buffer.writeln('-' * 80);
        buffer.writeln('Estudiante: ${student.nombreCompleto}');
        buffer.writeln('Código: ${student.codigo}');
        buffer.writeln('Programa: ${student.programa}');
        
        // Obtener datos de asistencia completos para calcular minutos de tardanza
        try {
          final attendanceData = await ApiService.getStudentAttendance(
            sessionToken,
            widget.course.id,
            student.codigo,
          );
          
          // Calcular minutos totales de tardanza
          int totalMinutosTardanza = 0;
          final attendanceList = attendanceData['attendance'] ?? [];
          
          for (var record in attendanceList) {
            if (record != null && record.minutosTardanza != null) {
              totalMinutosTardanza += (record.minutosTardanza as num).toInt();
            }
          }
          
          // Calcular horas de clase perdidas (cada 40 minutos = 1 hora)
          final int horasPerdidasPorTardanza = ((totalMinutosTardanza / 40).ceil()).toInt();
          
          buffer.writeln('');
          buffer.writeln('ESTADÍSTICAS:');
          buffer.writeln('  Asistencias: ${student.asistencias}');
          buffer.writeln('  Ausencias: ${student.ausencias}');
          buffer.writeln('  Minutos de tardanza acumulados: $totalMinutosTardanza min');
          buffer.writeln('  Horas de clase perdidas por tardanza: $horasPerdidasPorTardanza hrs');
          buffer.writeln('  Total faltas equivalentes: ${student.ausencias + horasPerdidasPorTardanza}');
          buffer.writeln('  Porcentaje de asistencia: ${student.porcentajeAsistencia.toStringAsFixed(1)}%');
        } catch (e) {
          // Si falla la obtención de datos detallados, usar solo lo básico
          buffer.writeln('');
          buffer.writeln('ESTADÍSTICAS:');
          buffer.writeln('  Asistencias: ${student.asistencias}');
          buffer.writeln('  Ausencias: ${student.ausencias}');
          buffer.writeln('  Porcentaje de asistencia: ${student.porcentajeAsistencia.toStringAsFixed(1)}%');
          buffer.writeln('  Nota: No se pudo calcular tardanzas (${e.toString()})');
        }
        
        buffer.writeln('');
      }
      
      buffer.writeln('=' * 80);
      buffer.writeln('FIN DEL INFORME');
      buffer.writeln('=' * 80);

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final filename = 'informe_${widget.course.codigo}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
      final path = '${directory.path}/$filename';
      final file = File(path);
      await file.writeAsString(buffer.toString());

      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Informe generado exitosamente',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(filename, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar informe: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estudiantes', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              widget.course.nombre,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar por',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applySortAndFilter();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'nombre',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, 
                      color: _sortBy == 'nombre' 
                        ? const Color(0xFF3b82f6) : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Por Nombre', 
                      style: TextStyle(
                        color: _sortBy == 'nombre' 
                          ? const Color(0xFF3b82f6) : Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'asistencia',
                child: Row(
                  children: [
                    Icon(Icons.trending_up, 
                      color: _sortBy == 'asistencia' 
                        ? const Color(0xFF3b82f6) : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Por Asistencia', 
                      style: TextStyle(
                        color: _sortBy == 'asistencia' 
                          ? const Color(0xFF3b82f6) : Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ausencias',
                child: Row(
                  children: [
                    Icon(Icons.trending_down, 
                      color: _sortBy == 'ausencias' 
                        ? const Color(0xFF3b82f6) : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Por Ausencias', 
                      style: TextStyle(
                        color: _sortBy == 'ausencias' 
                          ? const Color(0xFF3b82f6) : Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _filteredStudents.isNotEmpty
          ? FloatingActionButton(
              onPressed: _exportReport,
              backgroundColor: const Color(0xFF10B981),
              tooltip: 'Exportar Informe',
              child: const Icon(Icons.file_download, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando estudiantes...', 
              style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, 
                size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadStudents,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        _buildSummaryCards(),
        Expanded(
          child: _students.isEmpty
              ? _buildEmptyState()
              : _buildStudentsList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applySortAndFilter();
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, código o programa...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF3b82f6)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applySortAndFilter();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_students.isEmpty) return const SizedBox.shrink();

    final totalStudents = _students.length;
    final avgAttendance = _students.isEmpty
        ? 0.0
        : _students.map((s) => s.porcentajeAsistencia).reduce((a, b) => a + b) /
            totalStudents;
    final studentsAtRisk = _students.where((s) => s.porcentajeAsistencia < 70).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.people,
              title: 'Total',
              value: totalStudents.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.check_circle,
              title: 'Promedio',
              value: '${avgAttendance.toStringAsFixed(1)}%',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.warning,
              title: 'Riesgo',
              value: studentsAtRisk.toString(),
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, 
            size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay estudiantes registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No se encontraron estudiantes con "$_searchQuery"',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          return _buildStudentCard(student);
        },
      ),
    );
  }

  Widget _buildStudentCard(CourseStudent student) {
    final Color statusColor = student.porcentajeAsistencia >= 80
        ? Colors.green
        : student.porcentajeAsistencia >= 70
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentAttendanceDetailScreen(
                course: widget.course,
                studentCode: student.codigo,
                studentName: student.nombreCompleto,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF3b82f6).withOpacity(0.1),
                    child: Text(
                      student.nombreCompleto.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3b82f6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Código: ${student.codigo}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                student.programa,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: student.porcentajeAsistencia / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatChip(
                    icon: Icons.check_circle,
                    label: '${student.asistencias} asistencias',
                    color: Colors.green,
                  ),
                  _buildStatChip(
                    icon: Icons.cancel,
                    label: '${student.ausencias} ausencias',
                    color: Colors.red,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${student.porcentajeAsistencia.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
