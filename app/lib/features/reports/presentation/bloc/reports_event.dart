import 'package:app/features/reports/domain/entities/bill_report_period.dart';
import 'package:equatable/equatable.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

final class ReportsLoaded extends ReportsEvent {
  const ReportsLoaded({required this.period, required this.anchorDate});

  final BillReportPeriod period;
  final DateTime anchorDate;

  @override
  List<Object?> get props => [period, anchorDate];
}
