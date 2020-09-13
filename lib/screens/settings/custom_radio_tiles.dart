import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:lotus_led_inventory/model/shared_prefs.dart';
import 'package:lotus_led_inventory/screens/inventory/dropbox.dart';
import 'package:lotus_led_inventory/screens/inventory/google_drive.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Interval {
  five,
  ten,
  fifteen,
  thirty,
}

class CustomRadioTiles extends StatefulWidget {
  @override
  _CustomRadioTilesState createState() => _CustomRadioTilesState();
}

class _CustomRadioTilesState extends State<CustomRadioTiles> {
  bool isSelected;
  bool isLoading;
  Interval _interval;

  @override
  void initState() {
    super.initState();
    isLoading = false;
    isSelected = false;
    _interval = Interval.five;
  }

  Widget customRadioTile(int snooze, Interval value) {
    return RadioListTile<Interval>(
      title: Text('$snooze minutes'),
      value: Interval.five,
      groupValue: _interval,
      onChanged: (Interval value) async {
        setState(() {
          isLoading = true;
          _interval = value;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(SharedPrefs.SNOOZE, 5);

        setState(() => isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? ListTile(title: Center(child: CircularProgressIndicator()))
        : Column(
            children: [
              RadioListTile<Interval>(
                title: Text('5 minutes'),
                value: Interval.five,
                groupValue: _interval,
                onChanged: (Interval value) async {
                  setState(() {
                    isLoading = true;
                    _interval = value;
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt(SharedPrefs.SNOOZE, 5);

                  setState(() => isLoading = false);
                },
              ),
              RadioListTile<Interval>(
                title: Text('10 minutes'),
                value: Interval.ten,
                groupValue: _interval,
                onChanged: (Interval value) async {
                  setState(() {
                    isLoading = true;
                    _interval = value;
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt(SharedPrefs.SNOOZE, 5);

                  setState(() => isLoading = false);
                },
              ),
            ],
          );
  }
}
