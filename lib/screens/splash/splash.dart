import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../inventory/inventory.dart';
import '../welcome/welcome.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with AfterLayoutMixin<Splash> {

  checkHasStarted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _hasStarted = prefs.getBool('hasStarted') ?? false;

    if (_hasStarted) {
      String file = prefs.getString('file');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Inventory(
          org: prefs.getString('org'),
          file: file == null ? file : json.decode(file),
        )),
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
