//import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//
//import '../../controller/sheet_controller.dart';
//import '../../model/post_status.dart';
//import '../inventory/inventory.dart';
//
//Future<PostStatus> futureStatus;
//
//class Setup extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return StepOne();
//  }
//}
//
//class StepOne extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text('Step 1'),
//      ),
//      body: Container(
//        margin: EdgeInsets.symmetric(horizontal: 30.0),
//        child: Column(
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: <Widget>[
//            Flexible(
//              child: Text(
//                'Create a new Google Sheet or edit an existing one'
//                ' such that its first row is the only header row and its second'
//                ' column is for prices. The rest of'
//                ' the sheet is up to you.',
//                style: TextStyle(
//                  fontSize: 20.0,
//                  fontWeight: FontWeight.w400,
//                ),
//              ),
//            ),
//            SizedBox(height: 20.0),
//            Flexible(
//              child: Text(
//                'Tip: just enter numbers in the prices column, and the app will'
//                ' automatically display them in currency format.',
//                style: TextStyle(
//                  fontSize: 20.0,
//                  fontWeight: FontWeight.w400,
//                ),
//              ),
//            ),
//            SizedBox(height: 20.0),
//            RaisedButton(
//              child: Text('Next'),
//              onPressed: () async {
//                Navigator.of(context).push(
//                  MaterialPageRoute(
//                    builder: (context) => StepTwo(),
//                  ),
//                );
//              },
//            ),
//          ],
//        ),
//      ),
//    );
//  }
//}
//
//class StepTwo extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text('Step 2'),
//      ),
//      body: Container(
//        margin: EdgeInsets.symmetric(horizontal: 30.0),
//        child: Column(
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: <Widget>[
//            Flexible(
//              child: Text(
//                'Share the sheet with me (alensugimoto@gmail.com), and'
//                ' make me a \'Viewer\'.',
//                style: TextStyle(
//                  fontSize: 20.0,
//                  fontWeight: FontWeight.w400,
//                ),
//              ),
//            ),
//            SizedBox(height: 20.0),
//            Flexible(
//              child: Text(
//                'Please ignore this step if I am already a member of your sheet.',
//                style: TextStyle(
//                  fontSize: 20.0,
//                  fontWeight: FontWeight.w400,
//                ),
//              ),
//            ),
//            SizedBox(height: 20.0),
//            RaisedButton(
//              child: Text('Next'),
//              onPressed: () {
//                Navigator.of(context).push(
//                  MaterialPageRoute(
//                    builder: (context) => StepThree(),
//                  ),
//                );
//              },
//            ),
//          ],
//        ),
//      ),
//    );
//  }
//}
//
//class StepThree extends StatefulWidget {
//  @override
//  _StepThreeState createState() => _StepThreeState();
//}
//
//class _StepThreeState extends State<StepThree> {
//  final TextEditingController _textController = TextEditingController();
//  final _formKey = GlobalKey<FormState>();
//
//  List<String> getIdsFromUrl(String url) {
//    RegExp exp1 = RegExp(r"/spreadsheets/d/([a-zA-Z0-9-_]+)");
//    String spreadId = exp1.stringMatch(url)?.replaceAll('/spreadsheets/d/', '');
//
//    RegExp exp2 = RegExp(r"[#&]gid=([0-9]+)");
//    String sheetId = exp2.stringMatch(url)?.replaceAll(RegExp(r"[#&]gid="), '');
//
//    return [spreadId, sheetId];
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text('Step 3'),
//      ),
//      body: Form(
//        key: _formKey,
//        child: Container(
//          margin: EdgeInsets.symmetric(horizontal: 30.0),
//          child: Column(
//            mainAxisAlignment: MainAxisAlignment.center,
//            children: <Widget>[
//              Flexible(
//                child: Text(
//                  'Copy the link of the sheet you shared with me, and paste it'
//                  ' in the field below. You can get the link by going to your'
//                  ' phone\'s Google Drive.',
//                  style: TextStyle(
//                    fontSize: 20.0,
//                    fontWeight: FontWeight.w400,
//                  ),
//                ),
//              ),
//              TextFormField(
//                controller: _textController,
//                validator: (value) {
//                  List<String> ids = getIdsFromUrl(value.trim());
//                  if (value.trim().isEmpty) {
//                    return 'Please enter a link.';
//                  } else if (ids[0] == null) {
//                    return 'Invalid link. Please try again.';
//                  }
//                  return null;
//                },
//                decoration: InputDecoration(
//                  labelText: 'Link',
//                ),
//              ),
//              SizedBox(height: 20.0),
//              RaisedButton(
//                child: Text('Next'),
//                onPressed: () async {
//                  if (_formKey.currentState.validate()) {
//                    List<String> ids =
//                        getIdsFromUrl(_textController.text.trim());
//
//                    futureStatus = SheetController().postSheetData(
//                      spreadId: ids[0],
//                      sheetId: ids[1] ?? '',
//                      sheetName: '',
//                    );
//
//                    SharedPreferences prefs =
//                        await SharedPreferences.getInstance();
//                    prefs.setString('spreadId', ids[0]);
//                    prefs.setString('sheetId', ids[1] ?? '');
//                    prefs.setString('sheetName', '');
//
//                    Navigator.of(context).push(
//                      MaterialPageRoute(
//                        builder: (context) => StepFour(),
//                      ),
//                    );
//                  }
//                },
//              ),
//            ],
//          ),
//        ),
//      ),
//    );
//  }
//}
//
//class StepFour extends StatefulWidget {
//  @override
//  _StepFourState createState() => _StepFourState();
//}
//
//class _StepFourState extends State<StepFour> {
//  final TextEditingController _textController = TextEditingController();
//  final _formKey = GlobalKey<FormState>();
//
//  accessGranted() async {
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//    prefs.setBool('hasAccess', true);
//  }
//
//  checkIfSheetIdIsEmpty() async {
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//    if (prefs.getString('sheetId').isEmpty) {
//      prefs.setString('sheetId', '0');
//    }
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text('Step 4'),
//      ),
//      body: FutureBuilder<PostStatus>(
//        future: futureStatus,
//        builder: (context, snapshot) {
//          if (snapshot.hasData) {
//            if (snapshot.data.successful) {
//              checkIfSheetIdIsEmpty();
//
//              return Container(
//                margin: EdgeInsets.symmetric(horizontal: 30.0),
//                child: Column(
//                  mainAxisAlignment: MainAxisAlignment.center,
//                  children: <Widget>[
//                    Flexible(
//                      child: Text(
//                        'You are all set. Press the button below to view'
//                        ' your sheet.',
//                        style: TextStyle(
//                          fontSize: 20.0,
//                          fontWeight: FontWeight.w400,
//                        ),
//                      ),
//                    ),
//                    SizedBox(height: 20.0),
//                    RaisedButton(
//                      child: Text('Finish'),
//                      onPressed: () {
//                        accessGranted();
//
//                        Navigator.of(context).pushAndRemoveUntil(
//                          MaterialPageRoute(
//                            builder: (context) => Inventory(),
//                          ),
//                          (route) => false,
//                        );
//                      },
//                    ),
//                  ],
//                ),
//              );
//            } else {
//              return Form(
//                key: _formKey,
//                child: Container(
//                  margin: EdgeInsets.symmetric(horizontal: 30.0),
//                  child: Column(
//                    mainAxisAlignment: MainAxisAlignment.center,
//                    children: <Widget>[
//                      Flexible(
//                        child: Text(
//                          'Please specify the name of the sheet you want'
//                          ' to display in this app below.',
//                          style: TextStyle(
//                            fontSize: 20.0,
//                            fontWeight: FontWeight.w400,
//                          ),
//                        ),
//                      ),
//                      TextFormField(
//                        controller: _textController,
//                        validator: (value) {
//                          if (value.trim().isEmpty) {
//                            return 'Please enter the name.';
//                          } else if (!snapshot.data.sheetNames
//                              .contains(value.trim())) {
//                            return 'No such name was found.'
//                                ' Please try again.';
//                          }
//                          return null;
//                        },
//                        decoration: InputDecoration(
//                          labelText: 'Sheet Name',
//                        ),
//                      ),
//                      SizedBox(height: 20.0),
//                      RaisedButton(
//                        child: Text('Finish'),
//                        onPressed: () async {
//                          if (_formKey.currentState.validate()) {
//                            accessGranted();
//
//                            SharedPreferences prefs =
//                                await SharedPreferences.getInstance();
//
//                            futureStatus = SheetController().postSheetData(
//                              spreadId: prefs.getString('spreadId'),
//                              sheetId: prefs.getString('sheetId'),
//                              sheetName: _textController.text.trim(),
//                            );
//
//                            prefs.setString(
//                              'sheetName',
//                              _textController.text.trim(),
//                            );
//
//                            Navigator.of(context).pushAndRemoveUntil(
//                              MaterialPageRoute(
//                                builder: (context) => Inventory(),
//                              ),
//                              (route) => false,
//                            );
//                          }
//                        },
//                      ),
//                    ],
//                  ),
//                ),
//              );
//            }
//          } else if (snapshot.hasError) {
//            return Center(child: Text("${snapshot.error}"));
//          }
//          return Center(child: CircularProgressIndicator());
//        },
//      ),
//    );
//  }
//}
