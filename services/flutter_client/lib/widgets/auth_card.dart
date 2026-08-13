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
    final cardWidth = width ?? (screenWidth < 600 ? screenWidth * 0.9 : 420);

    return Container(
      width: cardWidth,
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
