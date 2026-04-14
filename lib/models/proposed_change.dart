/// A proposed set of changes ready for user approval before pushing.
///
/// This is the approval gate — the user sees everything here before
/// any code touches GitHub.
class ProposedChange {
  ProposedChange({
    required this.branchName,
    required this.commitMessage,
    required this.files,
    this.description,
  });

  /// Branch name in `type/description` format (e.g. `feat/add-login`).
  final String branchName;

  /// Conventional commit message (e.g. `feat: add login screen`).
  final String commitMessage;

  /// Optional human-readable description of the change.
  final String? description;

  /// Files to create or update.
  final List<FileChange> files;

  ProposedChangeStatus status = ProposedChangeStatus.pending;
}

enum ProposedChangeStatus { pending, approved, rejected, revising, pushing, pushed, failed }

/// A single file modification within a proposed change.
class FileChange {
  const FileChange({
    required this.path,
    required this.newContent,
    this.oldContent,
    this.action = FileAction.modify,
  });

  /// Repo-relative path, e.g. `lib/screens/login_screen.dart`.
  final String path;

  /// The old content (for showing diff). Null for new files.
  final String? oldContent;

  /// The new content to push.
  final String newContent;

  final FileAction action;

  String get basename => path.split('/').last;

  int get additions {
    if (oldContent == null) return newContent.split('\n').length;
    return _diffLines('+');
  }

  int get deletions {
    if (oldContent == null) return 0;
    return _diffLines('-');
  }

  int _diffLines(String prefix) {
    final oldLines = (oldContent ?? '').split('\n');
    final newLines = newContent.split('\n');
    if (prefix == '+') {
      return newLines.where((l) => !oldLines.contains(l)).length;
    }
    return oldLines.where((l) => !newLines.contains(l)).length;
  }
}

enum FileAction { create, modify, delete }
