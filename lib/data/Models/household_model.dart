class Household {
  final dynamic id;
  final String name;
  final String? inviteCode;
  final DateTime? createdAt;
  @override
  String toString() {
    return 'Household(id=$id (${id.runtimeType}), name=$name, inviteCode=$inviteCode)';
  }

  Household({required this.id, required this.name, this.inviteCode, this.createdAt});

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['household_id'] ?? json['id'],
      name: json['name'],
      inviteCode: json['invite_code'] ?? json['inviteCode'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'inviteCode': inviteCode, 'created_at': createdAt?.toIso8601String()};
  }
}
