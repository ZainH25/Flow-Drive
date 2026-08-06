import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/amplify_service.dart';
import 'core/services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storageService = await LocalStorageService.create();
  final amplifyService = AmplifyService();

  runApp(
    FlowDriveApp(
      storageService: storageService,
      amplifyService: amplifyService,
    ),
  );
}
