class GenerateCertificateResponseModel {
  const GenerateCertificateResponseModel({required this.certificateId});

  final String certificateId;

  factory GenerateCertificateResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GenerateCertificateResponseModel(
      certificateId: json['certificate_id']?.toString() ?? '',
    );
  }
}
