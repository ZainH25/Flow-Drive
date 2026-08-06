import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/services/amplify_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/controller/auth_controller.dart';
import 'modules/auth/service/cognito_auth_service.dart';
import 'modules/dashboard/controller/dashboard_controller.dart';

class FlowDriveApp extends StatelessWidget {
  const FlowDriveApp({
    super.key,
    required this.storageService,
    required this.amplifyService,
  });

  final LocalStorageService storageService;
  final AmplifyService amplifyService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: storageService),
        Provider.value(value: amplifyService),
        Provider(
          create: (context) => CognitoAuthService(amplifyService),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthController(
            authService: context.read<CognitoAuthService>(),
            storageService: storageService,
            amplifyService: amplifyService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => DashboardController()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
