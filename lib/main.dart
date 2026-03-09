import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:google_fonts/google_fonts.dart'; // Comentado temporalmente por error de red
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/face_registration_screen.dart';
// import 'screens/face_recognition_screen.dart'; // Comentado - no usado actualmente
import 'screens/attendance_registration_screen.dart';
import 'screens/chat_interface_screen.dart';
import 'providers/data_provider.dart';

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
      // Inicia directamente con el LoginScreen
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
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
    FaceRegistrationScreen(),
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
            icon: Icon(Icons.add_a_photo),
            label: 'Registrar',
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
