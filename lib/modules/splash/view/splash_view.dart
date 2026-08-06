import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/floating_files_background.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/splash_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Animation<double> _progress;
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashController(Get.find<AuthController>());

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _controller.initializeApp();
    if (!mounted) return;

    final auth = Get.find<AuthController>();
    if (auth.isAuthenticated) {
      await auth.onLoginSuccess();
    }
    Get.offAllNamed(_controller.resolveNextRoute());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.splashGradient),
          ),
          const FloatingFilesBackground(opacity: 0.55),
          FadeTransition(
            opacity: _fade,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth),
                child: Padding(
                  padding: Responsive.pagePadding,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 148,
                      height: 148,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.authCardShadow,
                            blurRadius: 40,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AssetPaths.logo,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.hub_rounded,
                          size: 56,
                          color: AppColors.brandIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                        children: [
                          const TextSpan(text: 'Welcome to\n'),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.brandGradient.createShader(bounds),
                              child: Text(
                                AppConstants.appName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppConstants.splashTagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, child) {
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 5,
                                backgroundColor:
                                    AppColors.brandIndigo.withValues(alpha: 0.12),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.brandIndigo,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'SYNCING WORKSPACE...',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
