class Household {
  final String id; // This is household_id
  final String name;
  final String? createdBy; // Will be null if not in the specific API response
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