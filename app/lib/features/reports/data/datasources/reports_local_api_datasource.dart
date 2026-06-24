import 'package:app/features/reports/data/models/bill_report_model.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';

abstract class ReportsLocalApiDataSource {
  Future<BillReportModel> getBillReport({
    required BillReportPeriod period,
    required DateTime anchorDate,
  });
}
