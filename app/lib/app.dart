import 'package:flutter/material.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Facturación',
      theme: AppTheme.theme,
      routerConfig: appRouter,
    );
  }
}
