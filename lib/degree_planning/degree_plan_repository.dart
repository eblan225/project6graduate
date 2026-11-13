import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'degree_plan.dart';

abstract interface class DegreePlanRepository {
  Future<DegreePlanInput?> load();
  Future<void> save(DegreePlanInput input);
}

class PreferencesDegreePlanRepository implements DegreePlanRepository {
  static const _storageKey = 'graduate_degree_plan_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<DegreePlanInput?> load() async {
    final encoded = await _preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Saved degree plan has an invalid format.');
    }
    return DegreePlanInput.fromJson(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> save(DegreePlanInput input) =>
      _preferences.setString(_storageKey, jsonEncode(input.toJson()));
}
