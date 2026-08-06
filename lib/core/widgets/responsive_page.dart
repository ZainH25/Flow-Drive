import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';

/// Consistent page shell: SafeArea, padding, and max-width across all devices.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
    this.centerBody = false,
    this.maxWidth,
    this.padding,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool centerBody;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: centerBody ? Alignment.center : Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.contentMaxWidth,
        ),
        child: Padding(
          padding: padding ?? Responsive.pagePadding,
          child: body,
        ),
      ),
    );

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor ?? AppColors.background,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: content),
    );
  }
}

/// Full-screen background with centered responsive child (login, splash content).
class ResponsiveCenteredScroll extends StatelessWidget {
  const ResponsiveCenteredScroll({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding ?? Responsive.pagePadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: SizedBox(
                width: maxWidth ?? Responsive.authCardWidth,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
