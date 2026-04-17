import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/github_tree_entry.dart';
import '../services/groq_service.dart';
import '../services/model_provider.dart';
import '../services/repo_provider.dart';

/// Displays a file's source code and offers an AI-powered explanation via Groq.
class FileViewerScreen extends StatefulWidget {
  const FileViewerScreen({super.key, required this.entry});

  final GitHubTreeEntry entry;

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  String? _content;
  bool _isLoadingFile = true;
  String? _fileError;

  String? _explanation;
  bool _isExplaining = false;

  final _scrollController = ScrollController();
  final _explainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _explainScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    final repo = context.read<RepoProvider>().selectedRepo;
    final branch = context.read<RepoProvider>().selectedBranch;
    if (repo == null) return;

    setState(() {
      _isLoadingFile = true;
      _fileError = null;
    });

    final api = context.read<RepoProvider>().apiService;
    final path = _buildFullPath();

    try {
      final content = await api.getFileContent(
        repo.owner,
        repo.name,
        path,
        ref: branch?.name,
      );

      if (!mounted) return;
      setState(() {
        _content = content;
        _isLoadingFile = false;
        if (content == null) _fileError = 'Could not load file content.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFile = false;
        _fileError = 'Failed to load file: $e';
      });
    }
  }

  /// Build the full repo-relative path from breadcrumbs + entry name.
  String _buildFullPath() {
    final provider = context.read<RepoProvider>();
    final crumbs = provider.breadcrumbs;
    if (crumbs.isEmpty) return widget.entry.path;
    return '${crumbs.join("/")}/${widget.entry.path}';
  }

  Future<void> _explain() async {
    if (_content == null || _content!.isEmpty) return;

    setState(() {
      _isExplaining = true;
      _explanation = null;
    });

    final groq = context.read<GroqService>();
    final model = context.read<ModelProvider>().currentModel;

    // Trim file content to stay within token budget.
    // Rough estimate: 1 token ≈ 4 chars. Keep under ~3000 tokens for content.
    final trimmed = _content!.length > 12000
        ? '${_content!.substring(0, 12000)}\n\n... (truncated — file too large for full analysis)'
        : _content!;

    final reply = await groq.sendPrompt(
      model: model,
      systemPrompt: '''You are Monday, a senior developer reviewing code.
Explain this file concisely:
1. Purpose — what does this file do?
2. Key components — classes, functions, exports
3. Dependencies — what does it import/rely on?
4. Anything notable — patterns, potential issues, complexity

Be brief and technical. Use markdown formatting.''',
      userContent: '**File: `${widget.entry.path}`**\n\n```\n$trimmed\n```',
      maxTokens: 1024,
      temperature: 0.3,
    );

    if (!mounted) return;
    setState(() {
      _explanation = reply ?? groq.lastError ?? 'No response from AI.';
      _isExplaining = false;
    });

    // Scroll to show explanation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_explainScrollController.hasClients) {
        _explainScrollController.animateTo(0,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Divider(height: 1, color: const Color(0xFF30363D)),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final ext = widget.entry.path.contains('.')
        ? widget.entry.path.split('.').last
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFFE6EDF3), size: 22),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entry.path,
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ext.isNotEmpty)
                  Text(
                    ext.toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFF8B949E),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          // Copy button
          if (_content != null)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _content!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    backgroundColor: const Color(0xFF161B22),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.copy_rounded,
                  size: 18, color: const Color(0xFF8B949E)),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingFile) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39D353)),
      );
    }

    if (_fileError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 40, color: const Color(0xFF30363D)),
              const SizedBox(height: 12),
              Text(
                _fileError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF8B949E),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadFile,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF39D353),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // — Code view ——————————————————————————————————————
        Expanded(
          flex: _explanation != null ? 1 : 2,
          child: _buildCodeView(),
        ),

        // — Explain button / explanation ——————————————————
        _buildExplainSection(),
      ],
    );
  }

  Widget _buildCodeView() {
    final lines = _content?.split('\n') ?? [];

    return Container(
      color: const Color(0xFF12121E),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lines.length, (i) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line number
                      SizedBox(
                        width: 52,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '${i + 1}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: const Color(0xFF30363D),
                              fontSize: 12,
                              fontFamily: 'monospace',
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                      // Code
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          lines[i].isEmpty ? ' ' : lines[i],
                          style: TextStyle(
                            color: const Color(0xFFE6EDF3),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplainSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(color: const Color(0xFF30363D)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // — Explain button ——————————————————————————————
          if (_explanation == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isExplaining ? null : _explain,
                  icon: _isExplaining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF8B949E)),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    _isExplaining ? 'Analyzing…' : 'Explain with AI',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39D353),
                    foregroundColor: const Color(0xFFE6EDF3),
                    disabledBackgroundColor:
                        const Color(0xFF39D353).withValues(alpha: 0.5),
                    disabledForegroundColor: const Color(0xFF8B949E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),

          // — AI explanation panel ————————————————————————
          if (_explanation != null || _isExplaining)
            Flexible(
              child: _buildExplanationPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildExplanationPanel() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // — Header ——————————————————————————————————————
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39D353), Color(0xFF26A641)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 12, color: Color(0xFFE6EDF3)),
                      SizedBox(width: 4),
                      Text(
                        'AI Explanation',
                        style: TextStyle(
                          color: Color(0xFFE6EDF3),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_explanation != null) ...[
                  // Re-explain button
                  IconButton(
                    onPressed: _isExplaining ? null : _explain,
                    icon: Icon(Icons.refresh_rounded,
                        size: 16,
                        color: const Color(0xFF8B949E)),
                    tooltip: 'Re-explain',
                  ),
                  // Close button
                  IconButton(
                    onPressed: () => setState(() => _explanation = null),
                    icon: Icon(Icons.close_rounded,
                        size: 16,
                        color: const Color(0xFF8B949E)),
                    tooltip: 'Dismiss',
                  ),
                ],
              ],
            ),
          ),

          // — Content ————————————————————————————————————
          if (_isExplaining && _explanation == null)
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
                          strokeWidth: 2, color: Color(0xFF39D353)),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Reading the code…',
                      style: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_explanation != null)
            Flexible(
              child: Scrollbar(
                controller: _explainScrollController,
                child: SingleChildScrollView(
                  controller: _explainScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      _explanation!,
                      style: TextStyle(
                        color: const Color(0xFF8B949E),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
