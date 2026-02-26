import 'package:equatable/equatable.dart';

class BillEntity extends Equatable {
  const BillEntity({
    required this.id,
    required this.publicId,
    required this.title,
    this.description,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.clientId,
    this.clientName,
    this.clientIdentifier,
    this.userId,
    this.userName,
  });

  final int id;
  final String publicId;
  final String title;
  final String? description;
  final String status;
  final double amount;
  final DateTime createdAt;
  final int? clientId;
  final String? clientName;
  final String? clientIdentifier;
  final int? userId;
  final String? userName;

  @override
  List<Object?> get props => [
        id,
        publicId,
        title,
        description,
        status,
        amount,
        createdAt,
        clientId,
        clientName,
        clientIdentifier,
        userId,
        userName,
      ];
}

