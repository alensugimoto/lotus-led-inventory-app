import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lotus_led_inventory/model/links.dart';

import '../../model/try_catch.dart';

class Policies extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'By using this app, you are agreeing to our\n',
        style: TextStyle(
          color: Colors.black,
        ),
        children: [
          TextSpan(
            text: 'Terms & Conditions',
            style: TextStyle(
              color: Colors.blue,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                await TryCatch.open(context, Links.TERMS_AND_CONDITIONS);
              },
          ),
          TextSpan(
            text: ' and ',
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: Colors.blue,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                await TryCatch.open(context, Links.PRIVACY_POLICY);
              },
          ),
        ],
      ),
    );
  }
}
