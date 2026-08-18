import '../models/product.dart';
import '../models/product_filter.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _apiClient;

  ProductService(this._apiClient);

  Future<List<Product>> getProducts() async {
    final response = await _apiClient.getListJson('/api/v1/products');
    return response
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<Product> getProductById(String productId) async {
    final response = await _apiClient.getJson('/api/v1/products/$productId');
    return Product.fromJson(response);
  }

  /// Search products with advanced filters
  Future<ProductSearchResult> searchProducts(ProductFilter filter) async {
    final queryParams = filter.toQueryParams();
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final path = queryString.isNotEmpty 
        ? '/api/v1/products/search?$queryString'
        : '/api/v1/products/search';
    
    final response = await _apiClient.getJson(path);
    return ProductSearchResult.fromJson(response);
  }

  /// Get all available brands for filtering
  Future<List<String>> getBrands() async {
    final response = await _apiClient.getListJson('/api/v1/brands');
    return response.whereType<String>().toList();
  }

  /// Get all available categories for filtering
  Future<List<String>> getCategories() async {
    final response = await _apiClient.getListJson('/api/v1/categories');
    return response.whereType<String>().toList();
  }

  /// Get the min/max price range for filter UI
  Future<PriceRange> getPriceRange() async {
    final response = await _apiClient.getJson('/api/v1/price-range');
    return PriceRange.fromJson(response);
  }
}
