class Item {
  final String? id; // Represents household_item_id for items within a household
  final String name;
  final String? photoUrl; // This should be the specific photo for the household_item if available, else global
  final int? itemId;     // Original item_id from the global items table
  final String? location;
  final double? price;
  final DateTime? expirationDate;
  final int? purchaseCounter;
  final int? quantity;
  final String? notes;

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
    String? determinedPhotoUrl;
    if (json['item_photo'] != null && json['item_photo'].toString().isNotEmpty) {
      determinedPhotoUrl = json['item_photo'].toString();
    } else if (json['global_photo'] != null && json['global_photo'].toString().isNotEmpty) {
      determinedPhotoUrl = json['global_photo'].toString();
    }

    return Item(
      id: json['household_item_id']?.toString(),
      name: json['item_name'] ?? 'Unknown Item',
      photoUrl: determinedPhotoUrl,
      itemId: json['item_id'] as int?,
      location: json['location'] as String?,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      expirationDate: json['expiration_date'] != null && json['expiration_date'].toString().isNotEmpty
          ? DateTime.tryParse(json['expiration_date'].toString())
          : null,
      purchaseCounter: json['purchase_counter'] as int?,
      quantity: json['quantity'] as int?, // Assuming backend might send this
      notes: json['notes'] as String?,    // Assuming backend might send this
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
      'quantity': quantity,
      'notes': notes,
    };
  }
}