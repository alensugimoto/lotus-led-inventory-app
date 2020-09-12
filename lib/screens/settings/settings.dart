import 'package:flutter/material.dart';
import 'package:lotus_led_inventory/app_drawer/app_drawer.dart';
import 'package:lotus_led_inventory/model/google_drive.dart';
import 'package:lotus_led_inventory/model/links.dart';
import 'package:lotus_led_inventory/screens/help_and_support/contact_info_tile.dart';
import 'package:lotus_led_inventory/model/dropbox.dart';
import 'package:lotus_led_inventory/screens/settings/custom_switch_tile.dart';

import '../../app.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      drawer: AppDrawer(),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              'App Permissions (Google Drive)',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CustomSwitchTile(
            permission: 'Read file metadata and content',
            provider: GoogleDrive.NAME,
            scopes: GoogleDrive.READ_SCOPES,
          ),
          Divider(),
          ListTile(
            title: Text(
              'App Permissions (Dropbox)',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CustomSwitchTile(
            permission: 'Read file content',
            provider: Dropbox.NAME,
            scopes: Dropbox.READ_CONTENT_SCOPES,
          ),
          CustomSwitchTile(
            permission: 'Read file metadata',
            provider: Dropbox.NAME,
            scopes: Dropbox.READ_METADATA_SCOPES,
          ),
          ListTile(
            title: Text('Google Drive'),
            leading: Icon(Icons.link_off),
            onTap: () {
              disconnectApp(
                'Google Drive',
                Links.GOOGLE_CONNECTED_APPS,
                "Remove Access",
              );
            },
          ),
          ListTile(
            title: Text('Dropbox'),
            leading: Icon(Icons.link_off),
            onTap: () {
              disconnectApp(
                'Dropbox',
                Links.DROPBOX_CONNECTED_APPS,
                "Disconnect",
              );
            },
          ),
        ],
      ),
    );
  }

  static void disconnectApp(String account, String link, String button) {
    showDialog(
      context: App.navigatorKey.currentState.overlay.context,
      builder: (context) => AlertDialog(
        title: Text(account),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              Text(
                'To remove Lotus LED Inventory\'s access to your $account, '
                'please follow the steps below:',
              ),
              ContactInfoTile(
                leading: Icon(Icons.filter_1),
                title: link,
                subtitle: 'Launch link',
                isLink: true,
              ),
              ListTile(
                leading: Icon(Icons.filter_2),
                contentPadding: EdgeInsets.zero,
                title: Text('Click on "Lotus LED Inventory"'),
              ),
              ListTile(
                leading: Icon(Icons.filter_3),
                contentPadding: EdgeInsets.zero,
                title: Text('Click on "$button"'),
              ),
            ],
          ),
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
  }
}
