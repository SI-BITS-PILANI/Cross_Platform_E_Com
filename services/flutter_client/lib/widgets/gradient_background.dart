import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          _FloatingShape(
            color: Colors.white.withOpacity(0.08),
            size: 300,
            top: -50,
            left: -80,
          ),
          _FloatingShape(
            color: Colors.white.withOpacity(0.06),
            size: 200,
            top: MediaQuery.of(context).size.height * 0.3,
            right: -60,
          ),
          _FloatingShape(
            color: Colors.white.withOpacity(0.04),
            size: 400,
            bottom: -100,
            left: MediaQuery.of(context).size.width * 0.2,
          ),
          _FloatingShape(
            color: Colors.white.withOpacity(0.05),
            size: 150,
            top: MediaQuery.of(context).size.height * 0.6,
            left: -40,
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingShape extends StatelessWidget {
  final Color color;
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const _FloatingShape({
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
