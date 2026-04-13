/// A commit summary from `GET /repos/:owner/:repo/commits`.
class GitHubCommit {
  const GitHubCommit({
    required this.sha,
    required this.message,
    required this.authorName,
    required this.date,
    this.authorAvatarUrl,
    this.authorLogin,
    this.additions,
    this.deletions,
    this.changedFiles,
    this.files,
  });

  final String sha;
  final String message;
  final String authorName;
  final DateTime date;
  final String? authorAvatarUrl;
  final String? authorLogin;

  /// Stats — only present on detail endpoint.
  final int? additions;
  final int? deletions;
  final int? changedFiles;
  final List<CommitFile>? files;

  String get shortSha => sha.substring(0, 7);

  String get title {
    final firstLine = message.split('\n').first;
    return firstLine.length > 72 ? '${firstLine.substring(0, 72)}…' : firstLine;
  }

  factory GitHubCommit.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>;
    final author = commit['author'] as Map<String, dynamic>;
    final ghAuthor = json['author'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;
    final files = json['files'] as List<dynamic>?;

    return GitHubCommit(
      sha: json['sha'] as String,
      message: commit['message'] as String,
      authorName: author['name'] as String? ?? 'Unknown',
      date: DateTime.parse(author['date'] as String),
      authorAvatarUrl: ghAuthor?['avatar_url'] as String?,
      authorLogin: ghAuthor?['login'] as String?,
      additions: stats?['additions'] as int?,
      deletions: stats?['deletions'] as int?,
      changedFiles: files?.length,
      files: files
          ?.map((f) => CommitFile.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A file changed in a commit.
class CommitFile {
  const CommitFile({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    this.patch,
  });

  final String filename;

  /// One of: added, removed, modified, renamed, copied, changed, unchanged.
  final String status;
  final int additions;
  final int deletions;

  /// Unified diff patch for this file — may be null for binary files.
  final String? patch;

  String get basename => filename.split('/').last;

  factory CommitFile.fromJson(Map<String, dynamic> json) {
    return CommitFile(
      filename: json['filename'] as String,
      status: json['status'] as String? ?? 'modified',
      additions: json['additions'] as int? ?? 0,
      deletions: json['deletions'] as int? ?? 0,
      patch: json['patch'] as String?,
    );
  }
}
