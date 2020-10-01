import 'package:flutter/material.dart';
import 'package:lotus_led_inventory/app_drawer/app_drawer.dart';
import 'package:lotus_led_inventory/screens/inventory/dropbox.dart';
import 'package:lotus_led_inventory/screens/inventory/google_drive.dart';
import 'package:lotus_led_inventory/screens/settings/custom_radio_tiles.dart';
import 'package:lotus_led_inventory/screens/settings/custom_switch_tile.dart';

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
            permission:
                'Read the content of all your ${GoogleDrive.NAME} files',
            provider: GoogleDrive.NAME,
            scopes: GoogleDrive.READ_CONTENT_SCOPES,
          ),
          CustomSwitchTile(
            permission:
                'List and search through all your ${GoogleDrive.NAME} files',
            provider: GoogleDrive.NAME,
            scopes: GoogleDrive.READ_METADATA_SCOPES,
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
            permission: 'Read the content of all your ${Dropbox.NAME} files',
            provider: Dropbox.NAME,
            scopes: Dropbox.READ_CONTENT_SCOPES,
          ),
          CustomSwitchTile(
            permission:
                'List and search through all your ${Dropbox.NAME} files',
            provider: Dropbox.NAME,
            scopes: Dropbox.READ_METADATA_SCOPES,
          ),
          Divider(),
          ListTile(
            title: Text(
              'Refresh Reminders',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CustomRadioTiles(),
          Divider(),
        ],
      ),
    );
  }
}
