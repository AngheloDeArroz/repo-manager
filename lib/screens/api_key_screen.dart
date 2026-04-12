import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/secure_storage_service.dart';

/// First-run screen: prompts the user to enter their Groq API key.
class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key, required this.onKeySaved});

  /// Called after the key is successfully saved.
  final VoidCallback onKeySaved;

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _controller = TextEditingController();
  final _storage = SecureStorageService();
  bool _obscure = true;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidKey(String key) {
    // Groq keys start with "gsk_" and are 56 characters long.
    return key.startsWith('gsk_') && key.length >= 40;
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (!_isValidKey(key)) {
      setState(() =>
          _error = 'Invalid key. Groq keys start with gsk_ and are 40+ characters.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await _storage.setApiKey(key);
    if (mounted) widget.onKeySaved();
  }

  Future<void> _openConsole() async {
    final uri = Uri.parse('https://console.groq.com/keys');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // — Icon ——————————————————————————————————————
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.key_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 28),

              // — Title —————————————————————————————————————
              const Text(
                'Enter your Groq API key',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your key is stored locally and never leaves this device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // — Input —————————————————————————————————————
              TextField(
                controller: _controller,
                obscureText: _obscure,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'gsk_xxxxxxxxxxxxxxxx',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style:
                      const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                ),
              ],

              const SizedBox(height: 20),

              // — Save button ———————————————————————————————
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // — Console link ——————————————————————————————
              TextButton(
                onPressed: _openConsole,
                child: Text(
                  'Get a free key at console.groq.com →',
                  style: TextStyle(
                    color:
                        const Color(0xFF7C3AED).withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
