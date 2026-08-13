import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;

  const AuthCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    final cardWidth = width ??
        (isDesktop
            ? 460.0
            : isTablet
                ? 480.0
                : screenWidth * 0.92);

    final verticalPadding = isDesktop ? 48.0 : isTablet ? 44.0 : 40.0;
    final horizontalPadding = isDesktop ? 48.0 : isTablet ? 44.0 : 32.0;
    final borderRadius = isDesktop ? 32.0 : isTablet ? 28.0 : 24.0;
    final shadowBlur = isDesktop ? 50.0 : isTablet ? 40.0 : 30.0;

    return Container(
      width: cardWidth,
      padding: padding ??
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: shadowBlur,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: shadowBlur + 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
