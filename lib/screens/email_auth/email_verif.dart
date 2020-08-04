import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../inventory/inventory.dart';

class EmailVerif extends StatelessWidget {
  final String _email;
  final String _code;

  EmailVerif(this._email, this._code);

  final _formKey = GlobalKey<FormState>();

  accessGranted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasAccess', true);
    prefs.setString('email', _email);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.mail,
              color: Colors.green[800],
              size: 50.0,
            ),
            SizedBox(height: 20.0),
            Text(
              'Check Your Email',
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.0),
            Flexible(
              child: Text(
                'To confirm your email address, enter the verification code '
                'that was sent to \"$_email\".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            TextFormField(
              validator: (value) {
                if (value.trim().isEmpty) {
                  return 'Please enter code';
                } else if (value.trim() != _code) {
                  return 'Invalid code';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Code',
              ),
            ),
            SizedBox(height: 5.0),
            RaisedButton(
              child: Text('Continue'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  accessGranted();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => Inventory(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            SizedBox(height: 20.0),
            Flexible(
              child: Text(
                'Did not get an email?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            RaisedButton(
              child: Text('Try Again'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
