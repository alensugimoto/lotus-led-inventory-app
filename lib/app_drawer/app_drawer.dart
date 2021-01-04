import 'package:flutter/material.dart';

import '../model/shared_prefs.dart';
import '../screens/about_app/about_app.dart';
import '../screens/help_and_support/help_and_support.dart';
import '../screens/inventory/home.dart';
import '../screens/settings/settings.dart';
import '../screens/welcome/policies.dart';

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
                      'Lotus LED Lights',
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

                      final files = await SharedPrefs.getFiles();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => Home(files),
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
