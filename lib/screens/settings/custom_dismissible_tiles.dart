import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/shared_prefs.dart';

class CustomDismissibleTiles extends StatefulWidget {
  @override
  _CustomDismissibleTilesState createState() => _CustomDismissibleTilesState();
}

class _CustomDismissibleTilesState extends State<CustomDismissibleTiles> {
  bool isLoading;
  SharedPreferences prefs;
  String linkOption;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      setState(() {
        isLoading = false;
        linkOption = prefs.getString(SharedPrefs.LINK_OPTION);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            linkOption == null
                ? ListTile(
                    title: Text(
                      "Nothing set as default",
                    ),
                  )
                : ListTile(
                    title: Text(
                      "You've chosen to $linkOption links "
                      "in the \"Home\" screen by default",
                    ),
                  ),
            OutlinedButton(
              onPressed: linkOption == null
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      await prefs.remove(SharedPrefs.LINK_OPTION);
                      setState(() {
                        isLoading = false;
                        linkOption = null;
                      });
                    },
              child: Text(
                'Clear defaults',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        Center(
          child: Visibility(
            visible: isLoading,
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}
