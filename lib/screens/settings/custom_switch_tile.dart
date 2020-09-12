import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:lotus_led_inventory/screens/inventory/dropbox.dart';
import 'package:lotus_led_inventory/screens/inventory/google_drive.dart';

class CustomSwitchTile extends StatefulWidget {
  final String permission;
  final List<String> scopes;
  final String provider;

  CustomSwitchTile({
    @required this.permission,
    @required this.provider,
    @required this.scopes,
  });

  @override
  _CustomSwitchTileState createState() => _CustomSwitchTileState();
}

class _CustomSwitchTileState extends State<CustomSwitchTile> {
  bool isSelected;
  bool isLoading;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    isSelected = false;
    (widget.provider == GoogleDrive.NAME
            ? GoogleDrive.getTokenFromStorage(widget.scopes)
            : Dropbox.getTokenFromStorage(widget.scopes))
        .then((isSelected) => setState(() {
              isLoading = false;
              this.isSelected = isSelected;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? ListTile(title: Center(child: CircularProgressIndicator()))
        : SwitchListTile(
            value: isSelected,
            title: Text(widget.permission),
            onChanged: (bool getToken) async {
              setState(() => isLoading = true);

              if (getToken) {
                void Function() onError = () {
                  Flushbar(
                    message: 'We were unable to get permission',
                    duration: Duration(seconds: 3),
                  )..show(context);
                };

                isSelected = await (widget.provider == GoogleDrive.NAME
                    ? GoogleDrive.getToken(widget.scopes, onError)
                    : Dropbox.getToken(widget.scopes, onError));
              } else {
                isSelected = await (widget.provider == GoogleDrive.NAME
                    ? GoogleDrive.revokeToken(widget.scopes)
                    : Dropbox.revokeToken(widget.scopes));
              }

              setState(() => isLoading = false);
            },
          );
  }
}
