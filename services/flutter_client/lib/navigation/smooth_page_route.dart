import 'package:flutter/material.dart';

/// A very smooth page transition that avoids any directional slide or
/// scale "settling" effect. It uses a fast, gentle crossfade so the
/// change feels like content blending rather than a page shift.
class SmoothPageRoute extends PageRouteBuilder {
  SmoothPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) : super(
         settings: settings,
         fullscreenDialog: fullscreenDialog,
         pageBuilder: (context, animation, secondaryAnimation) => builder(context),
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 260),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Gentle fade + very subtle vertical drift so the eye perceives
           // smooth motion without feeling like a directional page slide.
           final fadeAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
             CurvedAnimation(parent: animation, curve: Curves.easeInOut),
           );

           final slideAnimation = Tween<Offset>(
             begin: const Offset(0.0, 0.015),
             end: Offset.zero,
           ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation);

           return FadeTransition(
             opacity: fadeAnimation,
             child: SlideTransition(position: slideAnimation, child: child),
           );
         },
       );

  /// Convenience factory for pushing a new screen.
  static Route<dynamic> push(BuildContext context, Widget screen) {
    return SmoothPageRoute(builder: (_) => screen);
  }

  /// Convenience factory for replacing the current screen.
  static Route<dynamic> replace(BuildContext context, Widget screen) {
    return SmoothPageRoute(
      builder: (_) => screen,
      settings: const RouteSettings(name: 'replace'),
    );
  }
}
