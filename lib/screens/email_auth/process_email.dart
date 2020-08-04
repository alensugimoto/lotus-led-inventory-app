import 'package:flutter/material.dart';
import 'dart:math';

import '../../controller/sheet_controller.dart';
import '../../model/sheet.dart';
import 'email_verif.dart';
import 'need_approval.dart';

class ProcessEmail extends StatefulWidget {
  final String _email;

  ProcessEmail(this._email);

  @override
  _ProcessEmailState createState() => _ProcessEmailState();
}

class _ProcessEmailState extends State<ProcessEmail> {
  final String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
  final Random _rnd = Random.secure();

  Future<Sheet> futureSheet;

  @override
  void initState() {
    super.initState();
    futureSheet = SheetController().getSheetData();
  }

  String getRandomString(int length) => String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Sheet>(
        future: futureSheet,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            bool _isMember = false;

            for (int i = 0; i < snapshot.data.members.length; i++) {
              if (snapshot.data.members[i] == widget._email) {
                _isMember = true;
                break;
              }
            }

            if (_isMember) {
              String code = getRandomString(6);
              //SheetController().sendEmail(widget._email, code);
              return EmailVerif(widget._email, code);
            } else {
              return NeedApproval(widget._email, false);
            }
          } else if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
