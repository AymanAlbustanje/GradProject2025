class Item {
  final String? id; // Adding an ID field
  final String name;
  final String? photoUrl;

  Item({this.id, required this.name, this.photoUrl});

  // Factory constructor to create an Item from JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? json['_id'], // Handle different possible ID field names
      name: json['name'],
      photoUrl: json['photoUrl'],
    );
  }

  // Method to convert an Item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
    };
  }
}