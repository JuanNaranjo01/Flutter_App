import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_lib;
import '../models/course.dart';
import '../models/course_student.dart';
import '../services/api_services.dart';
import '../providers/data_provider.dart';
import '../models/periodo.dart';
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

  // Filtros de periodo y corte
  List<Periodo> _periodos = [];
  Periodo? _periodoSeleccionado;
  int? _corteSeleccionado;
  DateTime? _fechaSeleccionada; // ✅ NUEVO: Filtro por fecha específica
  bool _loadingPeriodos = false;

  @override
  void initState() {
    super.initState();
    _loadPeriodos();
    _loadStudents();
  }

  Future<void> _loadPeriodos() async {
    setState(() {
      _loadingPeriodos = true;
    });

    try {
      final periodos = await ApiService.getPeriodos();
      final periodoActual = await ApiService.getPeriodoActual();

      setState(() {
        _periodos = periodos;
        // Pre-seleccionar el periodo actual si existe
        if (periodoActual != null) {
          _periodoSeleccionado = periodos.firstWhere(
            (p) => p.idPeriodo == periodoActual.idPeriodo,
            orElse: () => periodos.isNotEmpty ? periodos.first : periodos.first,
          );
          _corteSeleccionado = periodoActual.corteActual;
        } else if (periodos.isNotEmpty) {
          _periodoSeleccionado = periodos.first;
          _corteSeleccionado = 1;
        }
        _loadingPeriodos = false;
      });
    } catch (e) {
      print('⚠️ Error cargando periodos: $e');
      setState(() {
        _loadingPeriodos = false;
      });
    }
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

      // Preparar parámetros de filtro opcionales
      int? anioFiltro;
      String? semestreFiltro;
      int? corteFiltro;
      String? fechaFiltro; // ✅ NUEVO: Filtro por fecha

      if (_periodoSeleccionado != null) {
        anioFiltro = _periodoSeleccionado!.anio;
        semestreFiltro = _periodoSeleccionado!.semestre;
      }

      if (_corteSeleccionado != null) {
        corteFiltro = _corteSeleccionado;
      }

      // ✅ NUEVO: Formatear fecha si está seleccionada (formato: YYYY-MM-DD)
      if (_fechaSeleccionada != null) {
        fechaFiltro = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!);
      }

      print(
          '🔍 Filtros aplicados - Año: $anioFiltro, Semestre: $semestreFiltro, Corte: $corteFiltro, Fecha: $fechaFiltro');

      // Llamar al servicio con los filtros
      final students = await ApiService.getCourseStudents(
        sessionToken,
        widget.course.id,
        anio: anioFiltro,
        semestre: semestreFiltro,
        corte: corteFiltro,
        fecha: fechaFiltro, // ✅ NUEVO: Pasar filtro de fecha
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
      if (errorStr.contains('sesión') ||
          errorStr.contains('session') ||
          errorStr.contains('401')) {
        friendlyMessage =
            'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      } else if (errorStr.contains('conexión') ||
          errorStr.contains('connection') ||
          errorStr.contains('socket')) {
        friendlyMessage =
            'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      } else if (errorStr.contains('timeout')) {
        friendlyMessage =
            'El servidor tardó demasiado en responder. Intenta nuevamente.';
      } else if (errorStr.contains('404')) {
        friendlyMessage = 'El curso no se encontró en el sistema.';
      } else if (errorStr.contains('500') ||
          errorStr.contains('error del servidor')) {
        friendlyMessage = 'Error en el servidor. Intenta más tarde.';
      }

      setState(() {
        _errorMessage = friendlyMessage;
        _isLoading = false;
      });
    }
  }

  /// Aplica filtros de periodo y corte a los estudiantes
  /// Obtiene estadísticas específicas por corte para cada estudiante
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
          _filteredStudents
              .sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
          break;
        case 'asistencia':
          _filteredStudents.sort((a, b) =>
              b.porcentajeAsistencia.compareTo(a.porcentajeAsistencia));
          break;
        case 'ausencias':
          _filteredStudents.sort((a, b) => b.ausencias.compareTo(a.ausencias));
          break;
      }
    });
  }

  Future<void> _exportReport() async {
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final sessionToken = dataProvider.authService.sessionToken;

      if (sessionToken == null) {
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
                  Text('Generando archivo Excel...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Crear archivo Excel
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheetObject = excel['Asistencias'];

      // Definir estilos
      excel_lib.CellStyle headerStyle = excel_lib.CellStyle(
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('#4472C4'),
        fontColorHex: excel_lib.ExcelColor.white,
        bold: true,
        fontSize: 12,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
        verticalAlign: excel_lib.VerticalAlign.Center,
      );

      excel_lib.CellStyle dataStyle = excel_lib.CellStyle(
        fontSize: 11,
        verticalAlign: excel_lib.VerticalAlign.Center,
      );

      // Crear encabezados de la tabla
      List<String> headers = [
        'Código',
        'Nombre Completo',
        'Programa',
        'Asistencias',
        'Tardanzas',
        'Ausencias',
        'Min. Tardanza',
        'Hrs. Perdidas'
      ];

      // Insertar encabezados
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = excel_lib.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Llenar datos de estudiantes
      int rowIndex = 1;
      for (var student in _filteredStudents) {
        // ✅ USAR DATOS DEL BACKEND DIRECTAMENTE (ya vienen calculados correctamente)
        // El endpoint /api/teacher/course/:id/students ya retorna:
        // - horas_faltadas: calculadas por el backend (incluye ausencias + tardanzas/50)
        // - tardanzas: cantidad de tardanzas
        // - minutos_tardanza: total de minutos acumulados
        // - total_clases: total de clases en el rango filtrado

        // Insertar datos del estudiante
        List<dynamic> rowData = [
          student.codigo,
          student.nombreCompleto,
          student.programa,
          student.asistencias,
          student.tardanzas,
          student.ausencias,
          student.minutosTardanza,
          student.horasFaltadas, // ⚠️ Double: incluye todo (ausencias + tardanzas)
        ];

        for (int i = 0; i < rowData.length; i++) {
          var cell = sheetObject.cell(excel_lib.CellIndex.indexByColumnRow(
              columnIndex: i, rowIndex: rowIndex));

          if (rowData[i] is String) {
            cell.value = excel_lib.TextCellValue(rowData[i]);
          } else if (rowData[i] is int) {
            cell.value = excel_lib.IntCellValue(rowData[i]);
          } else if (rowData[i] is double) {
            cell.value = excel_lib.DoubleCellValue(rowData[i]);
          } else {
            cell.value = excel_lib.TextCellValue(rowData[i].toString());
          }

          cell.cellStyle = dataStyle;
        }

        rowIndex++;
      }

      // Ajustar ancho de columnas
      for (int i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 15);
      }
      // Columna nombre más ancha
      sheetObject.setColumnWidth(1, 30);
      // Columna programa más ancha
      sheetObject.setColumnWidth(2, 35);

      // Eliminar hoja por defecto
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Guardar archivo en Downloads
      Directory? directory;
      String? downloadsPath;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = Directory('/storage/emulated/0/Downloads');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        }
        downloadsPath = directory?.path;
      } else {
        directory = await getApplicationDocumentsDirectory();
        downloadsPath = directory.path;
      }

      // Construir nombre de archivo según el curso y los filtros activos
      final filename = _buildExportFilename();
      final path = '${downloadsPath}/$filename';

      // Guardar archivo
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
      }

      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);

      // Mostrar diálogo informativo
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.green, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Excel generado',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.table_chart,
                          color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tabla de asistencias exportada exitosamente',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nombre del archivo:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filename,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF007f2f)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 20, color: Color(0xFF007f2f)),
                            const SizedBox(width: 8),
                            const Text(
                              '¿Dónde encontrarlo?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (Platform.isAndroid) ...[
                          _buildLocationStep(
                              '1', 'Abre la app "Archivos" de tu celular'),
                          _buildLocationStep(
                              '2', 'Ve a "Descargas" o "Downloads"'),
                          _buildLocationStep('3', 'Busca: $filename'),
                          _buildLocationStep(
                              '4', 'Ábrelo con Excel, Sheets o WPS Office'),
                        ] else ...[
                          _buildLocationStep(
                              '1', 'Revisa la carpeta de documentos'),
                          _buildLocationStep('2', 'Abre con Excel o Numbers'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido', style: TextStyle(fontSize: 16)),
              ),
            ],
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

  String _buildExportFilename() {
    String sanitize(String value) {
      return value
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\s]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();
    }

    final cleanCourseName = sanitize(widget.course.nombre);
    final filterParts = <String>[];

    if (_periodoSeleccionado != null) {
      filterParts.add(sanitize(_periodoSeleccionado!.nombrePeriodo));
    }

    if (_corteSeleccionado != null) {
      filterParts.add('corte_${_corteSeleccionado}');
    }

    if (_fechaSeleccionada != null) {
      filterParts.add('fecha_${DateFormat('yyyyMMdd').format(_fechaSeleccionada!)}');
    }

    if (_searchQuery.trim().isNotEmpty) {
      filterParts.add('busqueda_${sanitize(_searchQuery)}');
    }

    final filterSuffix = filterParts.isEmpty ? '' : '_${filterParts.join('_')}';
    return '$cleanCourseName$filterSuffix.xlsx';
  }

  // Widget auxiliar para mostrar pasos en el diálogo
  Widget _buildLocationStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF007f2f),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        flexibleSpace: Container(
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
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
                            ? const Color(0xFF007f2f)
                            : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Por Nombre',
                        style: TextStyle(
                            color: _sortBy == 'nombre'
                                ? const Color(0xFF007f2f)
                                : Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'asistencia',
                child: Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: _sortBy == 'asistencia'
                            ? const Color(0xFF007f2f)
                            : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Por Asistencia',
                        style: TextStyle(
                            color: _sortBy == 'asistencia'
                                ? const Color(0xFF007f2f)
                                : Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ausencias',
                child: Row(
                  children: [
                    Icon(Icons.trending_down,
                        color: _sortBy == 'ausencias'
                            ? const Color(0xFF007f2f)
                            : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Por Ausencias',
                        style: TextStyle(
                            color: _sortBy == 'ausencias'
                                ? const Color(0xFF007f2f)
                                : Colors.black)),
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
              backgroundColor: const Color(0xFF007f2f),
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                  backgroundColor: const Color(0xFF007f2f),
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
        _buildFilterSection(),
        Expanded(
          child: _students.isEmpty ? _buildEmptyState() : _buildStudentsList(),
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
          prefixIcon: const Icon(Icons.search, color: Color(0xFF007f2f)),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    final studentsAtRisk =
        _students.where((s) => s.porcentajeAsistencia < 70).length;

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
              color: const Color(0xFF007f2f),
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

  Widget _buildFilterSection() {
    if (_students.isEmpty && !_loadingPeriodos) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: Color(0xFF6B7280)),
              SizedBox(width: 6),
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Filtro de Periodo/Semestre
              Expanded(
                flex: 2,
                child: _buildPeriodoDropdown(),
              ),
              const SizedBox(width: 8),
              // Filtro de Corte
              Expanded(
                child: _buildCorteDropdown(),
              ),
              const SizedBox(width: 8),
              // ✅ NUEVO: Botón para filtro de fecha específica
              IconButton(
                icon: Icon(
                  Icons.calendar_today,
                  color: _fechaSeleccionada != null
                      ? const Color(0xFF007f2f)
                      : Colors.grey,
                ),
                tooltip: 'Filtrar por fecha específica',
                onPressed: _mostrarSelectorFecha,
              ),
            ],
          ),
          // Chips de filtros activos
          if (_periodoSeleccionado != null ||
              _corteSeleccionado != null ||
              _fechaSeleccionada != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_periodoSeleccionado != null)
                    _buildFilterChip(
                      label: _periodoSeleccionado!.nombrePeriodo,
                      onDelete: () {
                        setState(() {
                          _periodoSeleccionado = null;
                          _corteSeleccionado = null;
                        });
                        _loadStudents();
                      },
                    ),
                  if (_corteSeleccionado != null)
                    _buildFilterChip(
                      label: 'Corte $_corteSeleccionado',
                      onDelete: () {
                        setState(() {
                          _corteSeleccionado = null;
                        });
                        _loadStudents();
                      },
                    ),
                  // ✅ NUEVO: Chip para fecha seleccionada
                  if (_fechaSeleccionada != null)
                    _buildFilterChip(
                      label:
                          DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!),
                      icon: Icons.calendar_today,
                      onDelete: () {
                        setState(() {
                          _fechaSeleccionada = null;
                        });
                        _loadStudents();
                      },
                    ),
                  // Botón para limpiar todos los filtros
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _periodoSeleccionado = null;
                        _corteSeleccionado = null;
                        _fechaSeleccionada = null; // ✅ NUEVO: Limpiar fecha
                      });
                      _loadStudents();
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpiar filtros',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodoDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _periodoSeleccionado != null
              ? const Color(0xFF007f2f)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Periodo>(
          isExpanded: true,
          isDense: true,
          hint: const Text('Periodo', style: TextStyle(fontSize: 13)),
          value: _periodoSeleccionado,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: _periodos.map((Periodo periodo) {
            return DropdownMenuItem<Periodo>(
              value: periodo,
              child: Text(
                periodo.nombrePeriodo,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (Periodo? newValue) {
            setState(() {
              _periodoSeleccionado = newValue;
              // Reset corte al cambiar periodo
              _corteSeleccionado = null;
            });
            // Recargar estudiantes con el nuevo filtro
            _loadStudents();
          },
        ),
      ),
    );
  }

  Widget _buildCorteDropdown() {
    final cortesDisponibles = _periodoSeleccionado?.cortes ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _corteSeleccionado != null
              ? const Color(0xFF007f2f)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          isDense: true,
          hint: const Text('Corte', style: TextStyle(fontSize: 13)),
          value: _corteSeleccionado,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: cortesDisponibles.map((Corte corte) {
            return DropdownMenuItem<int>(
              value: corte.numero,
              child: Text(
                'Corte ${corte.numero}',
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: _periodoSeleccionado == null
              ? null
              : (int? newValue) {
                  setState(() {
                    _corteSeleccionado = newValue;
                  });
                  // Recargar estudiantes con el nuevo filtro
                  _loadStudents();
                },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDelete,
    IconData? icon, // ✅ NUEVO: Icono opcional
  }) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            // ✅ NUEVO: Mostrar icono si está presente
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
      onDeleted: onDelete,
      backgroundColor: const Color(0xFF007f2f),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 64, color: Colors.grey),
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
              backgroundColor: const Color(0xFF007f2f),
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
          // ✅ NUEVO: Pasar filtros actuales al detalle del estudiante
          final fechaFormateada = _fechaSeleccionada != null
              ? DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!)
              : null;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentAttendanceDetailScreen(
                course: widget.course,
                studentCode: student.codigo,
                studentName: student.nombreCompleto,
                anio: _periodoSeleccionado?.anio,
                semestre: _periodoSeleccionado?.semestre,
                corte: _corteSeleccionado,
                fecha: fechaFormateada,
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
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      student.nombreCompleto.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007f2f),
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
              // ✅ ACTUALIZADO (27/02/2026): Mostrar asistencias totales y separar presentes/tardanzas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatChip(
                    icon: Icons.check_circle,
                    label: '${student.asistenciasTotales}',
                    subLabel: 'Asistencias',
                    color: Colors.green,
                  ),
                  _buildStatChip(
                    icon: Icons.access_time,
                    label: '${student.tardanzas}',
                    subLabel: 'Tarde',
                    color: Colors.orange,
                  ),
                  _buildStatChip(
                    icon: Icons.cancel,
                    label: '${student.totalFaltas}',
                    subLabel: 'Faltas',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Horas faltadas - Prominente
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty,
                            size: 14, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${student.horasFaltadas}h',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
    String? subLabel,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (subLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// ✅ NUEVO: Muestra un selector de fecha para filtrar asistencias
  Future<void> _mostrarSelectorFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007f2f),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      _loadStudents();
    }
  }
}
