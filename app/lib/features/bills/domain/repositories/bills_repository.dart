import 'package:app/core/errors/failures.dart';
import 'package:app/core/errors/result.dart';
import 'package:app/features/bills/domain/entities/bill_entity.dart';
import 'package:app/features/sales/domain/entities/sale_line_entity.dart';

abstract class BillsRepository {
  /// Returns bills list with pagination. GET /api/bills.
  Future<Result<BillsListResult, Failure>> getBills({
    String? status,
    int? userId,
    int? clientId,
    int limit = 50,
    int offset = 0,
  });

  /// Get a bill by numeric id. GET /api/bills/:id.
  Future<Result<BillEntity, Failure>> getBillById(int id);

  /// Get a bill by public id. GET /api/bills/public/:publicId.
  Future<Result<BillEntity, Failure>> getBillByPublicId(String publicId);

  /// Create a sale bill and its lines using POST /api/bills and /api/bill-items.
  Future<Result<BillEntity, Failure>> createSaleBill({
    required List<SaleLineEntity> lines,
    required double subtotal,
    required double cashGiven,
    int? clientId,
  });
}

class BillsListResult {
  const BillsListResult({
    required this.bills,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<BillEntity> bills;
  final int total;
  final int limit;
  final int offset;
}

