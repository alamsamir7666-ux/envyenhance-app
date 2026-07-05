class EmailPreferences {
  EmailPreferences({
    required this.orderUpdates,
    required this.promotions,
    required this.restockAlerts,
    required this.newsletter,
    required this.abandonedCart,
    required this.loyaltyUpdates,
  });

  factory EmailPreferences.fromJson(Map<String, dynamic> json) {
    return EmailPreferences(
      orderUpdates: json['orderUpdates'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? true,
      restockAlerts: json['restockAlerts'] as bool? ?? true,
      newsletter: json['newsletter'] as bool? ?? true,
      abandonedCart: json['abandonedCart'] as bool? ?? true,
      loyaltyUpdates: json['loyaltyUpdates'] as bool? ?? true,
    );
  }

  final bool orderUpdates;
  final bool promotions;
  final bool restockAlerts;
  final bool newsletter;
  final bool abandonedCart;
  final bool loyaltyUpdates;

  Map<String, dynamic> toJson() => {
    'orderUpdates': orderUpdates,
    'promotions': promotions,
    'restockAlerts': restockAlerts,
    'newsletter': newsletter,
    'abandonedCart': abandonedCart,
    'loyaltyUpdates': loyaltyUpdates,
  };

  EmailPreferences copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? restockAlerts,
    bool? newsletter,
    bool? abandonedCart,
    bool? loyaltyUpdates,
  }) {
    return EmailPreferences(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      restockAlerts: restockAlerts ?? this.restockAlerts,
      newsletter: newsletter ?? this.newsletter,
      abandonedCart: abandonedCart ?? this.abandonedCart,
      loyaltyUpdates: loyaltyUpdates ?? this.loyaltyUpdates,
    );
  }
}
