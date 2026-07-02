/// Matches the `buildCart()` response shape from `src/routes/cart.ts`.
class Cart {
  Cart({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List? ?? [])
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double total;

  static Cart empty() => Cart(items: [], subtotal: 0, discount: 0, total: 0);

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  bool get isEmpty => items.isEmpty;
}

class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      productId: json['productId'] as int,
      quantity: json['quantity'] as int,
      product: CartProduct.fromJson(json['product'] as Map<String, dynamic>),
    );
  }

  final int id;
  final int productId;
  final int quantity;
  final CartProduct product;

  double get lineTotal => product.effectivePrice * quantity;
}

/// Slimmer product shape as embedded in cart responses (no ratings, etc.)
class CartProduct {
  CartProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.stock,
    required this.images,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      category: json['category'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      images: (json['images'] as List?)?.cast<String>() ?? const [],
    );
  }

  final int id;
  final String name;
  final String slug;
  final double price;
  final double? discountPrice;
  final String category;
  final int stock;
  final List<String> images;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  double get effectivePrice => discountPrice ?? price;
}
