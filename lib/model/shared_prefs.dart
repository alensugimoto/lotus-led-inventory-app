import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'file_data.dart';

class SharedPrefs {
  static const String GOT_STARTED = 'gotStarted';
  static const String FILES = 'files';
  static const String SNOOZE = 'snooze';

  static Future<List<FileData>> getFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStringList = prefs.getStringList(SharedPrefs.FILES) ?? [];
    return jsonStringList
        .map((jsonString) => FileData.fromJson(
              jsonString == null ? {} : json.decode(jsonString),
            ))
        .toList();
  }
}
