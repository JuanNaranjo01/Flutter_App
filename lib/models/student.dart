class Student {
  final String codigo;
  final String nombreCompleto;
  final String nombre;
  final String apellidos;
  final String emailInstitucional;
  final String emailPersonal;
  final String programa;
  final int semestre;
  final String movil;
  final String telefonos;
  final bool tieneEmbeddings;
  final int numEmbeddings;

  Student({
    required this.codigo,
    required this.nombreCompleto,
    required this.nombre,
    required this.apellidos,
    required this.emailInstitucional,
    required this.emailPersonal,
    required this.programa,
    required this.semestre,
    required this.movil,
    required this.telefonos,
    required this.tieneEmbeddings,
    required this.numEmbeddings,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      codigo: json['codigo'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      emailInstitucional: json['email_institucional'] ?? '',
      emailPersonal: json['email_personal'] ?? '',
      programa: json['programa'] ?? '',
      semestre: json['semestre'] ?? 0,
      movil: json['movil'] ?? '',
      telefonos: json['telefonos'] ?? '',
      tieneEmbeddings: json['tiene_embeddings'] ?? false,
      numEmbeddings: json['num_embeddings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre_completo': nombreCompleto,
      'nombre': nombre,
      'apellidos': apellidos,
      'email_institucional': emailInstitucional,
      'email_personal': emailPersonal,
      'programa': programa,
      'semestre': semestre,
      'movil': movil,
      'telefonos': telefonos,
      'tiene_embeddings': tieneEmbeddings,
      'num_embeddings': numEmbeddings,
    };
  }
}

class SearchStudentResponse {
  final bool success;
  final bool found;
  final int? count;
  final List<Student>? students;
  final String? message;

  SearchStudentResponse({
    required this.success,
    required this.found,
    this.count,
    this.students,
    this.message,
  });

  factory SearchStudentResponse.fromJson(Map<String, dynamic> json) {
    return SearchStudentResponse(
      success: json['success'] ?? false,
      found: json['found'] ?? false,
      count: json['count'],
      students: (json['students'] as List<dynamic>?)
          ?.map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'],
    );
  }
}

class StudentEmbeddingResponse {
  final bool success;
  final String message;
  final StudentInfo? student;
  final List<FailedImage>? failedImages;

  StudentEmbeddingResponse({
    required this.success,
    required this.message,
    this.student,
    this.failedImages,
  });

  factory StudentEmbeddingResponse.fromJson(Map<String, dynamic> json) {
    return StudentEmbeddingResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      student: json['student'] != null
          ? StudentInfo.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      failedImages: (json['failed_images'] as List<dynamic>?)
          ?.map((e) => FailedImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentInfo {
  final String codigo;
  final String nombre;
  final String apellido;
  final String nombreCompleto;
  final String programa;
  final int idUsuario;
  final int embeddingsSaved;
  final int embeddingsFailed;
  final int totalImages;

  StudentInfo({
    required this.codigo,
    required this.nombre,
    required this.apellido,
    required this.nombreCompleto,
    required this.programa,
    required this.idUsuario,
    required this.embeddingsSaved,
    required this.embeddingsFailed,
    required this.totalImages,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      programa: json['programa'] ?? '',
      idUsuario: json['id_usuario'] ?? 0,
      embeddingsSaved: json['embeddings_saved'] ?? 0,
      embeddingsFailed: json['embeddings_failed'] ?? 0,
      totalImages: json['total_images'] ?? 0,
    );
  }
}

class FailedImage {
  final int imageNumber;
  final String reason;

  FailedImage({
    required this.imageNumber,
    required this.reason,
  });

  factory FailedImage.fromJson(Map<String, dynamic> json) {
    return FailedImage(
      imageNumber: json['image_number'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

class OtpRequestResponse {
  final bool success;
  final String message;
  final int? expiresInSeconds;
  final String? emailMasked;

  OtpRequestResponse({
    required this.success,
    required this.message,
    this.expiresInSeconds,
    this.emailMasked,
  });

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      expiresInSeconds: json['expires_in_seconds'],
      emailMasked: json['email_masked'],
    );
  }
}

class OtpVerifyResponse {
  final bool success;
  final String message;
  final String? otpToken;
  final int? expiresInSeconds;

  OtpVerifyResponse({
    required this.success,
    required this.message,
    this.otpToken,
    this.expiresInSeconds,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      otpToken: json['otp_token'],
      expiresInSeconds: json['expires_in_seconds'],
    );
  }
}
