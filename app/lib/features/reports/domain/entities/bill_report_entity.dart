import 'package:app/features/bills/domain/entities/bill_entity.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';
import 'package:equatable/equatable.dart';

class BillReportEntity extends Equatable {
  const BillReportEntity({
    required this.period,
    required this.anchorDate,
    required this.startDate,
    required this.endDateExclusive,
    required this.billCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.series,
    required this.recentBills,
    required this.recentBillsLimit,
    required this.hasMoreBills,
  });

  final BillReportPeriod period;
  final DateTime anchorDate;
  final DateTime startDate;
  final DateTime endDateExclusive;
  final int billCount;
  final double totalAmount;
  final double averageAmount;
  final List<BillReportBucketEntity> series;
  final List<BillEntity> recentBills;
  final int recentBillsLimit;
  final bool hasMoreBills;

  @override
  List<Object?> get props => [
    period,
    anchorDate,
    startDate,
    endDateExclusive,
    billCount,
    totalAmount,
    averageAmount,
    series,
    recentBills,
    recentBillsLimit,
    hasMoreBills,
  ];
}

class BillReportBucketEntity extends Equatable {
  const BillReportBucketEntity({
    required this.label,
    required this.bucketStart,
    required this.bucketEnd,
    required this.billCount,
    required this.totalAmount,
  });

  final String label;
  final DateTime bucketStart;
  final DateTime bucketEnd;
  final int billCount;
  final double totalAmount;

  @override
  List<Object?> get props => [
    label,
    bucketStart,
    bucketEnd,
    billCount,
    totalAmount,
  ];
}
