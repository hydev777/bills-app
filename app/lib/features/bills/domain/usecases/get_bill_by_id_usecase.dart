import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/bills/domain/entities/bill_entity.dart';
import 'package:app/features/bills/domain/repositories/bills_repository.dart';

class GetBillByIdUseCase {
  GetBillByIdUseCase(this._repository);

  final BillsRepository _repository;

  Future<Result<BillEntity, Failure>> call({required int id}) {
    return _repository.getBillById(id);
  }
}

