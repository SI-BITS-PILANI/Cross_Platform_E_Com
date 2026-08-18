/// Model representing product filter/search criteria
class ProductFilter {
  final String? query;
  final String? category;
  final List<String> brands;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool inStockOnly;
  final bool hasDiscountOnly;
  final SortOption sortBy;
  final SortOrder sortOrder;

  const ProductFilter({
    this.query,
    this.category,
    this.brands = const [],
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.inStockOnly = false,
    this.hasDiscountOnly = false,
    this.sortBy = SortOption.name,
    this.sortOrder = SortOrder.asc,
  });

  ProductFilter copyWith({
    String? query,
    String? category,
    List<String>? brands,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStockOnly,
    bool? hasDiscountOnly,
    SortOption? sortBy,
    SortOrder? sortOrder,
    bool clearQuery = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
  }) {
    return ProductFilter(
      query: clearQuery ? null : (query ?? this.query),
      category: category ?? this.category,
      brands: brands ?? this.brands,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      hasDiscountOnly: hasDiscountOnly ?? this.hasDiscountOnly,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Convert filter to query parameters for API call
  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (query != null && query!.isNotEmpty) {
      params['q'] = query!;
    }
    if (category != null && category!.isNotEmpty && category != 'All') {
      params['category'] = category!;
    }
    if (brands.isNotEmpty) {
      params['brand'] = brands.join(',');
    }
    if (minPrice != null) {
      params['min_price'] = minPrice!.toString();
    }
    if (maxPrice != null) {
      params['max_price'] = maxPrice!.toString();
    }
    if (minRating != null) {
      params['min_rating'] = minRating!.toString();
    }
    if (inStockOnly) {
      params['in_stock'] = 'true';
    }
    if (hasDiscountOnly) {
      params['has_discount'] = 'true';
    }
    params['sort_by'] = sortBy.value;
    params['sort_order'] = sortOrder.value;

    return params;
  }

  /// Check if any filters are active (excluding default sort)
  bool get hasActiveFilters {
    return (query != null && query!.isNotEmpty) ||
        (category != null && category!.isNotEmpty && category != 'All') ||
        brands.isNotEmpty ||
        minPrice != null ||
        maxPrice != null ||
        minRating != null ||
        inStockOnly ||
        hasDiscountOnly;
  }

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (category != null && category!.isNotEmpty && category != 'All') count++;
    if (brands.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (inStockOnly) count++;
    if (hasDiscountOnly) count++;
    return count;
  }

  /// Reset all filters to default
  static const ProductFilter empty = ProductFilter();
}

enum SortOption {
  name('name', 'Name'),
  price('price', 'Price'),
  rating('rating', 'Rating'),
  discount('discount', 'Discount');

  final String value;
  final String label;
  const SortOption(this.value, this.label);
}

enum SortOrder {
  asc('asc', 'Low to High'),
  desc('desc', 'High to Low');

  final String value;
  final String label;
  const SortOrder(this.value, this.label);
}

/// Response from search API with pagination info
class ProductSearchResult {
  final List<dynamic> products;
  final int total;
  final int limit;
  final int offset;

  ProductSearchResult({
    required this.products,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    return ProductSearchResult(
      products: json['products'] as List<dynamic>,
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }
}

/// Price range for the filter UI
class PriceRange {
  final double minPrice;
  final double maxPrice;

  PriceRange({required this.minPrice, required this.maxPrice});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      minPrice: (json['min_price'] as num).toDouble(),
      maxPrice: (json['max_price'] as num).toDouble(),
    );
  }
}
