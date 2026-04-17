import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../services/github_auth_service.dart';
import '../services/groq_service.dart';
import '../services/model_provider.dart';
import '../models/github_user.dart';
import '../widgets/model_picker_button.dart';
import '../widgets/pixel_banner.dart';
import 'profile_screen.dart';
import 'repo_list_screen.dart';

/// Main screen — bottom nav with Chat and Repos tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GitHubAuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // — Top bar (shared) ——————————————————————————
            _buildTopBar(auth.user),

            // — Tab content ——————————————————————————————
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: const [_ChatTab(), RepoListScreen()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar(GitHubUser? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const SizedBox(
            height: 24, // Keep it app-bar sized
            child: PixelBanner(text: 'Monday'),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161B22),
                border: Border.all(color: const Color(0xFF30363D)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: user?.avatarUrl != null
                    ? Image.network(
                        user!.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _ProfileInitial(user: user),
                      )
                    : _ProfileInitial(user: user),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(top: BorderSide(color: Color(0xFF30363D))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.chat_bubble_rounded, 'Chat'),
            _buildNavItem(1, Icons.folder_rounded, 'Repos'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF102B19) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isActive ? 22 : 24,
              color: isActive ? const Color(0xFF39D353) : const Color(0xFF8B949E),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive) const SizedBox(width: 8),
                  if (isActive)
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF39D353),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInitial extends StatelessWidget {
  const _ProfileInitial({required this.user});

  final GitHubUser? user;

  @override
  Widget build(BuildContext context) {
    final initial = (user?.login.isNotEmpty == true ? user!.login[0] : '?')
        .toUpperCase();

    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFFE6EDF3),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Chat Tab — extracted from the old HomeScreen, unchanged
// ═══════════════════════════════════════════════════════════

class _ChatTab extends StatefulWidget {
  const _ChatTab();

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: _Role.user, text: text));
      _inputController.clear();
    });
    _scrollToBottom();

    final groq = context.read<GroqService>();
    final model = context.read<ModelProvider>().currentModel;

    final reply = await groq.sendPrompt(
      model: model,
      systemPrompt:
          'You are Monday, a concise AI coding assistant. Answer in markdown when helpful.',
      userContent: text,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          role: _Role.assistant,
          text: reply ?? groq.lastError ?? 'No response.',
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groq = context.watch<GroqService>();

    return Column(
      children: [
        // — Chat area ————————————————————————————————————
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
                ),
        ),

        // — Input Area ———————————————————————————————————
        _buildBottomArea(groq.isLoading),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 56,
            color: const Color(0xFF30363D),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ask Monday anything',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Powered by Groq',
            style: TextStyle(
              color: Color(0xFF484F58),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomArea(bool isLoading) {
    return Container(
      color: const Color(0xFF0D1117), // Same as bg
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input pill
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 6),
                  child: ModelPickerButton(),
                ),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 15),
                    maxLines: 6,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Message Monday...',
                      hintStyle: TextStyle(color: Color(0xFF8B949E)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 0, right: 16, top: 14, bottom: 14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isLoading
                          ? const Color(0xFF30363D)
                          : const Color(0xFFE6EDF3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: isLoading ? null : _send,
                      padding: EdgeInsets.zero,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF8B949E),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              color: Color(0xFF0D1117),
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// — Chat message model —————————————————————————————————————

enum _Role { user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});
  final _Role role;
  final String text;
}

// — Message bubble ——————————————————————————————————————————

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final _ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == _Role.user;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant message (Full width with Markdown)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assistant Avatar
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF161B22),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Color(0xFF39D353),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: MarkdownBody(
                data: msg.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  code: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    backgroundColor: Color(0xFF161B22),
                    fontFamily: 'monospace',
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF30363D)),
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
