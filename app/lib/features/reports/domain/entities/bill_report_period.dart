enum BillReportPeriod {
  day('day', 'Dia'),
  week('week', 'Semana'),
  month('month', 'Mes'),
  year('year', 'Ano');

  const BillReportPeriod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  DateTime previousAnchor(DateTime anchor) {
    final date = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (this) {
      BillReportPeriod.day => date.subtract(const Duration(days: 1)),
      BillReportPeriod.week => date.subtract(const Duration(days: 7)),
      BillReportPeriod.month => _shiftMonth(date, -1),
      BillReportPeriod.year => _shiftYear(date, -1),
    };
  }

  DateTime nextAnchor(DateTime anchor) {
    final date = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (this) {
      BillReportPeriod.day => date.add(const Duration(days: 1)),
      BillReportPeriod.week => date.add(const Duration(days: 7)),
      BillReportPeriod.month => _shiftMonth(date, 1),
      BillReportPeriod.year => _shiftYear(date, 1),
    };
  }

  static BillReportPeriod fromApiValue(String value) {
    for (final period in values) {
      if (period.apiValue == value) return period;
    }
    return BillReportPeriod.day;
  }
}

DateTime _shiftMonth(DateTime date, int delta) {
  final targetMonth = date.month + delta;
  final target = DateTime(date.year, targetMonth);
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(target.year, target.month, day);
}

DateTime _shiftYear(DateTime date, int delta) {
  final targetYear = date.year + delta;
  final lastDay = DateTime(targetYear, date.month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(targetYear, date.month, day);
}
