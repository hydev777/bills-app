import 'package:app/features/auth/domain/entities/branch_entity.dart';

class BranchModel extends BranchEntity {
  const BranchModel({
    required super.id,
    required super.name,
    required super.code,
    super.isPrimary,
    super.canLogin,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
      canLogin: json['canLogin'] as bool? ?? true,
    );
  }

  BranchEntity toEntity() => BranchEntity(
        id: id,
        name: name,
        code: code,
        isPrimary: isPrimary,
        canLogin: canLogin,
      );
}
