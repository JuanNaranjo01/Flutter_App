import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/face_registration_screen.dart';
import 'screens/face_recognition_screen.dart';
import 'screens/chat_interface_screen.dart';
import 'screens/face_management_screen.dart';
import 'providers/data_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DataProvider(),
      child: const AsistenciaGuardApp(),
    ),
  );
}

class AsistenciaGuardApp extends StatelessWidget {
  const AsistenciaGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, data, _) {
        return MaterialApp(
          title: 'AsistenciaGuard',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          home: data.isAuthenticated
              ? const DashboardScreen()
              : const LoginScreen(),
        );
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
    FaceRecognitionScreen(),
    ChatInterfaceScreen(),
    FaceManagementScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF3b82f6),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Registrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face_retouching_natural),
            label: 'Reconocer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Asistencias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Gestión',
          ),
        ],
      ),
    );
  }
}
