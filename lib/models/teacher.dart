class Teacher {
  final dynamic id; // id_docente
  final String codigo; // identificacion
  final String nombre; // nombre_docente
  final String email; // correo
  final String? correoPersonal; // correo_personal
  final String? telefono;
  final String? celular;
  final String? dedicacion;
  final String? vinculacion;
  final String? estado; // docentes_en_estado
  final String? periodoSemestral; // periodo_semestral
  final String? nivelAcademico; // nivel_academico

  Teacher({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.email,
    this.correoPersonal,
    this.telefono,
    this.celular,
    this.dedicacion,
    this.vinculacion,
    this.estado,
    this.periodoSemestral,
    this.nivelAcademico,
  });

  /// Constructor desde JSON (para respuestas del backend)
  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      // Soporta ambos formatos: snake_case (BD) y lowercase (endpoint)
      id: json['id_docente'] ?? json['id'],
      codigo: json['identificacion'] ?? json['codigo'] ?? '',
      nombre: json['nombre_docente'] ?? json['nombre'] ?? '',
      email: json['correo'] ?? json['email'] ?? '',
      correoPersonal: json['correo_personal'] ?? json['correo_institucional'],
      telefono: json['telefono'],
      celular: json['celular'],
      dedicacion: json['dedicacion'] ?? json['departamento'],
      vinculacion: json['vinculacion'],
      estado: json['docentes_en_estado'],
      periodoSemestral: json['periodo_semestral'] ?? json['Periodo'],
      nivelAcademico: json['nivel_academico'] ?? json['Semestre'],
    );
  }

  /// Convertir a JSON (para enviar al backend si es necesario)
  Map<String, dynamic> toJson() {
    return {
      'id_docente': id,
      'identificacion': codigo,
      'nombre_docente': nombre,
      'correo': email,
      'correo_personal': correoPersonal,
      'telefono': telefono,
      'celular': celular,
      'dedicacion': dedicacion,
      'vinculacion': vinculacion,
      'docentes_en_estado': estado,
      'periodo_semestral': periodoSemestral,
      'nivel_academico': nivelAcademico,
    };
  }

  @override
  String toString() {
    return 'Teacher(id: $id, codigo: $codigo, nombre: $nombre, email: $email, dedicacion: $dedicacion, estado: $estado)';
  }
}
