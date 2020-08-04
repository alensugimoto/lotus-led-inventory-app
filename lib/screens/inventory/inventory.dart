import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import 'fitted_text.dart';
import 'results.dart';
import '../pick_file/pick_file.dart';
import '../../google_drive.dart';
import '../../dropbox.dart';

Future<SpreadsheetDecoder> futureDecoder;
TabController tabController;

class Inventory extends StatefulWidget {
  final String org;
  final Map file;

  Inventory({this.file, this.org});

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<Inventory> with TickerProviderStateMixin {
  bool speedDialIsOpen;
  bool successfulDownload;
  final GlobalKey<RefreshIndicatorState> _key =
      GlobalKey<RefreshIndicatorState>();

  Future<void> pickOtherFile() async {
    final List<String> allowedExtensions = [
      'xlsx',
      'ods',
      'gsheet',
    ];

    String filePath = await FilePicker.getFilePath(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (allowedExtensions.contains(p.extension(filePath).replaceAll('.', ''))) {
      setState(() {
        successfulDownload = true;
      });
      // TODO
    } else {
      setState(() {
        successfulDownload = false;
      });
      await FilePicker.clearTemporaryFiles();
    }
  }

  Widget menuButton() {
    return Tooltip(
      message: 'Menu',
      child: IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          // TODO
        },
      ),
    );
  }

  Widget speedDial() {
    return SpeedDial(
      onOpen: () => setState(() => speedDialIsOpen = true),
      onClose: () => setState(() => speedDialIsOpen = false),
      child: speedDialIsOpen ? Icon(Icons.close) : Icon(Icons.add),
      children: <SpeedDialChild>[
        SpeedDialChild(
          label: 'Google Drive',
          backgroundColor: Colors.red,
          child: Center(child: Text('GD')),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PickFile('GD'),
              ),
            );
          },
        ),
        SpeedDialChild(
          label: 'Dropbox',
          backgroundColor: Colors.blue,
          child: Center(child: Text('DB')),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PickFile('DB'),
              ),
            );
          },
        ),
//        SpeedDialChild(
//          label: 'Other',
//          backgroundColor: Colors.grey,
//          child: Center(child: Text('OTH')),
//          onTap: () {
//            // TODO
//          },
//        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    speedDialIsOpen = false;
    successfulDownload = true;
    tabController = TabController(length: 0, vsync: this);
    if (widget.file != null) {
      setDecoder();
    }
    futureDecoder?.then((value) {
      tabController = TabController(
        length: value.tables.keys.length,
        vsync: this,
      );
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void savePref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('org', widget.org);
    prefs.setString('file', json.encode(widget.file));
  }

  void setDecoder() {
    savePref();

    switch (widget.org) {
      case 'Google':
        {
          futureDecoder = download(
            widget.file['id'],
            widget.file['mimeType'],
          );
        }
        break;

      case 'Dropbox':
        {
          futureDecoder = DropboxChooserState().downloadTest(
            widget.file['pathLower'],
            widget.file['name'],
          );
        }
        break;

      default:
        {
          futureDecoder = null;
        }
        break;
    }
  }

  Future<Null> _refresh() async {
    setState(setDecoder);
    await Future.delayed(Duration(seconds: 2));
    return null;
  }

  Widget title() {
    return Tooltip(
      child: Text(widget.file['name']),
      message: widget.file['name'],
    );
  }

  List<Widget> actions() {
    return [
      Tooltip(
        message: 'Refresh',
        child: IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            _key.currentState.show();
          },
        ),
      ),
      Tooltip(
        message: 'Search',
        child: IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            showSearch(context: context, delegate: CustomSearchDelegate());
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return widget.file == null
        ? Scaffold(
            appBar: AppBar(
              //leading: menuButton(),
            ),
            body: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'Choose a spreadsheet for the app to read using the'
                      ' button below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
//                      SizedBox(height: 20.0),
//                      Visibility(
//                        visible: !successfulDownload,
//                        child: Flexible(
//                          child: Text(
//                            '*Your selected file does not abide by the below'
//                            ' requirements. Please try again.',
//                            textAlign: TextAlign.center,
//                            style: TextStyle(
//                              fontSize: 15.0,
//                              fontWeight: FontWeight.w400,
//                              color: Colors.red[600],
//                            ),
//                          ),
//                        ),
//                      ),
//                      SizedBox(height: 20.0),
//                      Flexible(
//                        child: Text(
//                          'The file\'s extension must be one of the following: ' +
//                              allowedExtensions.join(', ') +
//                              '.',
//                          textAlign: TextAlign.center,
//                          style: TextStyle(
//                            fontSize: 20.0,
//                            fontWeight: FontWeight.w400,
//                          ),
//                        ),
//                      ),
                ],
              ),
            ),
            floatingActionButton: speedDial(),
//            bottomNavigationBar: fileNames.length > 1
//                ? Material(
//                    color: Theme.of(context).primaryColor,
//                    child: TabBar(
//                      isScrollable: true,
//                      tabs: List.generate(fileNames.length, (index) {
//                        return Tab(text: fileNames[index].toUpperCase());
//                      }),
//                    ),
//                  )
//                : Material(),
          )
        : FutureBuilder<SpreadsheetDecoder>(
            future: futureDecoder,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                SpreadsheetDecoder decoder = snapshot.data;
                return Scaffold(
                  appBar: decoder.tables.keys.length > 1
                      ? AppBar(
                          title: title(),
                          //leading: menuButton(),
                          bottom: TabBar(
                            isScrollable: true,
                            controller: tabController,
                            tabs: decoder.tables.keys
                                .map((e) => Tab(text: e))
                                .toList(),
                          ),
                          actions: actions(),
                        )
                      : AppBar(
                          title: title(),
                          //leading: menuButton(),
                          actions: actions(),
                        ),
                  body: RefreshIndicator(
                    key: _key,
                    onRefresh: () {
                      return _refresh();
                    },
                    child: TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      controller: tabController,
                      children: decoder.tables.keys
                          .map(
                            (e) => Results(decoder.tables[e].rows),
                          )
                          .toList(),
                    ),
                  ),
                  floatingActionButton: speedDial(),
//                    bottomNavigationBar: fileNames.length > 1
//                        ? Material(
//                            color: Theme.of(context).primaryColor,
//                            child: TabBar(
//                              isScrollable: true,
//                              tabs: List.generate(fileNames.length, (index) {
//                                return Tab(
//                                    text: fileNames[index].toUpperCase());
//                              }),
//                            ),
//                          )
//                        : Material(),
                );
              } else if (snapshot.hasError) {
                return Scaffold(body: Center(child: Text("${snapshot.error}")));
              }
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          );
  }
}

class CustomSearchDelegate extends SearchDelegate<Map<String, String>> {
  bool queryIsMatching(
    int i, {
    List<int> columns,
    @required SpreadsheetDecoder decoder,
    @required String table,
  }) {
    List<String> subQueries = query.toLowerCase().trim().split(RegExp(r"\s+"));

    if (columns == null) {
      for (int j = 0; j < decoder.tables[table].maxCols; j++) {
        List<String> toRemove = [];
        String text = FittedText(
          decoder.tables[table].rows,
          row: i,
          column: j,
        ).fittedTextText().toLowerCase();

        for (String subQuery in subQueries) {
          if (text.contains(subQuery)) {
            toRemove.add(subQuery);
          }
        }
        subQueries.removeWhere((element) => toRemove.contains(element));
        if (subQueries.length == 0) {
          return true;
        }
      }
    } else {
      for (int column in columns) {
        List<String> toRemove = [];
        String text = FittedText(
          decoder.tables[table].rows,
          row: i,
          column: column,
        ).fittedTextText().toLowerCase();

        for (String subQuery in subQueries) {
          if (text.contains(subQuery)) {
            toRemove.add(subQuery);
          }
        }
        subQueries.removeWhere((element) => toRemove.contains(element));
        if (subQueries.length == 0) {
          return true;
        }
      }
    }

    if (subQueries.length == 0) {
      return true;
    }
    return false;
  }

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
    return FutureBuilder<SpreadsheetDecoder>(
      future: futureDecoder,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<List<dynamic>> filteredResults = [];
          SpreadsheetDecoder decoder = snapshot.data;
          final String table = decoder.tables.keys.length > 1
              ? decoder.tables.keys.toList()[tabController.index]
              : decoder.tables.keys.first;

          for (int i = 0; i < decoder.tables[table].maxRows; i++) {
            if (query.isNotEmpty) {
              if (i == 0) {
                filteredResults.add(decoder.tables[table].rows[i]);
              } else {
                if (queryIsMatching(
                  i,
                  decoder: decoder,
                  table: table,
                )) {
                  filteredResults.add(decoder.tables[table].rows[i]);
                }
              }
            }
          }

          return Results(filteredResults);
        } else if (snapshot.hasError) {
          return Center(child: Text("${snapshot.error}"));
        }
        return Center(child: CircularProgressIndicator());
      },
    );
//    SpreadsheetDecoder decoder = snapshot.data;
//    return DefaultTabController(
//      length: decoder.tables.keys.length,
//      child: Scaffold(
//        appBar: decoder.tables.keys.length > 1
//            ? AppBar(
//                title: Text(widget.file['name']),
//                leading: infoButton(),
//                bottom: TabBar(
//                  tabs: decoder.tables.keys.map((e) => Tab(text: e)).toList(),
//                ),
//                actions: actions(),
//              )
//            : AppBar(
//                title: Text(widget.file['name']),
//                leading: infoButton(),
//                actions: actions(),
//              ),
//        body: TabBarView(
//          children: decoder.tables.keys
//              .map(
//                (e) => RefreshIndicator(
//                  key: _key,
//                  onRefresh: () {
//                    return _refresh();
//                  },
//                  child: Results(decoder.tables[e].rows),
//                ),
//              )
//              .toList(),
//        ),
//        floatingActionButton: speedDial(),
////                    bottomNavigationBar: fileNames.length > 1
////                        ? Material(
////                            color: Theme.of(context).primaryColor,
////                            child: TabBar(
////                              isScrollable: true,
////                              tabs: List.generate(fileNames.length, (index) {
////                                return Tab(
////                                    text: fileNames[index].toUpperCase());
////                              }),
////                            ),
////                          )
////                        : Material(),
//      ),
//    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<SpreadsheetDecoder>(
      future: futureDecoder,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<List<dynamic>> filteredSuggestions = [[]];
          SpreadsheetDecoder decoder = snapshot.data;
          final String table = decoder.tables.keys.length > 1
              ? decoder.tables.keys.toList()[tabController.index]
              : decoder.tables.keys.first;

          for (int i = 1; i < decoder.tables[table].maxRows; i++) {
            if (query.isNotEmpty) {
              if (queryIsMatching(
                i,
                decoder: decoder,
                table: table,
              )) {
                filteredSuggestions[0].add(decoder.tables[table].rows[i][0]);
              }
            }
          }

          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: filteredSuggestions[0].length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    FittedText(
                      filteredSuggestions,
                      row: 0,
                      column: index,
                    ).fittedTextText(),
                  ),
                  onTap: () {
                    query = FittedText(
                      filteredSuggestions,
                      row: 0,
                      column: index,
                    ).fittedTextText();
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
