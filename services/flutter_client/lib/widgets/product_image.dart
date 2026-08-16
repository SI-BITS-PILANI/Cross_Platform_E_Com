import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  bool get _isAssetImage => imageUrl.startsWith('asset:');

  String get _assetPath => 'assets/${imageUrl.substring('asset:'.length)}';

  bool get _isSvgAsset => _assetPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isAssetImage) {
      if (_isSvgAsset) {
        return SvgPicture.asset(
          _assetPath,
          fit: fit,
          placeholderBuilder: (context) => _fallback(),
        );
      }

      return Image.asset(
        _assetPath,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (imageUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        imageUrl,
        fit: fit,
        placeholderBuilder: (context) => _fallback(),
      );
    }

    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFE8EBF2),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 42),
      ),
    );
  }
}
