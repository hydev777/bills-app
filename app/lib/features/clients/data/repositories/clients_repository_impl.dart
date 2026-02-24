import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/clients/domain/entities/client_entity.dart';
import 'package:app/features/clients/domain/repositories/clients_repository.dart';
import 'package:app/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:app/features/clients/data/models/client_model.dart';
import 'package:dio/dio.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  ClientsRepositoryImpl(this._remote);

  final ClientsRemoteDataSource _remote;

  @override
  Future<Result<ClientsListResult, Failure>> getClients({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await _remote.getClients(
        search: search,
        limit: limit,
        offset: offset,
      );
      final clientsList = data['clients'] as List<dynamic>? ?? [];
      final clients = clientsList
          .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
          .map((m) => m.toEntity())
          .toList();
      final total = data['total'] as int? ?? 0;
      final limitVal = data['limit'] as int? ?? limit;
      final offsetVal = data['offset'] as int? ?? offset;
      return success(ClientsListResult(
        clients: clients,
        total: total,
        limit: limitVal,
        offset: offsetVal,
      ));
    } on DioException catch (e) {
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
