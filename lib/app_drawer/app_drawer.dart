import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lotus_led_inventory/model/file_data.dart';
import 'package:lotus_led_inventory/model/shared_prefs.dart';
import 'package:lotus_led_inventory/screens/about_app/about_app.dart';
import 'package:lotus_led_inventory/screens/help_and_support/help_and_support.dart';
import 'package:lotus_led_inventory/screens/inventory/inventory.dart';
import 'package:lotus_led_inventory/screens/settings/settings.dart';
import 'package:lotus_led_inventory/screens/welcome/policies.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool isLoading;

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ListTile(
                    title: Text(
                      'Lotus LED Inventory',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: isLoading
                        ? CircularProgressIndicator()
                        : Icon(Icons.home),
                    title: Text('Home'),
                    onTap: () async {
                      setState(() => isLoading = true);

                      final prefs = await SharedPreferences.getInstance();
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

                      setState(() => isLoading = false);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help),
                    title: Text('Help and Support'),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => HelpAndSupport(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('About App'),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => AboutApp(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => Settings(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Policies(),
          ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
