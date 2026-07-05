class ProductVariant {
  ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.variantType,
    required this.price,
    this.discountPrice,
    required this.stock,
    this.sku,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      productId: json['productId'] as int,
      name: json['name'] as String,
      variantType: json['variantType'] as String,
      price: (json['price'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      stock: json['stock'] as int? ?? 0,
      sku: json['sku'] as String?,
    );
  }

  final int id;
  final int productId;
  final String name;
  final String variantType;
  final double price;
  final double? discountPrice;
  final int stock;
  final String? sku;

  double get effectivePrice => discountPrice ?? price;
  bool get inStock => stock > 0;
}
