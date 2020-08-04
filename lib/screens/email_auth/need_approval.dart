import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'email_auth.dart';

class NeedApproval extends StatelessWidget {
  final String _email;
  final bool _isAbrupt;

  NeedApproval(this._email, this._isAbrupt);

  accessNotGranted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasAccess', false);
  }

  @override
  Widget build(BuildContext context) {
    accessNotGranted();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.block,
            color: Colors.red[800],
            size: 50.0,
          ),
          SizedBox(height: 20.0),
          Text(
            'Need Approval',
            style: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20.0),
          Flexible(
            child: Text(
              _isAbrupt
                  ? 'Permission to access this app was recently removed from '
                      'the email address \"$_email\". '
                      'Please contact Lotus LED Lights for permission.'
                  : '\"$_email\" has not received permission to access this app. '
                      'Please contact Lotus LED Lights for permission.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          SizedBox(height: 20.0),
          !_isAbrupt
              ? RaisedButton(
                  child: Text('Try Again'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              : RaisedButton(
                  child: Text('Go Back To The Welcome Screen'),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => EmailAuth(),
                      ),
                      (route) => false,
                    );
                  },
                ),
        ],
      ),
    );
  }
}
