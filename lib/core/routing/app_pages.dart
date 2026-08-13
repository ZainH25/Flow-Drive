import 'package:get/get.dart';

import '../../modules/auth/view/login_view.dart';
import '../../modules/dashboard/view/dashboard_view.dart';
import '../../modules/gesture_shapes/binding/gesture_shapes_binding.dart';
import '../../modules/gesture_shapes/view/gesture_shapes_view.dart';
import '../../modules/file_map/binding/file_map_binding.dart';
import '../../modules/file_map/view/file_map_view.dart';
import '../../modules/onboarding/view/onboarding_view.dart';
import '../../modules/splash/view/splash_view.dart';
import '../../modules/transfer/binding/transfer_binding.dart';
import '../../modules/transfer/view/device_radar_view.dart';
import '../../modules/transfer/view/send_files_view.dart';
import '../../modules/transfer/view/transfer_complete_view.dart';
import '../bindings/login_binding.dart';
import '../theme/color_theme_page.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingView()),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardView()),
    GetPage(
      name: AppRoutes.fileMap,
      page: () => const FileMapView(),
      binding: FileMapBinding(),
    ),
    GetPage(
      name: AppRoutes.gestureShapes,
      page: () => const GestureShapesView(),
      binding: GestureShapesBinding(),
    ),
    GetPage(name: AppRoutes.colorTheme, page: () => const ColorThemePage()),
    GetPage(
      name: AppRoutes.sendFiles,
      page: () => const SendFilesView(),
      binding: SendBinding(),
    ),
    GetPage(
      name: AppRoutes.deviceRadar,
      page: () => const DeviceRadarView(),
      binding: DeviceRadarBinding(),
    ),
    GetPage(
      name: AppRoutes.transferComplete,
      page: () => const TransferCompleteView(),
      binding: TransferCompleteBinding(),
    ),
  ];
}
