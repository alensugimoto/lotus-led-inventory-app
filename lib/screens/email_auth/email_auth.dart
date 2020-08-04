import 'package:flutter/material.dart';
import 'process_email.dart';

class EmailAuth extends StatefulWidget {
  @override
  _EmailAuthState createState() => _EmailAuthState();
}

class _EmailAuthState extends State<EmailAuth> {
  final TextEditingController _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20.0),
              TextFormField(
                controller: _textController,
                validator: (value) {
                  if (value.trim().isEmpty) {
                    return '*This field is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Please enter your email address',
                ),
              ),
              SizedBox(height: 20.0),
              Flexible(
                child: Text(
                  'A verification code will be sent to you '
                      'to access the contents of this app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              RaisedButton(
                child: Text('Send'),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProcessEmail(
                          _textController.text.trim(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
