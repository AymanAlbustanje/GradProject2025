class Household {
  final String id;
  final String name;
  final String? createdBy;
  final String inviteCode; 

  Household({
    required this.id,
    required this.name,
    this.createdBy,
    required this.inviteCode,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['household_id'].toString(),
      name: json['name'],
      createdBy: json['created_by']?.toString(), 
      inviteCode: json['invite_code'], 
    );
  }
}