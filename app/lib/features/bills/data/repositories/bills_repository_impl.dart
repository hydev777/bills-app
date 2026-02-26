import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/bills/data/datasources/bills_remote_datasource.dart';
import 'package:app/features/bills/data/models/bill_model.dart';
import 'package:app/features/bills/domain/entities/bill_entity.dart';
import 'package:app/features/bills/domain/repositories/bills_repository.dart';
import 'package:dio/dio.dart';

class BillsRepositoryImpl implements BillsRepository {
  BillsRepositoryImpl(this._remote);

  final BillsRemoteDataSource _remote;

  @override
  Future<Result<BillsListResult, Failure>> getBills({
    String? status,
    int? userId,
    int? clientId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await _remote.getBills(
        status: status,
        userId: userId,
        clientId: clientId,
        limit: limit,
        offset: offset,
      );
      final billsList = data['bills'] as List<dynamic>? ?? [];
      final bills = billsList
          .map((e) => BillModel.fromJson(e as Map<String, dynamic>))
          .map((m) => m.toEntity())
          .toList();
      final total = data['total'] as int? ?? 0;
      final limitVal = data['limit'] as int? ?? limit;
      final offsetVal = data['offset'] as int? ?? offset;
      return success(
        BillsListResult(
          bills: bills,
          total: total,
          limit: limitVal,
          offset: offsetVal,
        ),
      );
    } on DioException catch (e) {
      return failure(ServerFailure(message: _messageFromDio(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BillEntity, Failure>> getBillById(int id) async {
    try {
      final model = await _remote.getBillById(id);
      return success<BillEntity, Failure>(model.toEntity());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) {
        return failure(
          const ServerFailure(message: 'No tienes permisos para ver facturas'),
        );
      }
      if (status == 404) {
        return failure(
          const ServerFailure(message: 'Factura no encontrada'),
        );
      }
      return failure(ServerFailure(message: _messageFromDio(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<BillEntity, Failure>> getBillByPublicId(
    String publicId,
  ) async {
    try {
      final model = await _remote.getBillByPublicId(publicId);
      return success<BillEntity, Failure>(model.toEntity());
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) {
        return failure(
          const ServerFailure(message: 'No tienes permisos para ver facturas'),
        );
      }
      if (status == 404) {
        return failure(
          const ServerFailure(message: 'Factura no encontrada'),
        );
      }
      return failure(ServerFailure(message: _messageFromDio(e)));
    } catch (e) {
      return failure(ServerFailure(message: e.toString()));
    }
  }

  String _messageFromDio(DioException e) {
    final m = e.message;
    if (m != null && m.isNotEmpty) return m;
    final code = e.response?.statusCode;
    if (code != null) return 'Error del servidor: $code';
    return 'Error de conexión';
  }
}

