import 'package:uuid/uuid.dart';

class ApiKeyEntry {
  ApiKeyEntry({
    String? id,
    required this.label,
    required this.value,
    required this.createdAt,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String label;
  final String value;
  final DateTime createdAt;
  final bool isDefault;

  /// Returns a masked version of the key: sk-XXXXXXXXXXXXa1b2
  String get maskedValue {
    if (value.length <= 4) return '****';
    
    // Most Groq keys start with "gsk_" and are 56 chars. 
    // Show prefix "gsk_" if present and last 4 chars, mask the rest.
    String prefix = '';
    if (value.startsWith('gsk_')) {
      prefix = 'gsk_';
    }
    
    final lastFour = value.substring(value.length - 4);
    return '${prefix}${'*' * 16}$lastFour';
  }

  ApiKeyEntry copyWith({
    String? label,
    String? value,
    bool? isDefault,
  }) {
    return ApiKeyEntry(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      createdAt: createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory ApiKeyEntry.fromJson(Map<String, dynamic> json) {
    return ApiKeyEntry(
      id: json['id'] as String?,
      label: json['label'] as String,
      value: json['value'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
