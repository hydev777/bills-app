import 'package:app/core/widgets/error_with_retry.dart';
import 'package:app/features/bills/domain/entities/bill_entity.dart';
import 'package:app/features/reports/domain/entities/bill_report_entity.dart';
import 'package:app/features/reports/domain/entities/bill_report_period.dart';
import 'package:app/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:app/features/reports/presentation/bloc/reports_event.dart';
import 'package:app/features/reports/presentation/bloc/reports_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  BillReportPeriod _period = BillReportPeriod.day;
  late DateTime _anchorDate;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchorDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
    _loadReport();
  }

  void _loadReport() {
    context.read<ReportsBloc>().add(
      ReportsLoaded(period: _period, anchorDate: _anchorDate),
    );
  }

  void _setPeriod(BillReportPeriod period) {
    setState(() => _period = period);
    _loadReport();
  }

  void _movePeriod(int direction) {
    setState(() {
      _anchorDate = direction < 0
          ? _period.previousAnchor(_anchorDate)
          : _period.nextAnchor(_anchorDate);
    });
    _loadReport();
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() => _anchorDate = DateTime(now.year, now.month, now.day));
    _loadReport();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(
      () => _anchorDate = DateTime(picked.year, picked.month, picked.day),
    );
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          final report = state is ReportsLoadedState ? state.report : null;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: _ReportsToolbar(
                    period: _period,
                    anchorDate: _anchorDate,
                    rangeLabel: report == null
                        ? _dateText(_anchorDate)
                        : _rangeLabel(report),
                    onPeriodChanged: _setPeriod,
                    onPrevious: () => _movePeriod(-1),
                    onNext: () => _movePeriod(1),
                    onPickDate: _pickDate,
                    onToday: _goToday,
                  ),
                ),
              ),
              if (state is ReportsLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is ReportsError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorWithRetry(
                    message: state.message,
                    onRetry: _loadReport,
                  ),
                )
              else if (report != null)
                ..._reportSlivers(report)
              else
                const SliverFillRemaining(child: SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _reportSlivers(BillReportEntity report) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        sliver: SliverToBoxAdapter(child: _KpiGrid(report: report)),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        sliver: SliverToBoxAdapter(child: _ReportChart(report: report)),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        sliver: _RecentBillsSliver(report: report),
      ),
    ];
  }

  String _rangeLabel(BillReportEntity report) {
    return switch (report.period) {
      BillReportPeriod.day => _dateText(report.startDate),
      BillReportPeriod.week =>
        '${_shortDateText(report.startDate)} - ${_shortDateText(report.endDateExclusive.subtract(const Duration(days: 1)))}',
      BillReportPeriod.month =>
        '${report.startDate.month.toString().padLeft(2, '0')}/${report.startDate.year}',
      BillReportPeriod.year => report.startDate.year.toString(),
    };
  }
}

class _ReportsToolbar extends StatelessWidget {
  const _ReportsToolbar({
    required this.period,
    required this.anchorDate,
    required this.rangeLabel,
    required this.onPeriodChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
    required this.onToday,
  });

  final BillReportPeriod period;
  final DateTime anchorDate;
  final String rangeLabel;
  final ValueChanged<BillReportPeriod> onPeriodChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facturas registradas',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<BillReportPeriod>(
              segments: BillReportPeriod.values
                  .map(
                    (item) => ButtonSegment<BillReportPeriod>(
                      value: item,
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
              selected: {period},
              onSelectionChanged: (selected) => onPeriodChanged(selected.first),
            ),
            _PeriodNavigator(
              rangeLabel: rangeLabel,
              onPrevious: onPrevious,
              onNext: onNext,
              onPickDate: onPickDate,
            ),
            TextButton.icon(
              onPressed: onToday,
              icon: const Icon(Icons.today_rounded),
              label: const Text('Hoy'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.rangeLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  final String rangeLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Periodo anterior',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: onPrevious,
            ),
            TextButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(rangeLabel),
            ),
            IconButton(
              tooltip: 'Periodo siguiente',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.report});

  final BillReportEntity report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final tileWidth = wide
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiTile(
              width: tileWidth,
              icon: Icons.payments_rounded,
              label: 'Total facturado',
              value: _money(report.totalAmount),
            ),
            _KpiTile(
              width: tileWidth,
              icon: Icons.receipt_long_rounded,
              label: 'Facturas registradas',
              value: report.billCount.toString(),
            ),
            _KpiTile(
              width: tileWidth,
              icon: Icons.analytics_rounded,
              label: 'Promedio por factura',
              value: _money(report.averageAmount),
            ),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: width,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportChart extends StatelessWidget {
  const _ReportChart({required this.report});

  final BillReportEntity report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEmpty = report.billCount == 0;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tendencia del periodo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: isEmpty
                  ? const Center(child: Text('No hay facturas en este periodo'))
                  : SfCartesianChart(
                      tooltipBehavior: TooltipBehavior(enable: true),
                      trackballBehavior: TrackballBehavior(enable: true),
                      primaryXAxis: CategoryAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Total'),
                      ),
                      axes: <ChartAxis>[
                        NumericAxis(
                          name: 'countAxis',
                          opposedPosition: true,
                          title: AxisTitle(text: 'Facturas'),
                        ),
                      ],
                      series: <CartesianSeries<BillReportBucketEntity, String>>[
                        ColumnSeries<BillReportBucketEntity, String>(
                          name: 'Total facturado',
                          dataSource: report.series,
                          color: colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          xValueMapper: (bucket, _) => bucket.label,
                          yValueMapper: (bucket, _) => bucket.totalAmount,
                        ),
                        LineSeries<BillReportBucketEntity, String>(
                          name: 'Facturas registradas',
                          dataSource: report.series,
                          yAxisName: 'countAxis',
                          color: colorScheme.tertiary,
                          markerSettings: const MarkerSettings(isVisible: true),
                          xValueMapper: (bucket, _) => bucket.label,
                          yValueMapper: (bucket, _) => bucket.billCount,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentBillsSliver extends StatelessWidget {
  const _RecentBillsSliver({required this.report});

  final BillReportEntity report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (report.recentBills.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No hay facturas en este periodo',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecentBillsHeader(report: report),
            );
          }
          if (report.hasMoreBills && index == report.recentBills.length + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'El grafico incluye todas las facturas; la lista muestra las ${report.recentBillsLimit} mas recientes.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecentBillTile(bill: report.recentBills[index - 1]),
          );
        },
        childCount:
            report.recentBills.length + 1 + (report.hasMoreBills ? 1 : 0),
      ),
    );
  }
}

class _RecentBillsHeader extends StatelessWidget {
  const _RecentBillsHeader({required this.report});

  final BillReportEntity report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facturas del periodo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${report.recentBills.length} mostradas',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RecentBillTile extends StatelessWidget {
  const _RecentBillTile({required this.bill});

  final BillEntity bill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final client = bill.clientName?.trim();
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${bill.id} - ${bill.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      _dateText(bill.createdAt),
                      'Estado: ${bill.status}',
                      if (client != null && client.isNotEmpty) client,
                    ].join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _money(bill.amount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double value) => 'RD\$ ${value.toStringAsFixed(2)}';

String _dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _shortDateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}
