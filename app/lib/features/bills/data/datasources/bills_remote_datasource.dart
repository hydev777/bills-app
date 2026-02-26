import 'package:app/features/bills/data/models/bill_model.dart';

abstract class BillsRemoteDataSource {
  /// GET /api/bills - List bills (branch-scoped).
  /// Optional query: status, user_id, client_id, limit, offset.
  Future<Map<String, dynamic>> getBills({
    String? status,
    int? userId,
    int? clientId,
    int limit = 50,
    int offset = 0,
  });

  /// GET /api/bills/:id - Get bill by numeric id.
  Future<BillModel> getBillById(int id);

  /// GET /api/bills/public/:publicId - Get bill by public UUID.
  Future<BillModel> getBillByPublicId(String publicId);
}

