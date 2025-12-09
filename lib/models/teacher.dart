class Teacher {
  final String id;
  final String codigo;
  final String nombre;
  final String email;
  final String departamento;
  final String
      password; // En producción esto debería estar encriptado en backend

  Teacher({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.email,
    required this.departamento,
    required this.password,
  });
}
