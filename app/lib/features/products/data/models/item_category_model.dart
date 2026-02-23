import 'package:app/features/products/domain/entities/item_category_entity.dart';

class ItemCategoryModel extends ItemCategoryEntity {
  const ItemCategoryModel({
    required super.id,
    required super.name,
    super.description,
  });

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) {
    return ItemCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  ItemCategoryEntity toEntity() => ItemCategoryEntity(
        id: id,
        name: name,
        description: description,
      );
}
