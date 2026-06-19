import 'package:flutter/material.dart';

import 'package:app/app.dart';
import 'package:app/core/local_api/local_api_server.dart';
import 'package:app/injection.dart';
import 'package:app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final LocalApiServer localApiServer;
  try {
    localApiServer = await LocalApiServer.startPersistent();
    if (localApiServer.baseUrl == null) {
      throw const LocalApiStartupException('API local sin URL base');
    }
  } catch (e) {
    runApp(LocalStartupErrorApp(message: e.toString()));
    return;
  }

  await initInjection(localApiServer: localApiServer);
  initRouter();
  runApp(const App());
}

class LocalStartupErrorApp extends StatelessWidget {
  const LocalStartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facturacion',
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo iniciar la API local',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
