import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../inventory/inventory.dart';
import '../welcome/welcome.dart';
import '../../model/file_data.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with AfterLayoutMixin<Splash> {
  checkHasStarted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _hasStarted = prefs.getBool('hasStarted') ?? false;

    if (_hasStarted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Inventory(
            FileData.fromJson(
              prefs.getString('file') == null
                  ? {}
                  : json.decode(prefs.getString('file')),
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
  void afterFirstLayout(BuildContext context) => checkHasStarted();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
