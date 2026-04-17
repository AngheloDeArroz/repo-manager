import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_key_manager.dart';

class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  final _labelController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isAdding = false;
  String? _error;

  @override
  void dispose() {
    _labelController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _addKey() async {
    final label = _labelController.text.trim();
    final value = _keyController.text.trim();

    if (label.isEmpty) {
      setState(() => _error = 'Label cannot be empty.');
      return;
    }
    if (!value.startsWith('gsk_') || value.length < 40) {
      setState(() => _error = 'Invalid key format. Groq keys start with gsk_.');
      return;
    }

    final manager = context.read<ApiKeyManager>();
    await manager.addKey(label, value);

    setState(() {
      _isAdding = false;
      _error = null;
      _labelController.clear();
      _keyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ApiKeyManager>();
    final keys = manager.keys;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('API Keys', style: TextStyle(color: Color(0xFFE6EDF3), fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Manage your Groq API keys here. Your keys are stored locally and securely.',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (keys.isEmpty && !_isAdding)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No API keys added yet.', style: TextStyle(color: Color(0xFF8B949E))),
                ),
              ),
            for (final keyEntry in keys)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: keyEntry.isDefault ? const Color(0xFF39D353) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          keyEntry.label,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE6EDF3), fontSize: 16),
                        ),
                        if (keyEntry.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF39D353).withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('DEFAULT', style: TextStyle(color: Color(0xFF39D353), fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      keyEntry.maskedValue,
                      style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF8B949E)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!keyEntry.isDefault)
                          TextButton(
                            onPressed: () => manager.setDefaultKey(keyEntry.id),
                            child: const Text('Set as Default', style: TextStyle(color: Color(0xFF26A641))),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => manager.deleteKey(keyEntry.id),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            if (_isAdding) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Add New Key', style: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _labelController,
                      style: const TextStyle(color: Color(0xFFE6EDF3)),
                      decoration: InputDecoration(
                        labelText: 'Label (e.g. Work, Personal)',
                        labelStyle: const TextStyle(color: Color(0xFF8B949E)),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keyController,
                      style: const TextStyle(color: Color(0xFFE6EDF3), fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        labelText: 'API Key (gsk_...)',
                        labelStyle: const TextStyle(color: Color(0xFF8B949E)),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _isAdding = false;
                            _error = null;
                            _labelController.clear();
                            _keyController.clear();
                          }),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B949E))),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF39D353), foregroundColor: const Color(0xFFE6EDF3)),
                          onPressed: _addKey,
                          child: const Text('Save'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isAdding = true),
                icon: const Icon(Icons.add),
                label: const Text('Add API Key'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(20),
                  foregroundColor: const Color(0xFFE6EDF3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
