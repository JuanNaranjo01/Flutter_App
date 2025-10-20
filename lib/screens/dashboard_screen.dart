import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/data_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(ctx).pop()),
            TextButton(
              child: const Text('Cerrar sesión'),
              onPressed: () {
                context.read<DataProvider>().logout();
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Consumer<DataProvider>(
          builder: (context, data, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel de Control',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  data.currentTeacher != null
                      ? 'Bienvenido, ${data.currentTeacher!.nombre}'
                      : 'Sistema de Control de Asistencias',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              _showLogoutDialog(context);
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, data, child) {
          final totalStudents = data.registeredFaces.length;
          final totalRecords = data.attendanceRecords.length;
          final presentRecords =
              data.attendanceRecords.where((r) => r.asistio).length;
          final attendanceRate = totalRecords > 0
              ? ((presentRecords / totalRecords) * 100).round()
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tarjetas de estadísticas
                _buildStatsCards(totalStudents, attendanceRate, presentRecords),
                const SizedBox(height: 20),

                // Gráficas
                _buildCharts(context, data),
                const SizedBox(height: 20),

                // Actividad reciente y rostros
                _buildBottomSection(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(
      int totalStudents, int attendanceRate, int totalAttendances) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Estudiantes',
            value: totalStudents.toString(),
            icon: Icons.people,
            color: const Color(0xFF3b82f6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Tasa',
            value: '$attendanceRate%',
            icon: Icons.trending_up,
            color: const Color(0xFF10b981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Asistencias',
            value: totalAttendances.toString(),
            icon: Icons.check_circle,
            color: const Color(0xFF8b5cf6),
          ),
        ),
      ],
    );
  }

  Widget _buildCharts(BuildContext context, DataProvider data) {
    return Column(
      children: [
        // Fila 1: Asistencia por Estudiante y Distribución
        Row(
          children: [
            Expanded(
              child: _ChartCard(
                title: 'Asistencia por Estudiante',
                child: _buildBarChart(data),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChartCard(
                title: 'Distribución General',
                child: _buildPieChart(data),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fila 2: Tendencia y Por Periodo
        Row(
          children: [
            Expanded(
              child: _ChartCard(
                title: 'Tendencia',
                child: _buildLineChart(data),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChartCard(
                title: 'Por Periodo',
                child: _buildGroupedBarChart(data),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(DataProvider data) {
    final studentData = data.registeredFaces.map((face) {
      final records =
          data.attendanceRecords.where((r) => r.codigo == face.codigo);
      final present = records.where((r) => r.asistio).length;
      final total = records.length;
      final percentage = total > 0 ? (present / total) * 100 : 0;
      return percentage;
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barGroups: List.generate(
          studentData.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: studentData[index].toDouble(),
                color: const Color(0xFF3b82f6),
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < data.registeredFaces.length) {
                  final name =
                      data.registeredFaces[value.toInt()].name.split(' ')[0];
                  return Text(name, style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart(DataProvider data) {
    final present = data.attendanceRecords.where((r) => r.asistio).length;
    final absent = data.attendanceRecords.length - present;

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: present.toDouble(),
            title: '$present',
            color: const Color(0xFF10b981),
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: absent.toDouble(),
            title: '$absent',
            color: const Color(0xFFef4444),
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget _buildLineChart(DataProvider data) {
    final dateMap = <String, int>{};
    for (var record in data.attendanceRecords) {
      if (record.asistio) {
        dateMap[record.fecha] = (dateMap[record.fecha] ?? 0) + 1;
      }
    }

    final sortedDates = dateMap.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dateMap[entry.value]!.toDouble());
    }).toList();

    if (spots.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF8b5cf6),
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildGroupedBarChart(DataProvider data) {
    final periodMap = <String, Map<String, int>>{};

    for (var record in data.attendanceRecords) {
      if (!periodMap.containsKey(record.semestre)) {
        periodMap[record.semestre] = {
          '1er Corte': 0,
          '2do Corte': 0,
          '3er Corte': 0
        };
      }
      if (record.asistio) {
        periodMap[record.semestre]![record.corte] =
            (periodMap[record.semestre]![record.corte] ?? 0) + 1;
      }
    }

    final periods = periodMap.keys.toList()..sort();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(
          periods.length,
          (index) {
            final period = periods[index];
            final data = periodMap[period]!;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                    toY: data['1er Corte']!.toDouble(),
                    color: const Color(0xFF3b82f6),
                    width: 8),
                BarChartRodData(
                    toY: data['2do Corte']!.toDouble(),
                    color: const Color(0xFF10b981),
                    width: 8),
                BarChartRodData(
                    toY: data['3er Corte']!.toDouble(),
                    color: const Color(0xFFf59e0b),
                    width: 8),
              ],
            );
          },
        ),
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildBottomSection(DataProvider data) {
    final recentActivity = data.attendanceRecords.reversed.take(5).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 8),
                    Text('Actividad Reciente',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                ...recentActivity.map((record) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: record.asistio ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(record.nombre,
                                    style: const TextStyle(fontSize: 12)),
                                Text(record.materia,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
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
                              record.asistio ? 'Asistió' : 'Faltó',
                              style: TextStyle(
                                fontSize: 10,
                                color: record.asistio
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('Rostros Registrados',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                ...data.registeredFaces.map((face) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(face.imageUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(face.name,
                                    style: const TextStyle(fontSize: 12)),
                                Text(face.codigo,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(
                            '${face.confidence.toStringAsFixed(1)}%',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.green),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
