import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/shared_prefs.dart';

enum Interval {
  never,
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
  bool isLoading;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      setState(() => isLoading = false);
    });
  }

  Widget customRadioTile(int snooze, Interval value) {
    Interval groupValue;

    switch (prefs.getInt(SharedPrefs.SNOOZE)) {
      case 0:
        groupValue = Interval.never;
        break;
      case 5:
        groupValue = Interval.five;
        break;
      case 10:
        groupValue = Interval.ten;
        break;
      case 15:
        groupValue = Interval.fifteen;
        break;
      case 30:
        groupValue = Interval.thirty;
        break;
    }

    return RadioListTile<Interval>(
      title: Text(snooze == 0 ? 'Never' : 'Every $snooze minutes'),
      value: value,
      groupValue: groupValue,
      onChanged: (Interval value) async {
        setState(() => isLoading = true);
        await prefs.setInt(SharedPrefs.SNOOZE, snooze);
        setState(() => isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        isLoading
            ? ListTile(
                title: Text('Send in-app refresh reminders...'),
                trailing: CircularProgressIndicator(),
              )
            : ListTile(
                title: Text('Send in-app refresh reminders...'),
              ),
        customRadioTile(0, Interval.never),
        customRadioTile(5, Interval.five),
        customRadioTile(10, Interval.ten),
        customRadioTile(15, Interval.fifteen),
        customRadioTile(30, Interval.thirty),
      ],
    );
  }
}
