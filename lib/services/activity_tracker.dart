import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityTracker extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _initialized = false;
  
  List<Map<String, String>> _pushedBranches = [];
  
  int get pushCount => _pushedBranches.length;
  List<Map<String, String>> get pushedBranches => List.unmodifiable(_pushedBranches);

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    final stored = _prefs.getStringList('pushed_branches') ?? [];
    _pushedBranches = stored.map((e) {
      try {
        return Map<String, String>.from(jsonDecode(e) as Map);
      } catch (_) {
        return <String, String>{};
      }
    }).where((m) => m.isNotEmpty).toList();
    
    _initialized = true;
    notifyListeners();
  }

  Future<void> recordPush(String repoFullName, String branchName) async {
    if (!_initialized) return;
    
    _pushedBranches.insert(0, {
      'repo': repoFullName,
      'branch': branchName,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    final encoded = _pushedBranches.map((e) => jsonEncode(e)).toList();
    await _prefs.setStringList('pushed_branches', encoded);
    
    notifyListeners();
  }
}
