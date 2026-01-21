import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/data_provider.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final dataProvider =
                    Provider.of<DataProvider>(context, listen: false);
                final authService = AuthService();

                // Cerrar sesión de Google
                await authService.signOut();

                // Limpiar estado local
                dataProvider.logout();

                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login', (Route<dynamic> route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Cerrar Sesión'),
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
      body: Consumer<DataProvider>(
        builder: (context, data, child) {
          final totalStudents = data.registeredFaces.length;
          final totalRecords = data.attendanceRecords.length;
          final presentRecords =
              data.attendanceRecords.where((r) => r.asistio).length;
          final attendanceRate = totalRecords > 0
              ? ((presentRecords / totalRecords) * 100).round()
              : 0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 210,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF3B82F6),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 70, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.emoji_events,
                                      color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 12),
                                const Text('Bienvenido,',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.currentTeacher?.nombre ?? 'Docente',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  letterSpacing: 0.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (data.currentTeacher?.dedicacion != null &&
                                data.currentTeacher!.dedicacion!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  data.currentTeacher!.dedicacion!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.logout, size: 24),
                      onPressed: () => _showLogoutDialog(context),
                      tooltip: 'Cerrar Sesión',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;

                    Widget statsSection = isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildGradientStatCard(
                                  title: 'Estudiantes Registrados',
                                  value: totalStudents.toString(),
                                  icon: Icons.people,
                                  gradientColors: const [
                                    Color(0xFF3B82F6),
                                    Color(0xFF2563EB)
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildGradientStatCard(
                                  title: 'Tasa de Asistencia',
                                  value: '$attendanceRate%',
                                  icon: Icons.trending_up,
                                  gradientColors: const [
                                    Color(0xFF10B981),
                                    Color(0xFF059669)
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildGradientStatCard(
                                  title: 'Total Asistencias',
                                  value: presentRecords.toString(),
                                  icon: Icons.check_circle,
                                  gradientColors: const [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF7C3AED)
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildGradientStatCard(
                                title: 'Estudiantes Registrados',
                                value: totalStudents.toString(),
                                icon: Icons.people,
                                gradientColors: const [
                                  Color(0xFF3B82F6),
                                  Color(0xFF2563EB)
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildGradientStatCard(
                                title: 'Tasa de Asistencia',
                                value: '$attendanceRate%',
                                icon: Icons.trending_up,
                                gradientColors: const [
                                  Color(0xFF10B981),
                                  Color(0xFF059669)
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildGradientStatCard(
                                title: 'Total Asistencias',
                                value: presentRecords.toString(),
                                icon: Icons.check_circle,
                                gradientColors: const [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF7C3AED)
                                ],
                              ),
                            ],
                          );

                    Widget chart = _buildTrendChart(data);

                    Widget activityFaces = isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 2, child: _buildActivityCard(data)),
                              const SizedBox(width: 12),
                              Expanded(flex: 1, child: _buildFacesCard(data)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildActivityCard(data),
                              const SizedBox(height: 12),
                              _buildFacesCard(data),
                            ],
                          );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        statsSection,
                        const SizedBox(height: 16),
                        chart,
                        const SizedBox(height: 16),
                        activityFaces,
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradientStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: gradientColors[0].withAlpha((0.25 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: Colors.white.withAlpha((0.95 * 255).round()),
                      fontSize: 13)),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.18 * 255).round()),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(DataProvider data) {
    final dateMap = <String, Map<String, int>>{};
    for (var record in data.attendanceRecords) {
      if (!dateMap.containsKey(record.fecha)) {
        dateMap[record.fecha] = {'asistencias': 0, 'total': 0};
      }
      if (record.asistio) {
        dateMap[record.fecha]!['asistencias'] =
            dateMap[record.fecha]!['asistencias']! + 1;
      }
      dateMap[record.fecha]!['total'] = dateMap[record.fecha]!['total']! + 1;
    }

    final sortedDates = dateMap.keys.toList()..sort();
    final spots = <FlSpot>[];
    final totalSpots = <FlSpot>[];
    for (var i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      spots
          .add(FlSpot(i.toDouble(), dateMap[date]!['asistencias']!.toDouble()));
      totalSpots.add(FlSpot(i.toDouble(), dateMap[date]!['total']!.toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Tendencia de Asistencias',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6)
                          .withAlpha((0.08 * 255).round()),
                    ),
                  ),
                  LineChartBarData(
                    spots: totalSpots,
                    isCurved: true,
                    color: const Color(0xFF94A3B8),
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: true),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedDates.length) {
                          final date = sortedDates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(date.substring(5),
                                style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withAlpha((0.16 * 255).round()),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(DataProvider data) {
    final recentActivity = data.attendanceRecords.reversed.take(7).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.access_time, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Actividad Reciente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: recentActivity.map((activity) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.grey.shade100]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activity.asistio ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.nombre,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(activity.materia,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600])),
                        Text(activity.fecha,
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: activity.asistio
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(activity.asistio ? 'Asistió' : 'Faltó',
                        style: TextStyle(
                            fontSize: 11,
                            color: activity.asistio
                                ? Colors.green.shade800
                                : Colors.red.shade800)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildFacesCard(DataProvider data) {
    final faces = data.registeredFaces;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Rostros Registrados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: faces.map((face) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.grey.shade100]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF3B82F6), width: 2),
                      image: DecorationImage(
                          image: NetworkImage(face.imageUrl),
                          fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(face.name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(face.codigo,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                        ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(face.carrera,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    Text('${face.confidence}%',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}
