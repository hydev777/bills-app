import 'package:equatable/equatable.dart';

class ItemEntity extends Equatable {
  const ItemEntity({
    required this.id,
    required this.name,
    this.description,
    required this.unitPrice,
    this.categoryId,
    required this.itbisRateId,
    this.categoryName,
    this.itbisRateName,
    this.itbisPercentage,
  });

  final int id;
  final String name;
  final String? description;
  final double unitPrice;
  final int? categoryId;
  final int itbisRateId;
  final String? categoryName;
  final String? itbisRateName;
  final double? itbisPercentage;

  @override
  List<Object?> get props =>
      [id, name, description, unitPrice, categoryId, itbisRateId];
}
