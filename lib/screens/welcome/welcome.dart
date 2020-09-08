import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/shared_prefs.dart';
import 'policies.dart';
import '../splash/splash.dart';

class Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage("assets/ic_launcher_round.png"),
                      height: 150.0,
                    ),
                    SizedBox(height: 20.0),
                    Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5.0),
                    Flexible(
                      child: Text(
                        'to the Lotus LED Inventory app!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.0),
                    Flexible(
                      child: Text(
                        'View all your large tables effortlessly'
                        ' in just one simple app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.0),
                    RaisedButton(
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      child: Text('Get Started'),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setBool(SharedPrefs.GOT_STARTED, true);

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => Splash(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Policies(),
            ),
            SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
