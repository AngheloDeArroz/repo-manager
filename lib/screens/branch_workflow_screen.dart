import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exceptions.dart';
import '../models/proposed_change.dart';
import '../services/api_key_manager.dart';
import '../services/groq_service.dart';
import '../services/model_provider.dart';
import '../services/repo_provider.dart';
import '../widgets/needs_api_key_prompt.dart';

/// Branch workflow UI — the approve / reject / revise gate.
///
/// Flow:
/// 1. User describes a task
/// 2. AI generates: branch name, commit message, file changes
/// 3. User reviews the full proposal
/// 4. Approve → push · Reject → discard · Revise → iterate
class BranchWorkflowScreen extends StatefulWidget {
  const BranchWorkflowScreen({super.key});

  @override
  State<BranchWorkflowScreen> createState() => _BranchWorkflowScreenState();
}

class _BranchWorkflowScreenState extends State<BranchWorkflowScreen> {
  final _taskController = TextEditingController();
  ProposedChange? _proposal;
  bool _isGenerating = false;
  bool _isPushing = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  String? _publishPreflightError(RepoProvider provider) {
    final repo = provider.selectedRepo;
    if (repo == null) {
      return 'Select a repository before continuing.';
    }

    if (provider.branchError != null) {
      return provider.branchError;
    }

    final branch = provider.selectedBranch;
    if (branch == null) {
      return 'Select a branch before approving changes.';
    }

    if (branch.sha.isEmpty) {
      return 'The selected branch does not have a commit SHA yet.';
    }

    return null;
  }

  Widget _buildBranchWarning(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, size: 16, color: Color(0xFFFBBF24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.95),
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // — Generate proposal via AI ——————————————————————————

  Future<void> _generate() async {
    final taskText = _taskController.text.trim();
    if (taskText.isEmpty) return;

    final provider = context.read<RepoProvider>();
    final preflightError = _publishPreflightError(provider);
    if (preflightError != null) {
      setState(() {
        _error = preflightError;
      });
      return;
    }

    final repo = provider.selectedRepo!;
    final branch = provider.selectedBranch!;

    setState(() {
      _isGenerating = true;
      _error = null;
      _proposal = null;
      _successMessage = null;
    });

    final groq = context.read<GroqService>();
    final model = context.read<ModelProvider>().currentModel;

    String? reply;
    try {
      reply = await groq.sendPrompt(
        model: model,
        systemPrompt: '''You are Monday, a professional developer assistant.
Given a task, generate a structured response in this EXACT format:

BRANCH: type/description (lowercase, hyphen-separated, no words: ai, auto, bot, assistant, generated)
COMMIT: type: short description (conventional commit format)
DESCRIPTION: one-line summary of what this change does

FILES:
--- path/to/file.dart ---
<complete file content here>
--- END ---

Rules:
- Branch types: feat, fix, refactor, perf, chore
- Write complete, correct, production-quality code
- Use the repository context provided
- One branch per task
- Never touch files outside task scope''',
        userContent:
            'Repository: ${repo.fullName}\nCurrent branch: ${branch.name}\n\nTask: $taskText',
        maxTokens: 2048,
        temperature: 0.4,
      );
    } on NoApiKeyException {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _error = 'No active API key. Please add one in Settings.';
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _error = 'Error calling AI: $e';
      });
      return;
    }

    if (!mounted) return;

    if (reply == null) {
      setState(() {
        _isGenerating = false;
        _error = groq.lastError ?? 'No response from AI.';
      });
      return;
    }

    // Parse the AI response
    try {
      final proposal = _parseProposal(reply);
      setState(() {
        _proposal = proposal;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _error = 'Failed to parse AI response. Try rephrasing your task.';
      });
    }
  }

  ProposedChange _parseProposal(String text) {
    final branchMatch = RegExp(r'BRANCH:\s*(.+)').firstMatch(text);
    final commitMatch = RegExp(r'COMMIT:\s*(.+)').firstMatch(text);
    final descMatch = RegExp(r'DESCRIPTION:\s*(.+)').firstMatch(text);

    final branch = branchMatch?.group(1)?.trim() ?? 'feat/untitled';
    final commit = commitMatch?.group(1)?.trim() ?? 'feat: untitled change';
    final desc = descMatch?.group(1)?.trim();

    // Parse files
    final files = <FileChange>[];
    final filePattern = RegExp(r'---\s*(.+?)\s*---\n([\s\S]*?)---\s*END\s*---');
    for (final match in filePattern.allMatches(text)) {
      final path = match.group(1)!.trim();
      final content = match.group(2)!.trim();
      files.add(
        FileChange(path: path, newContent: content, action: FileAction.create),
      );
    }

    return ProposedChange(
      branchName: branch,
      commitMessage: commit,
      description: desc,
      files: files,
    );
  }

  // — Push approved changes —————————————————————————————

  Future<void> _approve() async {
    final proposal = _proposal;
    if (proposal == null) return;

    final provider = context.read<RepoProvider>();
    final repo = provider.selectedRepo;
    final branch = provider.selectedBranch;
    if (repo == null || branch == null) return;

    setState(() {
      _isPushing = true;
      _error = null;
      proposal.status = ProposedChangeStatus.pushing;
    });

    try {
      final api = provider.apiService;

      // 1. Create branch
      final branchCreated = await api.createBranch(
        repo.owner,
        repo.name,
        proposal.branchName,
        branch.sha,
      );

      if (!branchCreated.success) {
        if (!mounted) return;
        setState(() {
          _isPushing = false;
          _error = 'Failed to create branch "${proposal.branchName}".';
          proposal.status = ProposedChangeStatus.failed;
        });
        return;
      }

      // 2. Push files
      if (proposal.files.isNotEmpty) {
        final fileMap = <String, String>{};
        for (final f in proposal.files) {
          fileMap[f.path] = f.newContent;
        }

        final pushed = await api.pushChanges(
          repo.owner,
          repo.name,
          branch: proposal.branchName,
          commitMessage: proposal.commitMessage,
          files: fileMap,
          baseSha: branch.sha,
        );

        if (!pushed.success) {
          if (!mounted) return;
          setState(() {
            _isPushing = false;
            _error =
                'Branch created but failed to push files. Check branch "${proposal.branchName}" on GitHub.';
            proposal.status = ProposedChangeStatus.failed;
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _isPushing = false;
        proposal.status = ProposedChangeStatus.pushed;
        _successMessage = 'Pushed to ${proposal.branchName} ✓';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPushing = false;
        _error = 'Push failed: $e';
        proposal.status = ProposedChangeStatus.failed;
      });
    }
  }

  void _reject() {
    setState(() {
      _proposal?.status = ProposedChangeStatus.rejected;
      _proposal = null;
      _error = null;
      _successMessage = null;
    });
  }

  void _revise() {
    setState(() {
      _proposal?.status = ProposedChangeStatus.revising;
      _proposal = null;
      _error = null;
      _successMessage = null;
      // Keep the task text so user can tweak it
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, provider),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (context.watch<ApiKeyManager>().keys.isEmpty) ...[
                      const NeedsApiKeyPrompt(),
                      const SizedBox(height: 16),
                    ],
                    _buildTaskInput(provider),
                    if (provider.branchError != null) ...[
                      const SizedBox(height: 12),
                      _buildBranchWarning(provider.branchError!),
                    ],
                    if (_error != null) _buildError(),
                    if (_successMessage != null) _buildSuccess(),
                    if (_proposal != null) ...[
                      const SizedBox(height: 20),
                      _buildProposalCard(),
                      const SizedBox(height: 16),
                      _buildActionButtons(provider),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, RepoProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Branch Workflow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (provider.selectedBranch != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.call_split_rounded,
                    size: 12,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    provider.selectedBranch!.name,
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskInput(RepoProvider provider) {
    final canGenerate =
        !_isGenerating &&
        !_isPushing &&
        _publishPreflightError(provider) == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Describe your task',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: TextField(
            controller: _taskController,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'e.g. "Add a loading spinner to the login screen"',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: canGenerate ? _generate : null,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              _isGenerating ? 'Generating…' : 'Generate Plan',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFF7C3AED,
              ).withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Color(0xFF22C55E),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _successMessage!,
                style: TextStyle(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.9),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalCard() {
    final p = _proposal!;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Header ——————————————————————————————————————
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PROPOSAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                _StatusPill(status: p.status),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // — Branch ——————————————————————————————————
                _ProposalRow(
                  icon: Icons.call_split_rounded,
                  label: 'Branch',
                  value: p.branchName,
                  valueColor: const Color(0xFF7C3AED),
                ),
                const SizedBox(height: 10),

                // — Commit message ——————————————————————————
                _ProposalRow(
                  icon: Icons.commit_rounded,
                  label: 'Commit',
                  value: p.commitMessage,
                ),
                const SizedBox(height: 10),

                // — Description —————————————————————————————
                if (p.description != null) ...[
                  _ProposalRow(
                    icon: Icons.description_rounded,
                    label: 'About',
                    value: p.description!,
                  ),
                  const SizedBox(height: 10),
                ],

                // — Files ———————————————————————————————————
                Text(
                  'Affected files (${p.files.length})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                ...p.files.map((f) => _FileChangeTile(file: f)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(RepoProvider provider) {
    final canApprove = !_isPushing && _publishPreflightError(provider) == null;

    if (_proposal?.status == ProposedChangeStatus.pushed) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Reject
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isPushing ? null : _reject,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: BorderSide(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Revise
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isPushing ? null : _revise,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text(
                'Revise',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFBBF24),
                side: BorderSide(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Approve
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: canApprove ? _approve : null,
              icon: _isPushing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _isPushing ? 'Pushing…' : 'Approve & Push',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFF22C55E,
                ).withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// — Proposal row ——————————————————————————————————————————

class _ProposalRow extends StatelessWidget {
  const _ProposalRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.3)),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white.withValues(alpha: 0.8),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              fontFamily: valueColor != null ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

// — File change tile —————————————————————————————————————

class _FileChangeTile extends StatelessWidget {
  const _FileChangeTile({required this.file});
  final FileChange file;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            _actionBadge(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                file.path,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '+${file.additions}',
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '-${file.deletions}',
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBadge() {
    final (label, color) = switch (file.action) {
      FileAction.create => ('A', const Color(0xFF22C55E)),
      FileAction.modify => ('M', const Color(0xFFFBBF24)),
      FileAction.delete => ('D', const Color(0xFFEF4444)),
    };

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// — Status pill ——————————————————————————————————————————

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ProposedChangeStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ProposedChangeStatus.pending => ('Pending Review', Colors.white54),
      ProposedChangeStatus.approved => ('Approved', const Color(0xFF22C55E)),
      ProposedChangeStatus.rejected => ('Rejected', const Color(0xFFEF4444)),
      ProposedChangeStatus.revising => ('Revising', const Color(0xFFFBBF24)),
      ProposedChangeStatus.pushing => ('Pushing…', const Color(0xFF3B82F6)),
      ProposedChangeStatus.pushed => ('Pushed ✓', const Color(0xFF22C55E)),
      ProposedChangeStatus.failed => ('Failed', const Color(0xFFEF4444)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
