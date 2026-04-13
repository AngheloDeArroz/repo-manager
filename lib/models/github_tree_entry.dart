/// A single node in a Git tree (file or directory).
///
/// Returned by `GET /repos/:owner/:repo/git/trees/:sha`.
class GitHubTreeEntry implements Comparable<GitHubTreeEntry> {
  const GitHubTreeEntry({
    required this.path,
    required this.type,
    required this.sha,
    this.size,
  });

  /// Relative path segment (file or folder name).
  final String path;

  /// `"tree"` for directories, `"blob"` for files.
  final String type;

  final String sha;

  /// Size in bytes — only present for blobs.
  final int? size;

  bool get isDirectory => type == 'tree';
  bool get isFile => type == 'blob';

  factory GitHubTreeEntry.fromJson(Map<String, dynamic> json) {
    return GitHubTreeEntry(
      path: json['path'] as String,
      type: json['type'] as String,
      sha: json['sha'] as String,
      size: json['size'] as int?,
    );
  }

  /// Sorts directories before files, then alphabetically.
  @override
  int compareTo(GitHubTreeEntry other) {
    if (isDirectory && other.isFile) return -1;
    if (isFile && other.isDirectory) return 1;
    return path.toLowerCase().compareTo(other.path.toLowerCase());
  }
}
