import '../models/product.dart';
import 'api_client.dart';

class ProductsRepository {
  ProductsRepository(this._client);
  final ApiClient _client;

  Future<ProductPage> listProducts({
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? homepageTag,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _client.get<Map<String, dynamic>>('/products', query: {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minRating != null) 'minRating': minRating,
      if (homepageTag != null) 'homepageTag': homepageTag,
      'page': page,
      'limit': limit,
    });
    final data = res.data ?? {};
    return ProductPage(
      products: ((data['products'] as List?) ?? [])
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? 1,
      totalPages: data['totalPages'] as int? ?? 1,
    );
  }

  Future<List<Product>> featured() async {
    final res = await _client.get<List<dynamic>>('/products/featured');
    return (res.data ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the homepage sections: `trending` products and `new arrivals`,
  /// matching the `{ top, bottom }` shape from `/products/homepage`.
  Future<HomepageSections> homepage() async {
    final res = await _client.get<Map<String, dynamic>>('/products/homepage');
    final data = res.data ?? {};
    return HomepageSections(
      trending: ((data['top'] as List?) ?? [])
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      newArrivals: ((data['bottom'] as List?) ?? [])
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Product> getById(int id) async {
    final res = await _client.get<Map<String, dynamic>>('/products/$id');
    return Product.fromJson(res.data!);
  }
}

class HomepageSections {
  HomepageSections({required this.trending, required this.newArrivals});
  final List<Product> trending;
  final List<Product> newArrivals;
}

class ProductPage {
  ProductPage({
    required this.products,
    required this.total,
    required this.page,
    required this.totalPages,
  });
  final List<Product> products;
  final int total;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
