class Item {
  final String? id;
  final String name;
  final String? photoUrl;

  Item({this.id, required this.name, this.photoUrl});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
    };
  }
}