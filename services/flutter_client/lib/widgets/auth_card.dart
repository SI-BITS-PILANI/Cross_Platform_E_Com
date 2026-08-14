import 'package:flutter/material.dart';

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
    final cardWidth = width ?? (screenWidth < 600 ? screenWidth * 0.92 : 440);

    return Container(
      width: cardWidth,
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}
