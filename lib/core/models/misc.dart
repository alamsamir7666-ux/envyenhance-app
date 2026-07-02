/// Matches `toCategory()` in `src/routes/categories.ts`.
class Category {
  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.image,
    required this.displayOrder,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
      image: json['image'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      parentId: json['parentId'] as int?,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? image;
  final int displayOrder;
  final int? parentId;
}

/// Matches `formatAddress()` in `src/routes/users.ts`.
class Address {
  Address({
    this.id,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    this.district,
    this.postalCode,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int?,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String?,
      postalCode: json['postalCode'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  final int? id;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String? district;
  final String? postalCode;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'street': street,
        'city': city,
        if (district != null) 'district': district,
        if (postalCode != null) 'postalCode': postalCode,
        'isDefault': isDefault,
      };
}

/// Matches `formatUser()` in `src/routes/users.ts`.
class AppUser {
  AppUser({
    required this.id,
    required this.clerkId,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    required this.role,
    required this.isBlocked,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      clerkId: json['clerkId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      isBlocked: json['isBlocked'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final int id;
  final String clerkId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String role;
  final bool isBlocked;
  final String createdAt;

  String get displayName {
    final name = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return name.isNotEmpty ? name : email;
  }

  bool get isAdmin => role == 'admin';
}
