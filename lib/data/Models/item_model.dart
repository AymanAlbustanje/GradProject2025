class Item {
  final String? id; 
  final String name;
  final String? photoUrl;
  final int? itemId;
  final String? location;
  final double? price;
  final DateTime? expirationDate;
  final int? purchaseCounter;
  final int? quantity;
  final String? notes;
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
    this.quantity,
    this.notes,
    this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    String? determinedPhotoUrl;
    // Check for household-specific item photo first
    if (json['item_photo_household'] != null && json['item_photo_household'].toString().isNotEmpty) {
      determinedPhotoUrl = json['item_photo_household'].toString();
    } 
    // Then check for global item photo
    else if (json['item_photo'] != null && json['item_photo'].toString().isNotEmpty) {
      determinedPhotoUrl = json['item_photo'].toString();
    } 
    // Fallback if 'global_photo' is used in some contexts (ensure consistency with backend)
    else if (json['global_photo'] != null && json['global_photo'].toString().isNotEmpty) {
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
      quantity: json['quantity'] as int?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'household_item_id': id,
      'item_name': name,
      'item_photo': photoUrl, // This should ideally be item_photo_household if sending back specific instance
      'item_id': itemId,
      'location': location,
      'price': price,
      'expiration_date': expirationDate?.toIso8601String().split('T')[0],
      'purchase_counter': purchaseCounter,
      'quantity': quantity,
      'notes': notes,
      'category': category,
    };
  }
}