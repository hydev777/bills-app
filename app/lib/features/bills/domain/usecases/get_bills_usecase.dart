import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/bills/domain/repositories/bills_repository.dart';

class GetBillsUseCase {
  GetBillsUseCase(this._repository);

  final BillsRepository _repository;

  Future<Result<BillsListResult, Failure>> call({
    String? status,
    int? userId,
    int? clientId,
    int limit = 50,
    int offset = 0,
  }) {
    return _repository.getBills(
      status: status,
      userId: userId,
      clientId: clientId,
      limit: limit,
      offset: offset,
    );
  }
}

