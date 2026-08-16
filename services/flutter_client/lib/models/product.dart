class Product {
  final String productId;
  final String name;
  final String description;
  final double price;
  final double finalPrice;
  final int stock;
  final String category;
  final String brand;
  final double rating;
  final int reviewsCount;
  final int discountPercent;
  final String imageUrl;
  final bool available;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.finalPrice,
    required this.stock,
    required this.category,
    required this.brand,
    required this.rating,
    required this.reviewsCount,
    required this.discountPercent,
    required this.imageUrl,
    required this.available,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num).toDouble(),
      finalPrice: ((json['final_price'] ?? json['price']) as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      category: (json['category'] as String?) ?? 'general',
      brand: (json['brand'] as String?) ?? 'ShopEase',
      rating: ((json['rating'] ?? 4.3) as num).toDouble(),
      reviewsCount: ((json['reviews_count'] ?? 0) as num).toInt(),
      discountPercent: ((json['discount_percent'] ?? 0) as num).toInt(),
      imageUrl: (json['image_url'] as String?) ?? '',
      available: (json['available'] as bool?) ?? false,
    );
  }
}
