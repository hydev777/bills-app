import 'package:app/core/local_api/local_api_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

void registerItbisRoutes(
  Router router,
  LocalApiContext context,
  SafeHandler safe,
) {
  router.get(
    '/api/itbis-rates',
    safe((request) => _itbisRates(request, context)),
  );
}

Future<Response> _itbisRates(Request request, LocalApiContext context) async {
  context.requireAuth(request);
  final rows = context.database.read(
    (db) => db.select('SELECT * FROM itbis_rates ORDER BY percentage DESC'),
  );
  return jsonResponse({'itbis_rates': rows.map(itbisRateJson).toList()});
}

Map<String, dynamic> itbisRateJson(Row row) => {
  'id': intValue(row['id']),
  'name': row['name'],
  'percentage': round2(doubleValue(row['percentage'])),
};

void ensureItbisRateExists(Database db, int id) {
  if (db.select('SELECT id FROM itbis_rates WHERE id = ?', [id]).isEmpty) {
    throw const HttpError(404, 'ITBIS rate not found');
  }
}
