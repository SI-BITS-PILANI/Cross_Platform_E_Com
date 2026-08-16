import '../models/product.dart';
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
}
