import 'package:flutter/material.dart';

class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage("assets/ic_launcher_round.png"),
              height: 35.0,
            ),
            SizedBox(height: 20.0),
            Icon(Icons.arrow_downward),
            SizedBox(height: 20.0),
            Image(
              image: AssetImage("assets/ic_launcher_round.png"),
              height: 35.0,
            ),
            SizedBox(height: 20.0),
            RaisedButton(
              child: Text('Start Setup'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Example(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
