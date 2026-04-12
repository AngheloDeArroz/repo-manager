import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/groq_model.dart';

/// Manages the user-selected Groq model.
///
/// Persisted in [SharedPreferences] so it survives app restarts.
class ModelProvider extends ChangeNotifier {
  ModelProvider();

  static const _key = 'selected_groq_model';

  GroqModel _current = GroqModel.fast;
  GroqModel get currentModel => _current;

  SharedPreferences? _prefs;

  /// Call once at app startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _current = GroqModel.fromName(_prefs?.getString(_key));
    notifyListeners();
  }

  /// Switch to a different model and persist the choice.
  void setModel(GroqModel model) {
    if (model == _current) return;
    _current = model;
    _prefs?.setString(_key, model.name);
    notifyListeners();
  }
}
