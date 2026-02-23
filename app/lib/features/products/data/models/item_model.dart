import 'package:app/features/products/domain/entities/item_entity.dart';

class ItemModel extends ItemEntity {
  const ItemModel({
    required super.id,
    required super.name,
    super.description,
    required super.unitPrice,
    super.categoryId,
    required super.itbisRateId,
    super.categoryName,
    super.itbisRateName,
    super.itbisPercentage,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final itbisRate = json['itbisRate'] as Map<String, dynamic>?;
    return ItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      unitPrice: _toDouble(json['unitPrice']),
      categoryId: json['categoryId'] as int?,
      itbisRateId: json['itbisRateId'] as int,
      itbisRateName: itbisRate?['name'] as String?,
      itbisPercentage: itbisRate != null ? _toDouble(itbisRate['percentage']) : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  ItemEntity toEntity() => ItemEntity(
        id: id,
        name: name,
        description: description,
        unitPrice: unitPrice,
        categoryId: categoryId,
        itbisRateId: itbisRateId,
        categoryName: categoryName,
        itbisRateName: itbisRateName,
        itbisPercentage: itbisPercentage,
      );
}
