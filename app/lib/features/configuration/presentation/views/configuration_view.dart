import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/features/configuration/presentation/bloc/printer_configuration_cubit.dart';
import 'package:app/features/configuration/presentation/bloc/receipt_configuration_cubit.dart';
import 'package:app/features/configuration/presentation/widgets/printer_configuration_section.dart';
import 'package:app/features/configuration/presentation/widgets/receipt_configuration_section.dart';
import 'package:app/injection.dart';

class ConfigurationView extends StatelessWidget {
  const ConfigurationView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PrinterConfigurationCubit>(
          create: (_) => sl<PrinterConfigurationCubit>()..load(),
        ),
        BlocProvider<ReceiptConfigurationCubit>(
          create: (_) => sl<ReceiptConfigurationCubit>()..load(),
        ),
      ],
      child: const DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: _ConfigurationAppBar(),
          body: TabBarView(
            children: [
              PrinterConfigurationSection(),
              ReceiptConfigurationSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigurationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ConfigurationAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Configuracion'),
      bottom: const TabBar(
        tabs: [
          Tab(icon: Icon(Icons.print_outlined), text: 'Impresora'),
          Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Recibo'),
        ],
      ),
    );
  }
}

