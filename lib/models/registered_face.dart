class RegisteredFace {
  final String id;
  final String name;
  final String email;
  final String codigo;
  final String materia;
  final String carrera;
  final String semestre;
  final String registrationDate;
  final double confidence;
  final String imageUrl;

  RegisteredFace({
    required this.id,
    required this.name,
    required this.email,
    required this.codigo,
    required this.materia,
    required this.carrera,
    required this.semestre,
    required this.registrationDate,
    required this.confidence,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'codigo': codigo,
      'materia': materia,
      'carrera': carrera,
      'semestre': semestre,
      'registrationDate': registrationDate,
      'confidence': confidence,
      'imageUrl': imageUrl,
    };
  }

  factory RegisteredFace.fromJson(Map<String, dynamic> json) {
    return RegisteredFace(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      codigo: json['codigo'],
      materia: json['materia'],
      carrera: json['carrera'],
      semestre: json['semestre'],
      registrationDate: json['registrationDate'],
      confidence: json['confidence'],
      imageUrl: json['imageUrl'],
    );
  }
}
