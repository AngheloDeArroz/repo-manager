import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/groq_service.dart';
import '../services/model_provider.dart';
import '../widgets/model_picker_button.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // — Top bar (shared) ——————————————————————————
            _buildTopBar(),

            // — Tab content ——————————————————————————————
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: const [
                  _ChatTab(),
                  RepoListScreen(),
                ],
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF39D353), Color(0xFF26A641)],
              ),
            ),
            child: const Center(
              child: Text('M',
                  style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Monday',
            style: TextStyle(
              color: Color(0xFFE6EDF3),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: const Color(0xFF8B949E), size: 22),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(color: const Color(0xFF30363D)),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF39D353),
          unselectedItemColor: const Color(0xFF8B949E),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded, size: 20),
              activeIcon: Icon(Icons.chat_bubble_rounded, size: 22),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_rounded, size: 20),
              activeIcon: Icon(Icons.folder_rounded, size: 22),
              label: 'Repos',
            ),
          ],
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
      _messages.add(_ChatMessage(
        role: _Role.assistant,
        text: reply ?? groq.lastError ?? 'No response.',
      ));
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
        // — Model Picker (Top) ———————————————————————————
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 4),
          child: Center(child: ModelPickerButton()),
        ),

        // — Chat area ————————————————————————————————————
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
                ),
        ),

        // — Input ————————————————————————————————————————
        _buildInput(groq.isLoading),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 48, color: const Color(0xFF30363D)),
          const SizedBox(height: 16),
          Text(
            'Ask Monday anything',
            style: TextStyle(
              color: const Color(0xFF8B949E),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(
              color: const Color(0xFF30363D)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 14),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(
                    color: const Color(0xFF8B949E)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLoading
                  ? const Color(0xFF30363D)
                  : const Color(0xFF39D353),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: isLoading ? null : _send,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF8B949E)),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Color(0xFFE6EDF3), size: 18),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? const Color(0xFF39D353)
                : const Color(0xFF30363D),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: isUser
                  ? const Color(0xFFE6EDF3)
                  : const Color(0xFFE6EDF3),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
