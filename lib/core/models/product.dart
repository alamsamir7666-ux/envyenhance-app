/// A single product, matching the shape returned by `toProduct()` in
/// the backend's `src/routes/products.ts`.
class Product {
  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.discountPrice,
    required this.category,
    this.videoUrl,
    required this.stock,
    required this.description,
    this.ingredients,
    required this.keyBenefits,
    required this.mainIngredients,
    required this.bestFor,
    this.texture,
    required this.images,
    required this.averageRating,
    required this.reviewCount,
    this.homepageTag,
    required this.createdAt,
    required this.productStatus,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      category: json['category'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      stock: json['stock'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      ingredients: json['ingredients'] as String?,
      keyBenefits: (json['keyBenefits'] as List?)?.cast<String>() ?? const [],
      mainIngredients: (json['mainIngredients'] as List?)
              ?.map((e) => MainIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bestFor: (json['bestFor'] as List?)?.cast<String>() ?? const [],
      texture: json['texture'] as String?,
      images: (json['images'] as List?)?.cast<String>() ?? const [],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      homepageTag: json['homepageTag'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      productStatus: json['productStatus'] as String? ?? 'in_stock',
    );
  }

  final int id;
  final String name;
  final String slug;
  final double price;
  final double? discountPrice;
  final String category;
  final String? videoUrl;
  final int stock;
  final String description;
  final String? ingredients;
  final List<String> keyBenefits;
  final List<MainIngredient> mainIngredients;
  final List<String> bestFor;
  final String? texture;
  final List<String> images;
  final double averageRating;
  final int reviewCount;
  final String? homepageTag;
  final String createdAt;
  final String productStatus;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  bool get isOnSale => discountPrice != null && discountPrice! < price;

  double get effectivePrice => isOnSale ? discountPrice! : price;

  bool get inStock => stock > 0 && productStatus == 'in_stock';
}

class MainIngredient {
  MainIngredient({required this.name, required this.icon});

  factory MainIngredient.fromJson(Map<String, dynamic> json) {
    return MainIngredient(
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }

  final String name;
  final String icon;
}
