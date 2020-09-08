import 'dart:io';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';

class TryCatch {
  static Future<void> onWifi(Future<void> Function() fun) async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ); // TODO change google.com
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        await fun();
      }
    } on SocketException catch (_) {
      showDialog(
        context: App.navigatorKey.currentState.overlay.context,
        builder: (context) => AlertDialog(
          title: Text('No Internet'),
          content: Text(
            'The action you requested could not be completed due to the absence'
            ' of Internet. Please try again when you are connected.',
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

  static Future<void> open(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Flushbar(
        message: 'Could not launch $url',
        mainButton: FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'OK',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      )..show(context);
    }
  }
}
