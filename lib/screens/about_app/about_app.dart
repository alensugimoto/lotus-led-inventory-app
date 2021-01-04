import 'package:flutter/material.dart';

import '../../app_drawer/app_drawer.dart';
import '../../model/links.dart';
import 'package_info_tile.dart';
import '../../app.dart';
import '../../model/try_catch.dart';

class AboutApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About App'),
      ),
      drawer: AppDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacy Policy'),
            onTap: () async {
              await TryCatch.open(context, Links.PRIVACY_POLICY);
            },
            trailing: Icon(Icons.launch),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Terms and Conditions'),
            onTap: () async {
              await TryCatch.open(context, Links.TERMS_AND_CONDITIONS);
            },
            trailing: Icon(Icons.launch),
          ),
          ListTile(
            leading: Icon(Icons.folder_special),
            title: Text('Trademark Notices'),
            onTap: () {
              showDialog(
                context: App.navigatorKey.currentState.overlay.context,
                builder: (context) => AlertDialog(
                  title: Text('Trademark Notices'),
                  content: Text(
                    'Dropbox and the Dropbox logo are trademarks of Dropbox, '
                    'Inc.\n\nGoogle Drive is a trademark of Google Inc. Use of '
                    'this trademark is subject to Google Permissions.',
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(),
          PackageInfoTile(
            getTitle: (info) => 'Version ${info.version}',
          ),
        ],
      ),
    );
  }
}
