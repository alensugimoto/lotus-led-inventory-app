import 'package:flutter/material.dart';
import 'package:lotus_led_inventory/app_drawer/app_drawer.dart';
import 'package:lotus_led_inventory/model/links.dart';

import '../../app.dart';
import 'contact_info_tile.dart';

class HelpAndSupport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help and Support'),
      ),
      drawer: AppDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: Icon(Icons.vpn_key),
            title: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'View Lotus LED Lights\' Models, Inventory, and Prices',
              ),
            ),
            onTap: showRequestMethods,
          ),
          ListTile(
            leading: Icon(Icons.contacts),
            title: Text('Contact Developer'),
            onTap: _showContactInfo,
          ),
        ],
      ),
    );
  }

  void _showContactInfo() {
    showDialog(
      context: App.navigatorKey.currentState.overlay.context,
      builder: (context) => AlertDialog(
        title: Text('Contact Developer'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              ContactInfoTile(
                subtitle: 'Name',
                title: 'Alen Sugimoto',
                isLink: false,
              ),
              ContactInfoTile(
                subtitle: 'Email Address',
                title: 'alensugimoto@gmail.com',
                isLink: false,
              ),
              ContactInfoTile(
                subtitle: 'LinkedIn',
                title: Links.DEVELOPER_LINKEDIN,
                isLink: true,
              ),
              ContactInfoTile(
                subtitle: 'GitHub',
                title: Links.DEVELOPER_GITHUB,
                isLink: true,
              ),
              ContactInfoTile(
                subtitle: 'Website',
                title: Links.DEVELOPER_WEBSITE,
                isLink: true,
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

  static void showRequestMethods() {
    showDialog(
      context: App.navigatorKey.currentState.overlay.context,
      builder: (context) => AlertDialog(
        title: Text('View Lotus LED Lights\' Models, Inventory, and Prices'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              Text(
                'To request access to Lotus LED Lights\' models, inventory, '
                'and prices, please do one of the following using your work '
                'email address:',
              ),
              ContactInfoTile(
                subtitle: 'Send a request via email',
                title: 'support@lotusledlights.com',
                isLink: false,
              ),
              Text('- OR -'),
              ContactInfoTile(
                subtitle: 'Send a request via link',
                title: Links.LOTUS_INVENTORY,
                isLink: true,
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
