import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:app/app.dart';
import 'package:app/core/constants/api_constants.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/injection.dart';
import 'package:app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await initInjection();
  if (ApiConstants.env == 'dev') {
    final ok = await checkBackendHealth(ApiConstants.baseUrl);
    if (kDebugMode) {
      // ignore: avoid_print
      print(ok ? 'Backend reachable at ${ApiConstants.baseUrl}' : 'Backend unreachable at ${ApiConstants.baseUrl}');
    }
  }
  initRouter();
  runApp(const App());
}
