import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/attendance_detail.dart';
import '../services/api_services.dart';
import '../providers/data_provider.dart';

class StudentAttendanceDetailScreen extends StatefulWidget {
  final Course course;
  final String studentCode;
  final String studentName;

  const StudentAttendanceDetailScreen({
    super.key,
    required this.course,
    required this.studentCode,
    required this.studentName,
  });

  @override
  State<StudentAttendanceDetailScreen> createState() =>
      _StudentAttendanceDetailScreenState();
}

class _StudentAttendanceDetailScreenState
    extends State<StudentAttendanceDetailScreen> {
  List<AttendanceDetail> _attendanceList = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _studentInfo = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _showOnlyAbsences = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData({bool onlyAbsences = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showOnlyAbsences = onlyAbsences;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final sessionToken = dataProvider.authService.sessionToken;

      if (sessionToken == null) {
        throw Exception('SESIÓN_INVÁLIDA');
      }

      final Map<String, dynamic> data;
      if (onlyAbsences) {
        data = await ApiService.getStudentAbsences(
          sessionToken,
          widget.course.id,
          widget.studentCode,
        );
        _attendanceList =
            (data['absences'] as List<AttendanceDetail>?) ?? [];
      } else {
        data = await ApiService.getStudentAttendance(
          sessionToken,
          widget.course.id,
          widget.studentCode,
        );
        _attendanceList =
            (data['attendance'] as List<AttendanceDetail>?) ?? [];
      }

      setState(() {
        _summary = data['summary'] ?? {};
        _studentInfo = data['student'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      String friendlyMessage = 'No se pudo cargar el historial de asistencia';
      
      // Convertir errores técnicos en mensajes amigables
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('sesión') || errorStr.contains('session') || errorStr.contains('401')) {
        friendlyMessage = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      } else if (errorStr.contains('conexión') || errorStr.contains('connection') || errorStr.contains('socket')) {
        friendlyMessage = 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      } else if (errorStr.contains('timeout')) {
        friendlyMessage = 'El servidor tardó demasiado en responder. Intenta nuevamente.';
      } else if (errorStr.contains('404')) {
        friendlyMessage = 'No se encontró información de este estudiante.';
      } else if (errorStr.contains('type') && errorStr.contains('subtype')) {
        friendlyMessage = 'Error al procesar los datos. El estudiante no tiene registros de asistencia.';
      } else if (errorStr.contains('500') || errorStr.contains('error del servidor')) {
        friendlyMessage = 'Error en el servidor. Intenta más tarde.';
      }
      
      setState(() {
        _errorMessage = friendlyMessage;
        _isLoading = false;
      });
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
            Text(
              widget.studentName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.course.nombre,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAttendanceData(onlyAbsences: _showOnlyAbsences),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
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
            Text('Cargando historial...', 
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
                onPressed: () => _loadAttendanceData(
                  onlyAbsences: _showOnlyAbsences),
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
        _buildFilterToggle(),
        _buildSummarySection(),
        Expanded(
          child: _attendanceList.isEmpty
              ? _buildEmptyState()
              : _buildAttendanceList(),
        ),
      ],
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showOnlyAbsences
                  ? () => _loadAttendanceData(onlyAbsences: false)
                  : null,
              icon: const Icon(Icons.list, size: 18),
              label: const Text('Todo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: !_showOnlyAbsences
                    ? const Color(0xFF3b82f6)
                    : Colors.grey[300],
                foregroundColor:
                    !_showOnlyAbsences ? Colors.white : Colors.grey[600],
                elevation: !_showOnlyAbsences ? 2 : 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: !_showOnlyAbsences
                  ? () => _loadAttendanceData(onlyAbsences: true)
                  : null,
              icon: const Icon(Icons.warning, size: 18),
              label: const Text('Solo Ausencias'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showOnlyAbsences
                    ? Colors.red
                    : Colors.grey[300],
                foregroundColor:
                    _showOnlyAbsences ? Colors.white : Colors.grey[600],
                elevation: _showOnlyAbsences ? 2 : 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_summary.isEmpty) return const SizedBox.shrink();

    final totalAsistencias = _summary['asistencias'] ?? _summary['presentes'] ?? 0;
    final totalAusencias = _summary['ausencias'] ?? _summary['ausentes'] ?? 0;
    final totalClases = _summary['total_clases'] ?? 0;
    final totalTardanzas = _summary['tardanzas'] ?? 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila: Total de clases y Asistencias
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.class_,
                  label: 'Total de clases',
                  value: totalClases.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Asistencias',
                  value: totalAsistencias.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda fila: Ausencias y Tardanzas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.cancel,
                  label: 'Ausencias',
                  value: totalAusencias.toString(),
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  label: 'Tardanzas',
                  value: totalTardanzas.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showOnlyAbsences ? Icons.check_circle_outline : Icons.event_note,
              size: 80,
              color: _showOnlyAbsences ? Colors.green : Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              _showOnlyAbsences
                  ? '¡Excelente!'
                  : 'Sin Registros',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlyAbsences
                  ? 'No hay ausencias registradas para este estudiante'
                  : 'Este estudiante aún no tiene registros de asistencia para este curso',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadAttendanceData(onlyAbsences: _showOnlyAbsences),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Agrupar por mes
    final Map<String, List<AttendanceDetail>> groupedByMonth = {};
    for (var record in _attendanceList) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(record.fecha);
        final monthKey = DateFormat('MMMM yyyy', 'es').format(date);
        if (!groupedByMonth.containsKey(monthKey)) {
          groupedByMonth[monthKey] = [];
        }
        groupedByMonth[monthKey]!.add(record);
      } catch (e) {
        // Si falla el parseo, usar la fecha como viene
        final monthKey = record.fecha;
        if (!groupedByMonth.containsKey(monthKey)) {
          groupedByMonth[monthKey] = [];
        }
        groupedByMonth[monthKey]!.add(record);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedByMonth.length,
      itemBuilder: (context, index) {
        final monthKey = groupedByMonth.keys.elementAt(index);
        final records = groupedByMonth[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                monthKey,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            ...records.map((record) => _buildAttendanceCard(record)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceDetail record) {
    // Determinar color e ícono según el estado
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;
    
    if (record.isPresente) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Presente';
    } else if (record.isTardanza) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Tardanza';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Ausente';
    }

    String formattedDate = record.fecha;
    String formattedTime = record.hora;

    try {
      final date = DateFormat('yyyy-MM-dd').parse(record.fecha);
      formattedDate = DateFormat('EEEE, d \'de\' MMMM', 'es').format(date);
    } catch (e) {
      // Mantener formato original si falla
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time, 
                        size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (record.asignatura != null && record.asignatura!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.book, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            record.asignatura!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (record.isTardanza && record.minutosTardanza != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${record.minutosTardanza} min de retraso',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (record.justificada == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Justificada',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (record.observacion != null &&
                      record.observacion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.observacion!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
