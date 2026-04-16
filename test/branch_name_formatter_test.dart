import 'package:flutter_test/flutter_test.dart';

import 'package:monday/utils/branch_name_formatter.dart';

void main() {
  group('BranchNameFormatter', () {
    test('normalizes refs prefixes and invalid characters', () {
      expect(
        BranchNameFormatter.normalize('refs/heads/Feat/Add login!!!'),
        'feat/add-login',
      );
    });

    test('keeps allowed branch types and collapses separators', () {
      expect(
        BranchNameFormatter.normalize('fix/Crash on launch'),
        'fix/crash-on-launch',
      );
    });

    test('falls back to untitled when the AI gives nothing usable', () {
      expect(BranchNameFormatter.normalize(''), 'feat/untitled');
    });
  });
}
