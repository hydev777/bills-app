import 'package:app/features/bills/domain/entities/bill_entity.dart';

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.publicId,
    required super.title,
    required super.status,
    required super.amount,
    required super.createdAt,
    super.description,
    super.clientId,
    super.clientName,
    super.clientIdentifier,
    super.userId,
    super.userName,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;

    return BillModel(
      id: json['id'] as int,
      publicId: json['publicId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      amount: _toDouble(json['amount']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      clientId: client != null ? client['id'] as int? : null,
      clientName: client != null ? client['name'] as String? : null,
      clientIdentifier: client != null ? client['identifier'] as String? : null,
      userId: user != null ? user['id'] as int? : null,
      userName: user != null ? user['username'] as String? : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  BillEntity toEntity() => BillEntity(
        id: id,
        publicId: publicId,
        title: title,
        description: description,
        status: status,
        amount: amount,
        createdAt: createdAt,
        clientId: clientId,
        clientName: clientName,
        clientIdentifier: clientIdentifier,
        userId: userId,
        userName: userName,
      );
}

