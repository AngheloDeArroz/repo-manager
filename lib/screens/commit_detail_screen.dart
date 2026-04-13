import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/github_commit.dart';
import '../services/groq_service.dart';
import '../services/model_provider.dart';
import '../services/repo_provider.dart';

/// Shows a commit's diff with file-by-file patches and an AI code review button.
class CommitDetailScreen extends StatefulWidget {
  const CommitDetailScreen({super.key, required this.commit});

  final GitHubCommit commit;

  @override
  State<CommitDetailScreen> createState() => _CommitDetailScreenState();
}

class _CommitDetailScreenState extends State<CommitDetailScreen> {
  GitHubCommit? _detail;
  bool _isLoading = true;
  String? _error;

  String? _review;
  bool _isReviewing = false;

  // Track which files are expanded
  final Set<int> _expandedFiles = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final provider = context.read<RepoProvider>();
    final repo = provider.selectedRepo;
    if (repo == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await provider.apiService.getCommitDetail(
        repo.owner,
        repo.name,
        widget.commit.sha,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
        if (detail == null) _error = 'Could not load commit details.';
        // Expand all files by default if ≤ 5
        if (detail?.files != null && detail!.files!.length <= 5) {
          _expandedFiles.addAll(
            List.generate(detail.files!.length, (i) => i),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load commit: $e';
      });
    }
  }

  Future<void> _reviewWithAI() async {
    final detail = _detail;
    if (detail == null || detail.files == null) return;

    setState(() {
      _isReviewing = true;
      _review = null;
    });

    final groq = context.read<GroqService>();
    final model = context.read<ModelProvider>().currentModel;

    // Build a trimmed diff for the prompt
    final diffBuf = StringBuffer();
    diffBuf.writeln('Commit: ${detail.shortSha}');
    diffBuf.writeln('Message: ${detail.message}');
    diffBuf.writeln('Author: ${detail.authorName}');
    diffBuf.writeln(
        'Stats: +${detail.additions ?? 0} -${detail.deletions ?? 0} in ${detail.changedFiles ?? 0} files');
    diffBuf.writeln();

    var totalChars = 0;
    const charLimit = 10000;

    for (final file in detail.files!) {
      if (totalChars > charLimit) {
        diffBuf.writeln('\n... (diff truncated — too large for analysis)');
        break;
      }
      diffBuf.writeln('--- ${file.filename} (${file.status}) +${file.additions} -${file.deletions}');
      if (file.patch != null) {
        final patch = file.patch!.length > 2000
            ? '${file.patch!.substring(0, 2000)}\n... (patch truncated)'
            : file.patch!;
        diffBuf.writeln(patch);
        totalChars += patch.length;
      }
      diffBuf.writeln();
    }

    final reply = await groq.sendPrompt(
      model: model,
      systemPrompt: '''You are Monday, a senior code reviewer.
Review this commit diff concisely:
1. Summary — what does this commit do?
2. Quality — is the code clean, correct, well-structured?
3. Issues — any bugs, security concerns, or bad practices?
4. Suggestions — concrete improvements (if any)

Be direct and technical. Use markdown. Keep it under 300 words.''',
      userContent: diffBuf.toString(),
      maxTokens: 1024,
      temperature: 0.3,
    );

    if (!mounted) return;
    setState(() {
      _review = reply ?? groq.lastError ?? 'No response from AI.';
      _isReviewing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.commit.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        widget.commit.shortSha,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.commit.authorLogin ?? widget.commit.authorName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED)),
            ),
          ],
        ),
      );
    }

    final detail = _detail!;
    final files = detail.files ?? [];

    return Column(
      children: [
        // — Stats bar ——————————————————————————————————————
        _buildStatsBar(detail),

        Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),

        // — File diffs ————————————————————————————————————
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: files.length,
            itemBuilder: (_, i) => _FileDiffCard(
              file: files[i],
              index: i,
              isExpanded: _expandedFiles.contains(i),
              onToggle: () {
                setState(() {
                  if (_expandedFiles.contains(i)) {
                    _expandedFiles.remove(i);
                  } else {
                    _expandedFiles.add(i);
                  }
                });
              },
            ),
          ),
        ),

        // — AI review section —————————————————————————————
        _buildReviewSection(),
      ],
    );
  }

  Widget _buildStatsBar(GitHubCommit detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.insert_drive_file_rounded,
            label: '${detail.changedFiles ?? 0} files',
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.add_rounded,
            label: '${detail.additions ?? 0}',
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.remove_rounded,
            label: '${detail.deletions ?? 0}',
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_review == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isReviewing ? null : _reviewWithAI,
                  icon: _isReviewing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white70),
                        )
                      : const Icon(Icons.rate_review_rounded, size: 18),
                  label: Text(
                    _isReviewing ? 'Reviewing…' : 'AI Code Review',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF7C3AED).withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          if (_review != null || _isReviewing)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: _buildReviewPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rate_review_rounded,
                        size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI Code Review',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_review != null) ...[
                IconButton(
                  onPressed: _isReviewing ? null : _reviewWithAI,
                  icon: Icon(Icons.refresh_rounded,
                      size: 16, color: Colors.white.withValues(alpha: 0.3)),
                  tooltip: 'Re-review',
                ),
                IconButton(
                  onPressed: () => setState(() => _review = null),
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: Colors.white.withValues(alpha: 0.3)),
                  tooltip: 'Dismiss',
                ),
              ],
            ],
          ),
        ),
        if (_isReviewing && _review == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF7C3AED)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Reviewing changes…',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else if (_review != null)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  _review!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// — Stat chip ——————————————————————————————————————————————

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// — File diff card ————————————————————————————————————————

class _FileDiffCard extends StatelessWidget {
  const _FileDiffCard({
    required this.file,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  final CommitFile file;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: file.patch != null ? onToggle : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _StatusBadge(status: file.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.filename,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (file.additions > 0)
                      Text(
                        '+${file.additions}',
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    if (file.additions > 0 && file.deletions > 0)
                      const SizedBox(width: 6),
                    if (file.deletions > 0)
                      Text(
                        '-${file.deletions}',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    if (file.patch != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Diff patch (expanded)
            if (isExpanded && file.patch != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF12121E),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.04)),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: file.patch!.split('\n').map((line) {
                        return Text(
                          line,
                          style: TextStyle(
                            color: _lineColor(line),
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            height: 1.55,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _lineColor(String line) {
    if (line.startsWith('+')) return const Color(0xFF22C55E);
    if (line.startsWith('-')) return const Color(0xFFEF4444);
    if (line.startsWith('@@')) {
      return const Color(0xFF7C3AED).withValues(alpha: 0.7);
    }
    return Colors.white.withValues(alpha: 0.5);
  }
}

// — Status badge ——————————————————————————————————————————

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'added' => ('A', const Color(0xFF22C55E)),
      'removed' => ('D', const Color(0xFFEF4444)),
      'modified' => ('M', const Color(0xFFFBBF24)),
      'renamed' => ('R', const Color(0xFF3B82F6)),
      _ => ('C', Colors.white.withValues(alpha: 0.4)),
    };

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
