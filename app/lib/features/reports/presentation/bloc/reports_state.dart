import 'package:app/features/reports/domain/entities/bill_report_entity.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';
import 'package:equatable/equatable.dart';

sealed class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

final class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

final class ReportsLoading extends ReportsState {
  const ReportsLoading({required this.period, required this.anchorDate});

  final BillReportPeriod period;
  final DateTime anchorDate;

  @override
  List<Object?> get props => [period, anchorDate];
}

final class ReportsLoadedState extends ReportsState {
  const ReportsLoadedState(this.report);

  final BillReportEntity report;

  @override
  List<Object?> get props => [report];
}

final class ReportsError extends ReportsState {
  const ReportsError({
    required this.message,
    required this.period,
    required this.anchorDate,
  });

  final String message;
  final BillReportPeriod period;
  final DateTime anchorDate;

  @override
  List<Object?> get props => [message, period, anchorDate];
}
