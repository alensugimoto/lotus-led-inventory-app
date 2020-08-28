import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

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

  factory FileData.fromJson(Map<String, dynamic> json) => _$FileDataFromJson(json);

  Map<String, dynamic> toJson() => _$FileDataToJson(this);

//  FileData.fromJson(Map<String, dynamic> json)
//      : provider = json['provider'],
//        name = json['name'],
//        id = json['id'],
//        mimeType = json['mimeType'],
//        bytes = json['bytes'];
//
//  Map<String, dynamic> toJson() => {
//        'provider': provider,
//        'name': name,
//        'id': id,
//        'mimeType': mimeType,
//        'bytes': bytes,
//      };

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('file', json.encode(toJson()));
  }
}
