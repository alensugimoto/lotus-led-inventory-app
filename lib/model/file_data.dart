import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import 'shared_prefs.dart';

part 'file_data.g.dart';

@JsonSerializable()
class FileData {
  final String provider;
  final String name;
  final String id;
  final String mimeType;
  final List<int> bytes;
  final String dateTime;

  FileData({
    @required this.provider,
    @required this.name,
    @required this.id,
    @required this.mimeType,
    @required this.bytes,
    @required this.dateTime,
  });

  factory FileData.fromJson(Map<String, dynamic> json) =>
      _$FileDataFromJson(json);

  Map<String, dynamic> toJson() => _$FileDataToJson(this);

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final newList = (prefs.getStringList(SharedPrefs.FILES) ?? [])
      ..add(
        json.encode(toJson()),
      );
    await prefs.setStringList(SharedPrefs.FILES, newList);
  }
}
