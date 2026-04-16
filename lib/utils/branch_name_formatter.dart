/// Normalizes AI-generated branch names into a safe `type/description` form.
class BranchNameFormatter {
  BranchNameFormatter._();

  static const _allowedTypes = {'feat', 'fix', 'refactor', 'perf', 'chore'};
  static const _defaultType = 'feat';
  static const _legacyPrefix = 'refs/heads/';

  /// Convert arbitrary text into a safe branch name.
  static String normalize(String rawName) {
    var value = rawName.trim().toLowerCase();
    if (value.startsWith(_legacyPrefix)) {
      value = value.substring(_legacyPrefix.length);
    }

    value = value.replaceAll('\\', '/');

    if (value.isEmpty) {
      return '$_defaultType/untitled';
    }

    final parts = value.split('/');
    final firstPart = _slugifySegment(parts.first);
    final hasKnownType = _allowedTypes.contains(firstPart);
    final type = hasKnownType ? firstPart : _defaultType;
    final descriptionSource = hasKnownType ? parts.skip(1).join('/') : value;
    final description = _slugifyDescription(
      descriptionSource.isEmpty ? 'untitled' : descriptionSource,
    );

    return '$type/$description';
  }

  static String _slugifyDescription(String input) {
    final cleaned = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final collapsed = cleaned.replaceAll(RegExp(r'-+'), '-');
    final stripped = collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
    return stripped.isEmpty ? 'untitled' : stripped;
  }

  static String _slugifySegment(String input) {
    final cleaned = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return cleaned
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
