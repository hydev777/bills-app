import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/reports/domain/entities/bill_report_entity.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';
import 'package:app/features/reports/domain/repositories/reports_repository.dart';

class GetBillReportUseCase {
  const GetBillReportUseCase(this._repository);

  final ReportsRepository _repository;

  Future<Result<BillReportEntity, Failure>> call({
    required BillReportPeriod period,
    required DateTime anchorDate,
  }) {
    return _repository.getBillReport(period: period, anchorDate: anchorDate);
  }
}
