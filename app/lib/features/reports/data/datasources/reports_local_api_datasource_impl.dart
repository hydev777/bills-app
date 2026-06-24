import 'package:app/features/reports/data/datasources/reports_local_api_datasource.dart';
import 'package:app/features/reports/data/models/bill_report_model.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';
import 'package:dio/dio.dart';

class ReportsLocalApiDataSourceImpl implements ReportsLocalApiDataSource {
  ReportsLocalApiDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<BillReportModel> getBillReport({
    required BillReportPeriod period,
    required DateTime anchorDate,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/reports/bills',
      queryParameters: {
        'period': period.apiValue,
        'anchorDate': _dateOnly(anchorDate),
      },
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty response',
      );
    }
    return BillReportModel.fromJson(data);
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
