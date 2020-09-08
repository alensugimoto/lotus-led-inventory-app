import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../inventory/inventory.dart';
import '../welcome/welcome.dart';
import '../../model/file_data.dart';
import '../../model/shared_prefs.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with AfterLayoutMixin<Splash> {
  checkGotStarted() async {
    final prefs = await SharedPreferences.getInstance();
    final _gotStarted = prefs.getBool(SharedPrefs.GOT_STARTED) ?? false;

    if (_gotStarted) {
      final jsonString = prefs.getString(SharedPrefs.FILE);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Inventory(
            FileData.fromJson(
              jsonString == null ? {} : json.decode(jsonString),
            ),
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Welcome()),
      );
    }
  }

  @override
  void afterFirstLayout(BuildContext context) => checkGotStarted();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage("assets/ic_launcher_round.png"),
              width: 300.0,
            ),
            SizedBox(height: 5.0),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
