class FlashSaleProduct {
  FlashSaleProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.images,
    required this.stock,
  });

  factory FlashSaleProduct.fromJson(Map<String, dynamic> json) {
    return FlashSaleProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      category: json['category'] as String? ?? '',
      images: (json['images'] as List?)?.cast<String>() ?? const [],
      stock: json['stock'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final String slug;
  final double price;
  final double? discountPrice;
  final String category;
  final List<String> images;
  final int stock;

  String get primaryImage => images.isNotEmpty ? images.first : '';
  bool get inStock => stock > 0;
  double get effectivePrice => discountPrice ?? price;

  int get discountPercent {
    if (discountPrice == null || price == 0) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }
}
