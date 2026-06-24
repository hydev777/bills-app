import 'package:app/core/local_api/local_api_bills.dart';
import 'package:app/core/local_api/local_api_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const _recentBillsLimit = 200;

void registerReportRoutes(
  Router router,
  LocalApiContext context,
  SafeHandler safe,
) {
  router.get(
    '/api/reports/bills',
    safe((request) => _billReport(request, context)),
  );
}

Future<Response> _billReport(Request request, LocalApiContext context) async {
  final claims = context.requireAuth(request);
  context.requirePrivilege(claims.userId, claims.role, 'bill', 'read');

  final params = request.url.queryParameters;
  final period = _ReportPeriod.fromValue(params['period'] ?? 'day');
  if (period == null) {
    throw const HttpError(400, 'Invalid report period');
  }

  final anchorDate = _anchorDate(params['anchorDate']);
  final range = _rangeFor(period, anchorDate);
  final bucketDefinitions = _bucketDefinitions(period, range.start);
  final bucketMap = {
    for (final bucket in bucketDefinitions) bucket.key: bucket.toJson(),
  };

  final aggregateRows = context.database.read((db) {
    return db.select(
      '''
SELECT ${period.bucketExpression} AS bucket,
COUNT(*) AS bill_count,
COALESCE(SUM(b.amount), 0) AS total_amount
FROM bills b
WHERE datetime(b.created_at, 'localtime') >= ?
AND datetime(b.created_at, 'localtime') < ?
GROUP BY bucket
''',
      [_sqlDateTime(range.start), _sqlDateTime(range.endExclusive)],
    );
  });

  for (final row in aggregateRows) {
    final key = row['bucket']?.toString();
    final bucket = key == null ? null : bucketMap[key];
    if (bucket == null) continue;
    bucket['billCount'] = intValue(row['bill_count']);
    bucket['totalAmount'] = round2(doubleValue(row['total_amount']));
  }

  final series = bucketDefinitions
      .map((bucket) => bucketMap[bucket.key]!)
      .toList();
  final billCount = series.fold<int>(
    0,
    (sum, bucket) => sum + (bucket['billCount'] as int),
  );
  final totalAmount = round2(
    series.fold<double>(
      0,
      (sum, bucket) => sum + (bucket['totalAmount'] as double),
    ),
  );

  final recentBills = context.database.read((db) {
    return db
        .select(
          '''
SELECT b.*, u.username, u.email AS user_email, c.name AS client_name,
c.identifier AS client_identifier, c.tax_id AS client_tax_id, c.email AS client_email,
c.phone AS client_phone, c.address AS client_address
FROM bills b
JOIN users u ON u.id = b.user_id
LEFT JOIN clients c ON c.id = b.client_id
WHERE datetime(b.created_at, 'localtime') >= ?
AND datetime(b.created_at, 'localtime') < ?
ORDER BY b.created_at DESC
LIMIT ?
''',
          [
            _sqlDateTime(range.start),
            _sqlDateTime(range.endExclusive),
            _recentBillsLimit,
          ],
        )
        .map(billJson)
        .toList();
  });

  return jsonResponse({
    'period': period.value,
    'anchorDate': _dateOnly(anchorDate),
    'startDate': _dateOnly(range.start),
    'endDateExclusive': _dateOnly(range.endExclusive),
    'billCount': billCount,
    'totalAmount': totalAmount,
    'averageAmount': billCount == 0 ? 0.0 : round2(totalAmount / billCount),
    'series': series,
    'recentBills': recentBills,
    'recentBillsLimit': _recentBillsLimit,
    'hasMoreBills': billCount > _recentBillsLimit,
  });
}

DateTime _anchorDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) {
    throw const HttpError(400, 'Invalid anchorDate');
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

_ReportRange _rangeFor(_ReportPeriod period, DateTime anchor) {
  return switch (period) {
    _ReportPeriod.day => _ReportRange(
      anchor,
      anchor.add(const Duration(days: 1)),
    ),
    _ReportPeriod.week => () {
      final start = anchor.subtract(Duration(days: anchor.weekday - 1));
      return _ReportRange(start, start.add(const Duration(days: 7)));
    }(),
    _ReportPeriod.month => () {
      final start = DateTime(anchor.year, anchor.month);
      return _ReportRange(start, DateTime(anchor.year, anchor.month + 1));
    }(),
    _ReportPeriod.year => () {
      final start = DateTime(anchor.year);
      return _ReportRange(start, DateTime(anchor.year + 1));
    }(),
  };
}

List<_ReportBucket> _bucketDefinitions(_ReportPeriod period, DateTime start) {
  return switch (period) {
    _ReportPeriod.day => List.generate(24, (index) {
      final bucketStart = start.add(Duration(hours: index));
      return _ReportBucket(
        key: index.toString().padLeft(2, '0'),
        label: '${index.toString().padLeft(2, '0')}:00',
        start: bucketStart,
        end: bucketStart.add(const Duration(hours: 1)),
      );
    }),
    _ReportPeriod.week => List.generate(7, (index) {
      final bucketStart = start.add(Duration(days: index));
      return _ReportBucket(
        key: _dateOnly(bucketStart),
        label: const ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'][index],
        start: bucketStart,
        end: bucketStart.add(const Duration(days: 1)),
      );
    }),
    _ReportPeriod.month => List.generate(
      DateTime(start.year, start.month + 1, 0).day,
      (index) {
        final bucketStart = start.add(Duration(days: index));
        return _ReportBucket(
          key: _dateOnly(bucketStart),
          label: bucketStart.day.toString().padLeft(2, '0'),
          start: bucketStart,
          end: bucketStart.add(const Duration(days: 1)),
        );
      },
    ),
    _ReportPeriod.year => List.generate(12, (index) {
      final bucketStart = DateTime(start.year, index + 1);
      return _ReportBucket(
        key:
            '${bucketStart.year}-${bucketStart.month.toString().padLeft(2, '0')}',
        label: const [
          'Ene',
          'Feb',
          'Mar',
          'Abr',
          'May',
          'Jun',
          'Jul',
          'Ago',
          'Sep',
          'Oct',
          'Nov',
          'Dic',
        ][index],
        start: bucketStart,
        end: DateTime(start.year, index + 2),
      );
    }),
  };
}

String _sqlDateTime(DateTime date) {
  return '${_dateOnly(date)} ${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}:'
      '${date.second.toString().padLeft(2, '0')}';
}

String _dateOnly(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

enum _ReportPeriod {
  day('day', "strftime('%H', datetime(b.created_at, 'localtime'))"),
  week('week', "date(datetime(b.created_at, 'localtime'))"),
  month('month', "date(datetime(b.created_at, 'localtime'))"),
  year('year', "strftime('%Y-%m', datetime(b.created_at, 'localtime'))");

  const _ReportPeriod(this.value, this.bucketExpression);

  final String value;
  final String bucketExpression;

  static _ReportPeriod? fromValue(String value) {
    for (final period in values) {
      if (period.value == value) return period;
    }
    return null;
  }
}

class _ReportRange {
  const _ReportRange(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;
}

class _ReportBucket {
  const _ReportBucket({
    required this.key,
    required this.label,
    required this.start,
    required this.end,
  });

  final String key;
  final String label;
  final DateTime start;
  final DateTime end;

  Map<String, dynamic> toJson() => {
    'label': label,
    'bucketStart': start.toIso8601String(),
    'bucketEnd': end.toIso8601String(),
    'billCount': 0,
    'totalAmount': 0.0,
  };
}
