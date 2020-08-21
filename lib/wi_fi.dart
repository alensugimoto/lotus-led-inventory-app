import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';

class WiFi {
  Future<void> tryCatch(Future<void> Function() fun) async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ); // TODO change google.com
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        await fun();
      }
    } on SocketException catch (_) {
      showDialog(
        context: navigatorKey.currentState.overlay.context,
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
}
