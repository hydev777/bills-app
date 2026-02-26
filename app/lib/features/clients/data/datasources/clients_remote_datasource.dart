abstract class ClientsRemoteDataSource {
  /// GET /api/clients. Query: search, limit, offset.
  Future<Map<String, dynamic>> getClients({
    String? search,
    int limit = 50,
    int offset = 0,
  });

  /// POST /api/clients - Create client.
  Future<Map<String, dynamic>> createClient({
    required String name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  });

  /// PUT /api/clients/:id - Update client.
  Future<Map<String, dynamic>> updateClient(
    int id, {
    String? name,
    String? identifier,
    String? taxId,
    String? email,
    String? phone,
    String? address,
  });
}
