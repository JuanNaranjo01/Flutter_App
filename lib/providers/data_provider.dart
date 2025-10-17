import 'package:flutter/foundation.dart';
import '../models/registered_face.dart';
import '../models/attendance_record.dart';

class DataProvider with ChangeNotifier {
  final List<Teacher> _teachers = [
      nombre: 'Dr. Juan Carlos Pérez',
      email: 'juan.perez@uceva.edu.co',
      departamento: 'Ingeniería de Sistemas',
      password: 'uceva2024', // En producción esto debe estar hasheado
    ),
    Teacher(
      id: '2',
      codigo: 'DOC67890',
      nombre: 'Dra. María Elena Rodríguez',
      email: 'maria.rodriguez@uceva.edu.co',
      departamento: 'Ingeniería de Software',
      password: 'uceva2024',
    ),
  ];

  Teacher? _currentTeacher;
  bool _isAuthenticated = false;

  Teacher? get currentTeacher => _currentTeacher;
  bool get isAuthenticated => _isAuthenticated;

  // Método de login
  bool login(String codigo, String password) {
    try {
      final teacher = _teachers.firstWhere(
        (t) => t.codigo == codigo && t.password == password,
      );
      _currentTeacher = teacher;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Método de logout
  void logout() {
    _currentTeacher = null;
    _isAuthenticated = false;
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

  final List<AttendanceRecord> _attendanceRecords = [
    // 2024-I - 1er Corte
    AttendanceRecord(
        fecha: '2024-01-15',
        codigo: 'EST001234',
        nombre: 'María González López',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 4,
        semestre: '2024-I',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-01-15',
        codigo: 'EST001567',
        nombre: 'Carlos Ramírez Torres',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 4,
        semestre: '2024-I',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-01-15',
        codigo: 'EST001890',
        nombre: 'Ana Patricia Morales',
        materia: 'Programación Orientada a Objetos',
        asistio: false,
        horasAsistidas: 0,
        semestre: '2024-I',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-01-22',
        codigo: 'EST001234',
        nombre: 'María González López',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 3,
        semestre: '2024-I',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-01-22',
        codigo: 'EST001567',
        nombre: 'Carlos Ramírez Torres',
        materia: 'Programación Orientada a Objetos',
        asistio: false,
        horasAsistidas: 0,
        semestre: '2024-I',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-01-22',
        codigo: 'EST001890',
        nombre: 'Ana Patricia Morales',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 3,
        semestre: '2024-I',
        corte: '1er Corte'),
    // 2024-I - 2do Corte
    AttendanceRecord(
        fecha: '2024-03-10',
        codigo: 'EST001234',
        nombre: 'María González López',
        materia: 'Programación Orientada a Objetos',
        asistio: false,
        horasAsistidas: 0,
        semestre: '2024-I',
        corte: '2do Corte'),
    AttendanceRecord(
        fecha: '2024-03-10',
        codigo: 'EST001567',
        nombre: 'Carlos Ramírez Torres',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 2,
        semestre: '2024-I',
        corte: '2do Corte'),
    AttendanceRecord(
        fecha: '2024-03-10',
        codigo: 'EST001890',
        nombre: 'Ana Patricia Morales',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 2,
        semestre: '2024-I',
        corte: '2do Corte'),
    // 2024-I - 3er Corte
    AttendanceRecord(
        fecha: '2024-05-12',
        codigo: 'EST001234',
        nombre: 'María González López',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 4,
        semestre: '2024-I',
        corte: '3er Corte'),
    AttendanceRecord(
        fecha: '2024-05-12',
        codigo: 'EST001567',
        nombre: 'Carlos Ramírez Torres',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 4,
        semestre: '2024-I',
        corte: '3er Corte'),
    AttendanceRecord(
        fecha: '2024-05-12',
        codigo: 'EST001890',
        nombre: 'Ana Patricia Morales',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 4,
        semestre: '2024-I',
        corte: '3er Corte'),
    // 2024-II - 1er Corte
    AttendanceRecord(
        fecha: '2024-08-15',
        codigo: 'EST001234',
        nombre: 'María González López',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 4,
        semestre: '2024-II',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-08-15',
        codigo: 'EST001567',
        nombre: 'Carlos Ramírez Torres',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 4,
        semestre: '2024-II',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-08-15',
        codigo: 'EST001890',
        nombre: 'Ana Patricia Morales',
        materia: 'Programación Orientada a Objetos',
        asistio: false,
        horasAsistidas: 0,
        semestre: '2024-II',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-09-02',
        codigo: 'EST001234',
        nombre: 'María González López',
        materia: 'Programación Orientada a Objetos',
        asistio: false,
        horasAsistidas: 0,
        semestre: '2024-II',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-09-02',
        codigo: 'EST001567',
        nombre: 'Carlos Ramírez Torres',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 2,
        semestre: '2024-II',
        corte: '1er Corte'),
    AttendanceRecord(
        fecha: '2024-09-02',
        codigo: 'EST001890',
        nombre: 'Ana Patricia Morales',
        materia: 'Programación Orientada a Objetos',
        asistio: true,
        horasAsistidas: 2,
        semestre: '2024-II',
        corte: '1er Corte'),
  ];

  List<RegisteredFace> get registeredFaces => _registeredFaces;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;

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
}
