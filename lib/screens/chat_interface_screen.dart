import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/data_provider.dart';
import '../models/attendance_record.dart';
import '../models/course.dart';
import '../services/api_services.dart';
import 'course_students_screen.dart';

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
  bool _hasInitialized = false;
  
  // Para la sección de cursos
  List<Course> _courses = [];
  bool _isLoadingCourses = false;
  String? _coursesError;

  @override
  void initState() {
    super.initState();
    _hasInitialized = false;
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
      _coursesError = null;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final sessionToken = dataProvider.authService.sessionToken;

      if (sessionToken == null) {
        throw Exception('SESIÓN_INVÁLIDA');
      }

      final courses = await ApiService.getTeacherCourses(sessionToken);

      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      String friendlyMessage = 'No se pudieron cargar los cursos';
      
      // Convertir errores técnicos en mensajes amigables
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('sesión') || errorStr.contains('session') || errorStr.contains('401')) {
        friendlyMessage = 'Tu sesión ha expirado';
      } else if (errorStr.contains('conexión') || errorStr.contains('connection') || errorStr.contains('socket')) {
        friendlyMessage = 'Error de conexión';
      } else if (errorStr.contains('timeout')) {
        friendlyMessage = 'Tiempo de espera agotado';
      } else if (errorStr.contains('404')) {
        friendlyMessage = 'No se encontraron cursos';
      } else if (errorStr.contains('500') || errorStr.contains('error del servidor')) {
        friendlyMessage = 'Error en el servidor';
      }
      
      setState(() {
        _coursesError = friendlyMessage;
        _isLoadingCourses = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refrescar solo la primera vez
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        dataProvider.refreshAttendanceRecords();
      });
    }
  }

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
          // Mostrar loading inicial
          if (data.isLoadingAttendance && data.attendanceRecords.isEmpty) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, data),
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando registros de asistencia...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Mostrar error si hay y no hay datos
          if (data.attendanceError != null && data.attendanceRecords.isEmpty) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, data),
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar asistencias',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.attendanceError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => data.refreshAttendanceRecords(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007f2f),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

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
                expandedHeight: 140,
                pinned: true,
                actions: [
                  IconButton(
                    icon: data.isLoadingAttendance
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white),
                    onPressed: data.isLoadingAttendance
                        ? null
                        : () => data.refreshAttendanceRecords(),
                    tooltip: 'Actualizar',
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF007f2f), // Verde corporativo UCEVA
                          Color(0xFF009938),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.2 * 255).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.school,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Consultas de Asistencia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Filtra y exporta registros por semestre, corte y materia',
                              style: const TextStyle(
                                color: Color(0xFFE8F5E9),
                                fontSize: 13,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

          // Lista de cursos directamente
          if (_isLoadingCourses)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Cargando cursos...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (_coursesError != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text(_coursesError!, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadCourses,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_courses.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No tienes cursos asignados',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final course = _courses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCourseCard(course),
                    );
                  },
                  childCount: _courses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DataProvider data) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      actions: [
        IconButton(
          icon: data.isLoadingAttendance
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
          onPressed: data.isLoadingAttendance
              ? null
              : () => data.refreshAttendanceRecords(),
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF007f2f), // Verde corporativo UCEVA
                Color(0xFF009938),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Consulta de Asistencias',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Filtra y exporta registros por semestre, corte y materia',
                    style: TextStyle(
                      color: Color(0xFFE8F5E9),
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
