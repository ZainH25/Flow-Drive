import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../auth/controller/auth_controller.dart';

class SplashController {
  SplashController(this._authController);

  final AuthController _authController;

  Future<void> initializeApp() async {
    await _authController.initialize();
    await Future<void>.delayed(AppConstants.splashDuration);
  }

  String resolveNextRoute() {
    if (_authController.isAuthenticated) {
      return AppRoutes.dashboard;
    }
    return AppRoutes.login;
  }
}
