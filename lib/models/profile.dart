class Profile {
  final String id;
  final String role;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? speciality;
  final String? avatarUrl;
  final bool isBlocked;
  final String memberTier;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.speciality,
    this.avatarUrl,
    this.isBlocked = false,
    this.memberTier = 'standard',
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      role: (map['role'] as String?) ?? 'member',
      firstName: (map['first_name'] as String?) ?? '',
      lastName: (map['last_name'] as String?) ?? '',
      phone: map['phone'] as String?,
      speciality: map['speciality'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isBlocked: (map['is_blocked'] as bool?) ?? false,
      memberTier: (map['member_tier'] as String?) ?? 'standard',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
