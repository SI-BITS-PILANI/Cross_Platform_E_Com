import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import 'auth_provider.dart';

class ProductCatalogState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final String query;
  final String selectedCategory;

  ProductCatalogState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.selectedCategory = 'All',
  });

  ProductCatalogState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    String? query,
    String? selectedCategory,
  }) {
    return ProductCatalogState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  List<Product> get filteredProducts {
    final normalizedQuery = query.trim().toLowerCase();
    return products.where((product) {
      final matchesCategory = selectedCategory == 'All' ||
          product.category.toLowerCase() == selectedCategory.toLowerCase();

      if (!matchesCategory) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return product.name.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery) ||
          product.description.toLowerCase().contains(normalizedQuery) ||
          product.brand.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  List<String> get categories {
    final unique = <String>{
      for (final product in products) product.category,
    };
    final sorted = unique.toList()..sort();
    return ['All', ...sorted];
  }
}

class ProductCatalogNotifier extends StateNotifier<ProductCatalogState> {
  final ProductService _productService;

  ProductCatalogNotifier(this._productService) : super(ProductCatalogState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await _productService.getProducts();
      state = state.copyWith(
        products: products,
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

  void setQuery(String query) {
    state = state.copyWith(query: query, error: state.error);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category, error: state.error);
  }

  void clearError() {
    state = state.copyWith(error: null, query: state.query);
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
