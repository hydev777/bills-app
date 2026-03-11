import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/bills/domain/entities/bill_entity.dart';
import 'package:app/features/bills/domain/repositories/bills_repository.dart';
import 'package:app/features/sales/domain/entities/sale_line_entity.dart';

class CreateSaleBillUseCase {
  CreateSaleBillUseCase(this._repository);

  final BillsRepository _repository;

  Future<Result<BillEntity, Failure>> call({
    required List<SaleLineEntity> lines,
    required double subtotal,
    required double cashGiven,
    int? clientId,
  }) async {
    return _repository.createSaleBill(
      lines: lines,
      subtotal: subtotal,
      cashGiven: cashGiven,
      clientId: clientId,
    );
  }
}

