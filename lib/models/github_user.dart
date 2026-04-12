/// Minimal GitHub user profile.
class GitHubUser {
  const GitHubUser({
    required this.login,
    required this.avatarUrl,
    this.name,
    this.email,
  });

  final String login;
  final String avatarUrl;
  final String? name;
  final String? email;

  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      login: json['login'] as String,
      avatarUrl: json['avatar_url'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}
