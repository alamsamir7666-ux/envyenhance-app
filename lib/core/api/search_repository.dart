import 'api_client.dart';

class SearchResult {
  SearchResult({
    required this.products,
    required this.categories,
  });

  final List<SearchProduct> products;
  final List<SearchCategory> categories;
}

class SearchProduct {
  SearchProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.price,
    this.discountPrice,
    this.image,
    required this.averageRating,
  });

  factory SearchProduct.fromJson(Map<String, dynamic> json) {
    return SearchProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      image: json['image'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String category;
  final double price;
  final double? discountPrice;
  final String? image;
  final double averageRating;

  double get effectivePrice => discountPrice ?? price;
}

class SearchCategory {
  SearchCategory({required this.name, required this.slug});

  factory SearchCategory.fromJson(Map<String, dynamic> json) {
    return SearchCategory(
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  final String name;
  final String slug;
}

class SearchRepository {
  SearchRepository(this._client);
  final ApiClient _client;

  Future<SearchResult> autocomplete(String query) async {
    if (query.trim().length < 2) {
      return SearchResult(products: [], categories: []);
    }
    final res = await _client.get<Map<String, dynamic>>(
      '/search/autocomplete',
      queryParameters: {'q': query.trim()},
    );
    final data = res.data ?? {};
    return SearchResult(
      products: (data['products'] as List? ?? [])
          .map((e) => SearchProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (data['categories'] as List? ?? [])
          .map((e) => SearchCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
