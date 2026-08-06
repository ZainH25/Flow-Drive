import 'package:get/get.dart';

import '../../modules/auth/controller/auth_controller.dart';
import '../../modules/auth/controller/auth_form_controller.dart';
import '../services/local_storage_service.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuthFormController(
        Get.find<AuthController>(),
        Get.find<LocalStorageService>(),
      ),
    );
  }
}
