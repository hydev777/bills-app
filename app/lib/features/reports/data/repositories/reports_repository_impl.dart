import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/reports/data/datasources/reports_local_api_datasource.dart';
import 'package:app/features/reports/domain/entities/bill_report_entity.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';
import 'package:app/features/reports/domain/repositories/reports_repository.dart';
import 'package:dio/dio.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._localApi);

  final ReportsLocalApiDataSource _localApi;

  @override
  Future<Result<BillReportEntity, Failure>> getBillReport({
    required BillReportPeriod period,
    required DateTime anchorDate,
  }) async {
    try {
      final report = await _localApi.getBillReport(
        period: period,
        anchorDate: anchorDate,
      );
      return success(report);
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDio(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  String _messageFromDio(DioException e) {
    final responseMessage = e.response?.data is Map<String, dynamic>
        ? (e.response?.data as Map<String, dynamic>)['error'] as String?
        : null;
    if (responseMessage != null && responseMessage.isNotEmpty) {
      return responseMessage;
    }
    final message = e.message;
    if (message != null && message.isNotEmpty) return message;
    final code = e.response?.statusCode;
    if (code != null) return 'Error del servidor: $code';
    return 'Error de conexion';
  }
}
