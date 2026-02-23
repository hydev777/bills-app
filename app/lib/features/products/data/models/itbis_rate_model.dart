import 'package:app/features/products/domain/entities/itbis_rate_entity.dart';

class ItbisRateModel extends ItbisRateEntity {
  const ItbisRateModel({
    required super.id,
    required super.name,
    required super.percentage,
  });

  factory ItbisRateModel.fromJson(Map<String, dynamic> json) {
    return ItbisRateModel(
      id: json['id'] as int,
      name: json['name'] as String,
      percentage: _toDouble(json['percentage']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  ItbisRateEntity toEntity() => ItbisRateEntity(
        id: id,
        name: name,
        percentage: percentage,
      );
}
