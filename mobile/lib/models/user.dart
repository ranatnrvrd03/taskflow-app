class AppUser {
  final String id;
  final String username;
  final String name;
  final String role;

  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'employee',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'role': role,
      };

  bool get isCeo => role == 'ceo';
  String get roleLabel => isCeo ? 'CEO' : 'Çalışan';
}

class TeamMember {
  final AppUser user;
  final int total;
  final int open;
  final int done;
  final int overdue;

  const TeamMember({
    required this.user,
    required this.total,
    required this.open,
    required this.done,
    required this.overdue,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final stats = (json['stats'] as Map<String, dynamic>?) ?? {};
    int read(String key) => (stats[key] as num?)?.toInt() ?? 0;
    return TeamMember(
      user: AppUser.fromJson(json),
      total: read('total'),
      open: read('open'),
      done: read('done'),
      overdue: read('overdue'),
    );
  }

  double get progress => total == 0 ? 0 : done / total;
}