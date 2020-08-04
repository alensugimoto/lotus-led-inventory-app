import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/sheet_controller.dart';
import '../../model/sheet.dart';
import '../email_auth/need_approval.dart';
import 'results.dart';

Future<Sheet> futureSheet;

class Invent extends StatefulWidget {
  @override
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Invent> {
  final GlobalKey<RefreshIndicatorState> _key =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    futureSheet = SheetController().getSheetData();
  }

  Future<Null> _refresh() async {
    setState(() {
      futureSheet = SheetController().getSheetData();
    });

    await Future.delayed(Duration(seconds: 4));
    return null;
  }

  void _recheckUserEmail(AsyncSnapshot<Sheet> snapshot) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userEmail = prefs.getString('email');

    bool _isStillMember = false;

    for (int i = 0; i < snapshot.data.members.length; i++) {
      if (snapshot.data.members[i] == userEmail) {
        _isStillMember = true;
        break;
      }
    }

    if (!_isStillMember) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => Scaffold(body: NeedApproval(userEmail, true)),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventory and Pricing"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _key.currentState.show();
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: CustomSearchDelegate());
            },
          ),
        ],
      ),
      body: FutureBuilder<Sheet>(
        future: futureSheet,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RefreshIndicator(
              key: _key,
              onRefresh: () {
                //_recheckUserEmail(snapshot);
                return _refresh();
              },
              child: Results(snapshot.data.lights, snapshot),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<Map<String, String>> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<Sheet>(
      future: futureSheet,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<Map<String, String>> filteredResults = [];

          for (int i = 0; i < snapshot.data.lights.length; i++) {
            if (query.isNotEmpty &&
                snapshot.data.lights[i][snapshot.data.headers[0]]
                    .toLowerCase()
                    .contains(query.toLowerCase().trim())) {
              filteredResults.add(snapshot.data.lights[i]);
            }
          }
          return Results(filteredResults, snapshot);
        } else if (snapshot.hasError) {
          return Center(child: Text("${snapshot.error}"));
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<Sheet>(
      future: futureSheet,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<String> filteredSuggestions = [];

          for (int i = 0; i < snapshot.data.lights.length; i++) {
            if (query.isNotEmpty &&
                snapshot.data.lights[i][snapshot.data.headers[0]]
                    .toLowerCase()
                    .contains(query.toLowerCase().trim())) {
              filteredSuggestions
                  .add(snapshot.data.lights[i][snapshot.data.headers[0]]);
            }
          }

          return Container(
            padding: EdgeInsets.all(5.0),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: filteredSuggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    filteredSuggestions[index],
                  ),
                  onTap: () {
                    query = filteredSuggestions[index];
                    showResults(context);
                  },
                );
              },
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text("${snapshot.error}"));
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
