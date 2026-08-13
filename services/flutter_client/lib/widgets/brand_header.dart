import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLogo(),
        const SizedBox(height: 24),
        _buildTagline(),
        const SizedBox(height: 48),
        _buildIllustration(),
      ],
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.shopping_bag_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'ShopEase',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'Your marketplace,\nreimagined.',
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.15,
        letterSpacing: -1,
      ),
    );
  }

  Widget _buildIllustration() {
    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      child: Transform.rotate(
        angle: 0.05,
        child: SvgPicture.asset(
          'assets/illustrations/brand_illustration.svg',
          width: 320,
          height: 320,
        ),
      ),
    );
  }
}
