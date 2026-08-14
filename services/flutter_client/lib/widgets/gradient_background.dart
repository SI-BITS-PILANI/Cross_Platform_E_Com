import 'package:flutter/material.dart';
import 'bezier_container.dart';

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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFfbb448), Color(0xFFf7892b)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.15,
            right: -MediaQuery.of(context).size.width * 0.4,
            child: const BezierContainer(),
          ),
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}
