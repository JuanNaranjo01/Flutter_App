import 'package:flutter/foundation.dart';
import '../models/registered_face.dart';
import '../models/attendance_record.dart';
import '../models/teacher.dart';
import '../models/student.dart';
import '../services/api_services.dart';
import '../services/auth_service.dart';

class DataProvider with ChangeNotifier {
  Teacher? _currentTeacher;
  bool _isAuthenticated = false;
  final AuthService _authService = AuthService();

  Teacher? get currentTeacher => _currentTeacher;
  bool get isAuthenticated => _isAuthenticated;
  AuthService get authService => _authService;

  /// Método de login con objeto Teacher (usado por AuthService)
  void loginWithTeacher(Teacher teacher) {
    _currentTeacher = teacher;
    _isAuthenticated = true;
    notifyListeners();
    refreshAttendanceRecords();
  }

  /// Método de logout
  Future<void> logout() async {
    // Limpiar token en el servidor y localmente
    await _authService.logoutTeacher();
    
    _currentTeacher = null;
    _isAuthenticated = false;
    _attendanceRecords = [];
    _isLoadingAttendance = false;
    _attendanceError = null;
    notifyListeners();
  }

  final List<RegisteredFace> _registeredFaces = [
    RegisteredFace(
      id: '1',
      name: 'María González López',
      email: 'maria.gonzalez@universidad.edu',
      codigo: 'EST001234',
      materia: 'Programación Orientada a Objetos',
      carrera: 'Ingeniería en Sistemas',
      semestre: '3er Semestre',
      registrationDate: '2024-01-15',
      confidence: 98.5,
      imageUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
    ),
    RegisteredFace(
      id: '2',
      name: 'Carlos Ramírez Torres',
      email: 'carlos.ramirez@universidad.edu',
      codigo: 'EST001567',
      materia: 'Programación Orientada a Objetos',
      carrera: 'Ingeniería en Software',
      semestre: '4to Semestre',
      registrationDate: '2024-01-16',
      confidence: 97.2,
      imageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    ),
    RegisteredFace(
      id: '3',
      name: 'Ana Patricia Morales',
      email: 'ana.morales@universidad.edu',
      codigo: 'EST001890',
      materia: 'Programación Orientada a Objetos',
      carrera: 'Ingeniería en Informática',
      semestre: '5to Semestre',
      registrationDate: '2024-01-17',
      confidence: 96.8,
      imageUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
    ),
  ];

  // Registros de asistencia (se cargan desde el backend)
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoadingAttendance = false;
  String? _attendanceError;

  List<RegisteredFace> get registeredFaces => _registeredFaces;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  bool get isLoadingAttendance => _isLoadingAttendance;
  String? get attendanceError => _attendanceError;

  // Estudiante actualmente seleccionado para registro de embeddings
  Student? _currentStudent;
  Student? get currentStudent => _currentStudent;

  void addRegisteredFace(RegisteredFace face) {
    _registeredFaces.add(face);
    notifyListeners();
  }

  void removeRegisteredFace(String id) {
    _registeredFaces.removeWhere((face) => face.id == id);
    notifyListeners();
  }

  void addAttendanceRecord(AttendanceRecord record) {
    _attendanceRecords.add(record);
    notifyListeners();
  }

  /// Refresca los registros de asistencia desde el backend
  Future<void> refreshAttendanceRecords() async {
    if (_currentTeacher == null) return;

    _isLoadingAttendance = true;
    _attendanceError = null;
    notifyListeners();

    try {
      final response = await ApiService.getAttendanceHistory(
        emailDocente: _currentTeacher!.email,
      );

      if (response.success) {
        _attendanceRecords = response.records;
        _attendanceError = null;
      } else {
        _attendanceError = response.error ?? 'Error al cargar asistencias';
      }
    } catch (e) {
      _attendanceError = 'Error al cargar asistencias: $e';
    }

    _isLoadingAttendance = false;
    notifyListeners();
  }

  // Métodos para gestión de estudiante en proceso de registro
  void setCurrentStudent(Student? student) {
    _currentStudent = student;
    notifyListeners();
  }

  void clearCurrentStudent() {
    _currentStudent = null;
    notifyListeners();
  }
}
