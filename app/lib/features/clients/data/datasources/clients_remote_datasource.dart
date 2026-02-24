abstract class ClientsRemoteDataSource {
  /// GET /api/clients. Query: search, limit, offset.
  Future<Map<String, dynamic>> getClients({
    String? search,
    int limit = 50,
    int offset = 0,
  });
}
