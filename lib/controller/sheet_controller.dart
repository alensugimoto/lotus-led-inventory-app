import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory/model/post_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/sheet.dart';

class SheetController {
  final String url =
      'https://script.google.com/macros/s/AKfycbyGkBf8vg2kn4u9rl8NMBqD7vTAQRPuO9zRqsBRMgQ-4PFc42Z7/exec';

//  Future<Sheet> getSheetData() async {
//    final response = await http.get(url);
//
//    if (response.statusCode == 200) {
//      return Sheet.fromJson(json.decode(response.body));
//    } else {
//      throw Exception('Failed to get sheet data.');
//    }
//  }

  Future<Sheet> getSheetData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await http.post(
      url,
      body: {
        'isGet': 'true',
        'spreadId': prefs.getString('spreadId'),
        'sheetId': prefs.getString('sheetId'),
        'sheetName': prefs.getString('sheetName'),
      },
    );

    if (response.statusCode == 302) {
      var newUrl = response.headers['location'];

      final response2 = await http.get(newUrl);

      if (response2.statusCode == 200) {
        return Sheet.fromJson(json.decode(response2.body));
      } else {
        throw Exception('Failed to get sheet data.');
      }
    } else if (response.statusCode == 200) {
      return Sheet.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get sheet data.');
    }
  }

  Future<PostStatus> postSheetData({
    @required String spreadId,
    @required String sheetId,
    @required String sheetName,
  }) async {
    final response = await http.post(
      url,
      body: {
        'isGet': 'false',
        'spreadId': spreadId,
        'sheetId': sheetId,
        'sheetName': sheetName,
      },
    );

    if (response.statusCode == 302) {
      var newUrl = response.headers['location'];

      final response2 = await http.get(newUrl);

      if (response2.statusCode == 200) {
        return PostStatus.fromJson(json.decode(response2.body));
      } else {
        throw Exception('Failed to post sheet data.');
      }
    } else if (response.statusCode == 200) {
      return PostStatus.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to post sheet data.');
    }
  }
}
