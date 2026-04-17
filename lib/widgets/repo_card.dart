import 'package:flutter/material.dart';

import '../models/github_repo.dart';

/// A glassmorphic card for a single repository in the list.
class RepoCard extends StatelessWidget {
  const RepoCard({super.key, required this.repo, required this.onTap});

  final GitHubRepo repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFF39D353).withValues(alpha: 0.08),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF30363D),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // — Row 1: name + private badge ———————————————
                Row(
                  children: [
                    Icon(
                      repo.isPrivate
                          ? Icons.lock_rounded
                          : Icons.menu_book_rounded,
                      size: 16,
                      color: repo.isPrivate
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF39D353),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        repo.name,
                        style: const TextStyle(
                          color: Color(0xFFE6EDF3),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (repo.isPrivate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFBBF24).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Private',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                // — Description ——————————————————————————————
                if (repo.description != null &&
                    repo.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    repo.description!,
                    style: TextStyle(
                      color: const Color(0xFF8B949E),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // — Row 2: language · stars · updated ————————
                Row(
                  children: [
                    if (repo.language != null) ...[
                      _LanguageDot(language: repo.language!),
                      const SizedBox(width: 5),
                      Text(
                        repo.language!,
                        style: TextStyle(
                          color: const Color(0xFF8B949E),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Icon(Icons.star_rounded,
                        size: 14,
                        color: const Color(0xFF8B949E)),
                    const SizedBox(width: 3),
                    Text(
                      '${repo.starCount}',
                      style: TextStyle(
                        color: const Color(0xFF8B949E),
                        fontSize: 11.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _relativeTime(repo.updatedAt),
                      style: TextStyle(
                        color: const Color(0xFF8B949E),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

// — Language color dot ——————————————————————————————————

class _LanguageDot extends StatelessWidget {
  const _LanguageDot({required this.language});
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _colorFor(language),
        shape: BoxShape.circle,
      ),
    );
  }

  static Color _colorFor(String lang) {
    return switch (lang.toLowerCase()) {
      'dart' => const Color(0xFF00B4AB),
      'javascript' => const Color(0xFFF1E05A),
      'typescript' => const Color(0xFF3178C6),
      'python' => const Color(0xFF3572A5),
      'java' => const Color(0xFFB07219),
      'kotlin' => const Color(0xFFA97BFF),
      'swift' => const Color(0xFFFF6F43),
      'c++' || 'cpp' => const Color(0xFFF34B7D),
      'c#' => const Color(0xFF178600),
      'go' => const Color(0xFF00ADD8),
      'rust' => const Color(0xFFDEA584),
      'ruby' => const Color(0xFF701516),
      'php' => const Color(0xFF4F5D95),
      'html' => const Color(0xFFE34C26),
      'css' => const Color(0xFF563D7C),
      'shell' || 'bash' => const Color(0xFF89E051),
      _ => const Color(0xFF8B8B8B),
    };
  }
}
