import 'package:app/features/bills/data/models/bill_model.dart';
import 'package:app/features/reports/domain/entities/bill_report_entity.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';

class BillReportModel extends BillReportEntity {
  const BillReportModel({
    required super.period,
    required super.anchorDate,
    required super.startDate,
    required super.endDateExclusive,
    required super.billCount,
    required super.totalAmount,
    required super.averageAmount,
    required super.series,
    required super.recentBills,
    required super.recentBillsLimit,
    required super.hasMoreBills,
  });

  factory BillReportModel.fromJson(Map<String, dynamic> json) {
    final series = json['series'] as List<dynamic>? ?? const [];
    final recentBills = json['recentBills'] as List<dynamic>? ?? const [];
    return BillReportModel(
      period: BillReportPeriod.fromApiValue(json['period'] as String? ?? 'day'),
      anchorDate: DateTime.parse(json['anchorDate'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDateExclusive: DateTime.parse(json['endDateExclusive'] as String),
      billCount: json['billCount'] as int? ?? 0,
      totalAmount: _toDouble(json['totalAmount']),
      averageAmount: _toDouble(json['averageAmount']),
      series: series
          .map(
            (item) =>
                BillReportBucketModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      recentBills: recentBills
          .map(
            (item) =>
                BillModel.fromJson(item as Map<String, dynamic>).toEntity(),
          )
          .toList(),
      recentBillsLimit: json['recentBillsLimit'] as int? ?? 0,
      hasMoreBills: json['hasMoreBills'] as bool? ?? false,
    );
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class BillReportBucketModel extends BillReportBucketEntity {
  const BillReportBucketModel({
    required super.label,
    required super.bucketStart,
    required super.bucketEnd,
    required super.billCount,
    required super.totalAmount,
  });

  factory BillReportBucketModel.fromJson(Map<String, dynamic> json) {
    return BillReportBucketModel(
      label: json['label'] as String? ?? '',
      bucketStart: DateTime.parse(json['bucketStart'] as String),
      bucketEnd: DateTime.parse(json['bucketEnd'] as String),
      billCount: json['billCount'] as int? ?? 0,
      totalAmount: BillReportModel._toDouble(json['totalAmount']),
    );
  }
}
