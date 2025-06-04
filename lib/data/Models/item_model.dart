class Item {
  final String? id;
  final String name;
  final String? photoUrl;
  final int? itemId;
  final String? location;
  final double? price;
  final DateTime? expirationDate;
  final int? purchaseCounter;
  final double? totalPurchasePrice;
  final String? category;

  Item({
    this.id,
    required this.name,
    this.photoUrl,
    this.itemId,
    this.location,
    this.price,
    this.expirationDate,
    this.purchaseCounter,
    this.totalPurchasePrice,
    this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    String? photoUrl = json['item_photo']?.toString();

    return Item(
      id: json['household_item_id']?.toString(),
      name: json['item_name'] ?? 'Unknown Item',
      photoUrl: photoUrl,
      itemId: json['item_id'] as int?,
      location: json['location'] as String?,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      expirationDate:
          json['expiration_date'] != null && json['expiration_date'].toString().isNotEmpty
              ? DateTime.tryParse(json['expiration_date'].toString())
              : null,
      purchaseCounter: json['purchase_counter'] as int?,
      totalPurchasePrice:
          json['total_purchase_price'] != null ? double.tryParse(json['total_purchase_price'].toString()) : null,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'household_item_id': id,
      'item_name': name,
      'item_photo': photoUrl,
      'item_id': itemId,
      'location': location,
      'price': price,
      'expiration_date': expirationDate?.toIso8601String().split('T')[0],
      'purchase_counter': purchaseCounter,
      'total_purchase_price': totalPurchasePrice,
      'category': category,
    };
  }
}
