import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/product_filter.dart';
import '../services/product_service.dart';
import 'auth_provider.dart';

class ProductCatalogState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final ProductFilter filter;
  final int totalCount;
  
  // Filter metadata
  final List<String> availableBrands;
  final List<String> availableCategories;
  final PriceRange? priceRange;
  final bool isLoadingMetadata;

  ProductCatalogState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.filter = const ProductFilter(),
    this.totalCount = 0,
    this.availableBrands = const [],
    this.availableCategories = const [],
    this.priceRange,
    this.isLoadingMetadata = false,
  });

  ProductCatalogState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    ProductFilter? filter,
    int? totalCount,
    List<String>? availableBrands,
    List<String>? availableCategories,
    PriceRange? priceRange,
    bool? isLoadingMetadata,
  }) {
    return ProductCatalogState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
      totalCount: totalCount ?? this.totalCount,
      availableBrands: availableBrands ?? this.availableBrands,
      availableCategories: availableCategories ?? this.availableCategories,
      priceRange: priceRange ?? this.priceRange,
      isLoadingMetadata: isLoadingMetadata ?? this.isLoadingMetadata,
    );
  }

  // Legacy getters for backward compatibility
  String get query => filter.query ?? '';
  String get selectedCategory => filter.category ?? 'All';
  
  List<Product> get filteredProducts => products;

  List<String> get categories {
    final sorted = availableCategories.toList()..sort();
    return ['All', ...sorted];
  }
}

class ProductCatalogNotifier extends StateNotifier<ProductCatalogState> {
  final ProductService _productService;

  ProductCatalogNotifier(this._productService) : super(ProductCatalogState());

  void setQuery(String query) {
    final newFilter = state.filter.copyWith(
      query: query.isEmpty ? null : query,
      clearQuery: query.isEmpty,
    );
    state = state.copyWith(filter: newFilter, error: state.error);
    _debounceSearch();
  }

  void setCategory(String category) {
    final newFilter = state.filter.copyWith(
      category: category == 'All' ? null : category,
    );
    state = state.copyWith(filter: newFilter, error: state.error);
    loadProducts();
  }

  void setFilter(ProductFilter filter) {
    state = state.copyWith(filter: filter, error: state.error);
    loadProducts();
  }

  void clearAllFilters() {
    state = state.copyWith(filter: ProductFilter.empty, error: state.error);
    loadProducts();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  DateTime? _lastSearchTime;
  void _debounceSearch() {
    _lastSearchTime = DateTime.now();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastSearchTime != null &&
          DateTime.now().difference(_lastSearchTime!).inMilliseconds >= 300) {
        loadProducts();
      }
    });
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _productService.searchProducts(state.filter);
      final products = result.products
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();
      
      state = state.copyWith(
        products: products,
        totalCount: result.total,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load products. Please try again.',
      );
    }
  }

  Future<void> loadFilterMetadata() async {
    if (state.availableBrands.isNotEmpty) return;
    
    state = state.copyWith(isLoadingMetadata: true);
    try {
      final results = await Future.wait([
        _productService.getBrands(),
        _productService.getCategories(),
        _productService.getPriceRange(),
      ]);
      
      state = state.copyWith(
        availableBrands: results[0] as List<String>,
        availableCategories: results[1] as List<String>,
        priceRange: results[2] as PriceRange,
        isLoadingMetadata: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMetadata: false);
    }
  }
}

final productServiceProvider = Provider<ProductService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductService(apiClient);
});

final productCatalogProvider =
    StateNotifierProvider<ProductCatalogNotifier, ProductCatalogState>((ref) {
  final productService = ref.watch(productServiceProvider);
  return ProductCatalogNotifier(productService);
});
