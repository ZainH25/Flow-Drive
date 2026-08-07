import 'package:get/get.dart';

import '../../modules/auth/controller/auth_controller.dart';
import '../../modules/auth/service/cognito_auth_service.dart';
import '../../modules/dashboard/controller/dashboard_controller.dart';
import '../../modules/dashboard/controller/home_controller.dart';
import '../services/amplify_service.dart';
import '../services/local_storage_service.dart';
import '../utils/responsive.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ResponsiveController(), permanent: true);
    Get.put(CognitoAuthService(Get.find<AmplifyService>()), permanent: true);
    Get.put(
      AuthController(
        authService: Get.find<CognitoAuthService>(),
        storageService: Get.find<LocalStorageService>(),
        amplifyService: Get.find<AmplifyService>(),
      ),
      permanent: true,
    );
    Get.put(DashboardController(), permanent: true);
    Get.put(HomeController(), permanent: true);
  }
}
