import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'schedule.dart';

abstract interface class ScheduleRepository {
  Future<List<SemesterSchedule>> load();
  Future<void> save(List<SemesterSchedule> schedules);
  Future<void> clear();
}

/// Stores lightweight schedule records on this device. Do not store secrets here.
class PreferencesScheduleRepository implements ScheduleRepository {
  static const _storageKey = 'graduate_semester_schedules_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<List<SemesterSchedule>> load() async {
    final encoded = await _preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return [];

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('Saved schedules have an invalid format.');
    }
    return decoded.map((value) {
      if (value is! Map) {
        throw const FormatException('Saved schedules have an invalid format.');
      }
      return SemesterSchedule.fromJson(Map<String, Object?>.from(value));
    }).toList();
  }

  @override
  Future<void> save(List<SemesterSchedule> schedules) async {
    final encoded = jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    );
    await _preferences.setString(_storageKey, encoded);
  }

  @override
  Future<void> clear() => _preferences.remove(_storageKey);
}
