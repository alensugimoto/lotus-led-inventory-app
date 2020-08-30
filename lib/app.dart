import 'package:flutter/material.dart';
import 'screens/splash/splash.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lotus LED Inventory',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Splash(),
    );
  }
}
