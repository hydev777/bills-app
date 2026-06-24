import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/reports/domain/entities/bill_report_entity.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';

abstract class ReportsRepository {
  Future<Result<BillReportEntity, Failure>> getBillReport({
    required BillReportPeriod period,
    required DateTime anchorDate,
  });
}
