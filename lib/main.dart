import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:google_fonts/google_fonts.dart'; // Comentado temporalmente por error de red
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
// import 'screens/face_registration_screen.dart'; // Movido a estudiantes
import 'screens/attendance_registration_screen.dart';
import 'screens/chat_interface_screen.dart';
import 'screens/student_login_screen.dart';
import 'screens/student_face_registration_screen.dart';
import 'providers/data_provider.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF007f2f).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school,
                  size: 60,
                  color: Color(0xFF007f2f),
                ),
              ),
              const SizedBox(height: 32),

              // Título principal
              const Text(
                'Synkro Asis',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007f2f),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtítulo
              const Text(
                'Sistema de Asistencia con Reconocimiento Facial',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Botón para docentes
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  icon: const Icon(Icons.person, size: 24),
                  label: const Text(
                    'Iniciar sesión como docente',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF007f2f),
                    side: const BorderSide(color: Color(0xFF007f2f)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón para estudiantes
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/student_login'),
                  icon: const Icon(Icons.face, size: 24),
                  label: const Text(
                    'Iniciar sesión como estudiante',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF007f2f),
                    side: const BorderSide(color: Color(0xFF007f2f)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Información adicional
              const Text(
                'Universidad Corporativa Empresarial Virtual y a Distancia',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => DataProvider(),
      child: const AsistenciaGuardApp(),
    ),
  );
}

class AsistenciaGuardApp extends StatelessWidget {
  const AsistenciaGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synkro Asis',
      debugShowCheckedModeBanner: false,
      // Configuración de localización para widgets de fecha
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés
      ],
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007f2f), // Verde corporativo UCEVA
          brightness: Brightness.light,
        ),
        // textTheme: GoogleFonts.interTextTheme(), // Comentado temporalmente por error de red
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF007f2f),
          foregroundColor: Colors.white,
        ),
      ),
      // Inicia con pantalla de selección
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
        '/student_login': (context) => const StudentLoginScreen(),
        '/student_face_registration': (context) => const StudentFaceRegistrationScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AttendanceRegistrationScreen(),
    // FaceRecognitionScreen(), // Oculta temporalmente
    ChatInterfaceScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // ✅ Actualizar datos cuando se navega a Inicio (Dashboard)
    if (index == 0) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.refreshAttendanceRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF007f2f), // Verde corporativo UCEVA
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Asistencia',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.face_retouching_natural),
          //   label: 'Reconocer',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Consultas',
          ),
        ],
      ),
    );
  }
}
