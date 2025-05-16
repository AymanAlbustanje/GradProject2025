class Item {
  final String? id; // Represents household_item_id
  final String name;
  final String? photoUrl;
  final int? itemId; // Original item_id from the global items table
  final String? location;
  final double? price;
  final DateTime? expirationDate;
  final int? purchaseCounter;
  final int? quantity; // Added quantity
  final String? notes; // Added notes

  Item({
    this.id,
    required this.name,
    this.photoUrl,
    this.itemId,
    this.location,
    this.price,
    this.expirationDate,
    this.purchaseCounter,
    this.quantity,
    this.notes,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['household_item_id']?.toString(),
      name: json['item_name'] ?? 'Unknown Item',
      photoUrl: json['item_photo'] ?? json['global_photo'],
      itemId: json['item_id'] as int?,
      location: json['location'] as String?,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null, // Modified line
      expirationDate: json['expiration_date'] != null && json['expiration_date'].toString().isNotEmpty
          ? DateTime.tryParse(json['expiration_date'].toString())
          : null,
      purchaseCounter: json['purchase_counter'] as int?,
      quantity: json['quantity'] as int?,
      notes: json['notes'] as String?,
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
      'expiration_date': expirationDate?.toIso8601String().split('T')[0], // Store date only
      'purchase_counter': purchaseCounter,
      'quantity': quantity,
      'notes': notes,
    };
  }
}