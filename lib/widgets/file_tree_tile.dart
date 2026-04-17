import 'package:flutter/material.dart';

import '../models/github_tree_entry.dart';

/// A single row in the file tree — folder or file with icon and size.
class FileTreeTile extends StatelessWidget {
  const FileTreeTile({super.key, required this.entry, required this.onTap});

  final GitHubTreeEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFF39D353).withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // — Icon ————————————————————————————————————————
            _FileIcon(entry: entry),
            const SizedBox(width: 12),

            // — Name ————————————————————————————————————————
            Expanded(
              child: Text(
                entry.path,
                style: TextStyle(
                  color: entry.isDirectory
                      ? const Color(0xFFE6EDF3)
                      : const Color(0xFFE6EDF3),
                  fontSize: 13.5,
                  fontWeight:
                      entry.isDirectory ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // — Size (files only) ——————————————————————————
            if (entry.isFile && entry.size != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatSize(entry.size!),
                style: TextStyle(
                  color: const Color(0xFF8B949E),
                  fontSize: 11,
                ),
              ),
            ],

            // — Chevron for directories ———————————————————
            if (entry.isDirectory)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: const Color(0xFF8B949E),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// — File icon with extension-based colors ————————————————

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.entry});
  final GitHubTreeEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.isDirectory) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF39D353).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(
          Icons.folder_rounded,
          size: 16,
          color: Color(0xFF39D353),
        ),
      );
    }

    final ext = entry.path.contains('.') ? entry.path.split('.').last : '';
    final (icon, color) = _iconForExtension(ext);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 15, color: color),
    );
  }

  static (IconData, Color) _iconForExtension(String ext) {
    return switch (ext.toLowerCase()) {
      'dart' => (Icons.flutter_dash, const Color(0xFF00B4AB)),
      'js' || 'jsx' || 'ts' || 'tsx' => (Icons.javascript_rounded, const Color(0xFFF1E05A)),
      'py' => (Icons.code_rounded, const Color(0xFF3572A5)),
      'java' || 'kt' => (Icons.coffee_rounded, const Color(0xFFB07219)),
      'json' => (Icons.data_object_rounded, const Color(0xFF5D9B38)),
      'yaml' || 'yml' => (Icons.settings_rounded, const Color(0xFFCB171E)),
      'md' => (Icons.description_rounded, const Color(0xFF083FA1)),
      'html' || 'htm' => (Icons.html_rounded, const Color(0xFFE34C26)),
      'css' || 'scss' => (Icons.css_rounded, const Color(0xFF563D7C)),
      'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' =>
        (Icons.image_rounded, const Color(0xFFA855F7)),
      'lock' => (Icons.lock_rounded, const Color(0xFF6B7280)),
      'gitignore' => (Icons.visibility_off_rounded, const Color(0xFF6B7280)),
      _ => (Icons.insert_drive_file_rounded, const Color(0xFF6B7280)),
    };
  }
}
