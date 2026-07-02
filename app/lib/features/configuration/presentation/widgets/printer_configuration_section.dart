import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/configuration/domain/entities/printer_connection_status.dart';
import 'package:app/features/configuration/domain/entities/printer_device_entity.dart';
import 'package:app/features/configuration/presentation/bloc/printer_configuration_cubit.dart';
import 'package:app/features/configuration/presentation/bloc/printer_configuration_state.dart';

class PrinterConfigurationSection extends StatelessWidget {
  const PrinterConfigurationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrinterConfigurationCubit, PrinterConfigurationState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _PrinterStatusHeader(state: state),
            const SizedBox(height: 16),
            _PrinterActions(state: state),
            const SizedBox(height: 16),
            _PrinterList(state: state),
          ],
        );
      },
    );
  }
}

class _PrinterStatusHeader extends StatelessWidget {
  const _PrinterStatusHeader({required this.state});

  final PrinterConfigurationState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedName = state.savedConfiguration?.printerName;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _statusIcon(state.status),
            color: _statusColor(theme, state.status),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(state.status),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  savedName == null
                      ? 'No hay impresora guardada'
                      : 'Impresora guardada: $savedName',
                  style: theme.textTheme.bodyMedium,
                ),
                if (state.message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (state.isBusy)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  IconData _statusIcon(PrinterConnectionStatus status) {
    return switch (status) {
      PrinterConnectionStatus.connected => Icons.check_circle_outline,
      PrinterConnectionStatus.detected => Icons.print_outlined,
      PrinterConnectionStatus.disconnected => Icons.link_off_outlined,
      PrinterConnectionStatus.notDetected => Icons.search_off_outlined,
      PrinterConnectionStatus.error => Icons.error_outline,
      PrinterConnectionStatus.scanning => Icons.manage_search_outlined,
      PrinterConnectionStatus.initial => Icons.print_outlined,
    };
  }

  Color _statusColor(ThemeData theme, PrinterConnectionStatus status) {
    return switch (status) {
      PrinterConnectionStatus.connected => Colors.green.shade700,
      PrinterConnectionStatus.error => theme.colorScheme.error,
      PrinterConnectionStatus.disconnected => Colors.orange.shade700,
      PrinterConnectionStatus.notDetected => theme.colorScheme.outline,
      _ => theme.colorScheme.primary,
    };
  }

  String _statusLabel(PrinterConnectionStatus status) {
    return switch (status) {
      PrinterConnectionStatus.connected => 'Conectada',
      PrinterConnectionStatus.detected => 'Detectada',
      PrinterConnectionStatus.disconnected => 'No conectada',
      PrinterConnectionStatus.notDetected => 'No detectada',
      PrinterConnectionStatus.error => 'Error',
      PrinterConnectionStatus.scanning => 'Buscando impresoras',
      PrinterConnectionStatus.initial => 'Impresora',
    };
  }
}

class _PrinterActions extends StatelessWidget {
  const _PrinterActions({required this.state});

  final PrinterConfigurationState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrinterConfigurationCubit>();
    final canSave = state.selectedPrinter != null &&
        state.selectedPrinter?.name != state.savedConfiguration?.printerName;
    final canDisconnect = state.status == PrinterConnectionStatus.connected ||
        state.status == PrinterConnectionStatus.disconnected;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        IconButton.filledTonal(
          onPressed: state.isBusy ? null : cubit.refresh,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: canSave ? cubit.saveSelectedPrinter : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar impresora'),
        ),
        OutlinedButton.icon(
          onPressed: canDisconnect ? cubit.disconnect : null,
          icon: const Icon(Icons.link_off_outlined),
          label: const Text('Desconectar'),
        ),
        TextButton.icon(
          onPressed: state.savedConfiguration == null
              ? null
              : cubit.clearConfiguration,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Eliminar configuracion'),
        ),
      ],
    );
  }
}

class _PrinterList extends StatelessWidget {
  const _PrinterList({required this.state});

  final PrinterConfigurationState state;

  @override
  Widget build(BuildContext context) {
    if (state.printers.isEmpty) {
      return const _EmptyPrinterList();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.printers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final printer = state.printers[index];
        return _PrinterTile(
          printer: printer,
          selected: state.selectedPrinter?.name == printer.name,
          saved: state.savedConfiguration?.printerName == printer.name,
        );
      },
    );
  }
}

class _PrinterTile extends StatelessWidget {
  const _PrinterTile({
    required this.printer,
    required this.selected,
    required this.saved,
  });

  final PrinterDeviceEntity printer;
  final bool selected;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          saved ? Icons.bookmark_added_outlined : Icons.print_outlined,
        ),
        title: Text(printer.name),
        subtitle: Text(saved ? 'Guardada' : 'USB'),
        trailing: selected ? const Icon(Icons.check_circle_outline) : null,
        onTap: () =>
            context.read<PrinterConfigurationCubit>().selectPrinter(printer),
      ),
    );
  }
}

class _EmptyPrinterList extends StatelessWidget {
  const _EmptyPrinterList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Conecta una impresora termica USB y pulsa actualizar.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
