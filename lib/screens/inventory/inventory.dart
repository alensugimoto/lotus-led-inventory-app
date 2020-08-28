import 'dart:io';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../../app.dart';
import '../../wi_fi.dart';
import 'fitted_text.dart';
import 'results.dart';
import '../pick_file/pick_file.dart';
import '../pick_file/google_drive.dart' as google;
import '../pick_file/dropbox.dart' as dropbox;
import '../../model/file_data.dart';
import '../../model/spreadsheet.dart';
import '../../model/sheet.dart';

Spreadsheet spread;
TabController tabController;

class Inventory extends StatefulWidget {
  final FileData file;

  Inventory([this.file]);

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<Inventory> with TickerProviderStateMixin {
  bool speedDialIsOpen;
  FileData file;
  String dateTime;
  Flushbar flushbar;
  int refreshSeconds = 10;
  final GlobalKey<RefreshIndicatorState> _key =
      GlobalKey<RefreshIndicatorState>();

  Future<FileData> pickOtherFile() async {
    final List<String> allowedExtensions = [
      'xlsx',
      'ods',
      'html',
      'htm',
    ];
    String ext;
    String filePath;

    filePath = await FilePicker.getFilePath(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (filePath == null) {
      return widget.file;
    }

    ext = p.extension(filePath).replaceAll('.', '');

    if (allowedExtensions.contains(ext)) {
      var bytes = await File(filePath).readAsBytes();
      var fileData = FileData(
        provider: null,
        name: p.basename(filePath),
        id: null,
        mimeType: mimeFromExtension(ext),
        dateTime: DateTime.now().toIso8601String(),
        bytes: bytes,
      );
      await fileData.save();

      return fileData;
    } else {
      showDialog(
        context: navigatorKey.currentState.overlay.context,
        builder: (context) => AlertDialog(
          title: Text('Failed to Read File'),
          content: Text(
            'The chosen file couldn\'t be read. Make sure its extension is'
            ' one of the following: ${allowedExtensions.join(', ')}.',
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );

      return widget.file;
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
          onTap: () async {
            await WiFi().tryCatch(() async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PickFile('GD'),
                ),
              );
            });
          },
        ),
        SpeedDialChild(
          label: 'Dropbox',
          backgroundColor: Colors.blue,
          child: Center(child: Text('DB')),
          onTap: () async {
            await WiFi().tryCatch(() async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PickFile('DB'),
                ),
              );
            });
          },
        ),
        SpeedDialChild(
          label: 'Other',
          backgroundColor: Colors.grey,
          child: Center(child: Text('OTH')),
          onTap: () {
            var futureFileData = pickOtherFile();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => FutureBuilder(
                  future: futureFileData,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Inventory(snapshot.data);
                    } else if (snapshot.hasError) {
                      return Scaffold(
                        body: Center(
                          child: Text("${snapshot.error}"),
                        ),
                      );
                    }
                    return Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    speedDialIsOpen = false;
    file = widget.file;
    spread = file?.bytes == null ? file?.bytes : getSpread(file.bytes);
    dateTime = file?.dateTime;
    if (spread != null) {
      tabController = TabController(
        length: spread.tables.keys.length,
        vsync: this,
      );
    } else {
      tabController = TabController(length: 0, vsync: this);
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showRefreshReminder(),
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Spreadsheet getSpread(List<int> bytes) {
    Map<String, Sheet> sheets = {};

    switch (extensionFromMime(file.mimeType)) {
      case 'htm':
      case 'html':
        {
          var document = parse(bytes);
          var tables = document.getElementsByTagName('table');
          for (int tblIndex = 0; tblIndex < tables.length; tblIndex++) {
            var rows = tables[tblIndex].getElementsByTagName('tr');
            List<Map<int, dynamic>> listOfMaps = [];
            List<List<dynamic>> listOfLists = [];
            for (var _ in rows) {
              listOfMaps.add({});
            }
            for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
              var cells = rows[rowIndex].querySelectorAll('td, th');
              for (int colIndex = 0, offset = 0;
                  colIndex < cells.length;
                  colIndex++) {
                while (listOfMaps[rowIndex].containsKey(colIndex + offset)) {
                  offset++;
                }
                var cell = cells[colIndex];
                int colspan = int.parse(cell.attributes['colspan'] ?? '1');
                int rowspan = int.parse(cell.attributes['rowspan'] ?? '1');
                for (int i = 0; i < colspan; i++) {
                  for (int j = 0; j < rowspan; j++) {
                    listOfMaps[rowIndex + j][colIndex + offset + i] = cell.text;
                  }
                }
              }
              listOfLists.add(listOfMaps[rowIndex].values.toList());
            }
            sheets['$tblIndex'] = Sheet(listOfLists);
          }
        }
        break;

      default:
        {
          var decoder = SpreadsheetDecoder.decodeBytes(bytes);
          for (var key in decoder.tables.keys) {
            sheets[key] = Sheet(decoder.tables[key].rows);
          }
        }
        break;
    }

    return Spreadsheet(sheets);
  }

  void setSpread() {
    switch (file.provider) {
      case 'Google':
        {
          google
              .download(
            name: file.name,
            provider: file.provider,
            fileId: file.id,
            mime: file.mimeType,
          )
              .then((value) {
            setState(() {
              spread = getSpread(value.bytes);
              dateTime = value.dateTime;
            });
          });
        }
        break;

      case 'Dropbox':
        {
          dropbox
              .download(
            fileName: file.name,
            provider: file.provider,
            dropboxPath: file.id,
            mime: file.mimeType,
          )
              .then((value) {
            setState(() {
              spread = getSpread(value.bytes);
              dateTime = value.dateTime;
            });
          });
        }
        break;
    }
  }

  Future<Null> _refresh() async {
    setSpread();
    await Future.delayed(Duration(seconds: 2));

    if (flushbar?.isShowing() ?? false) {
      await flushbar.dismiss();
    }
    Future.delayed(
      Duration(seconds: refreshSeconds),
      showRefreshReminder,
    );

    return null;
  }

  void showRefreshReminder() {
    if (flushbar == null) {
      flushbar = Flushbar(
        message: 'Remember to refresh the list once in a while.',
        mainButton: FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Dismiss',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      );
    }
    if (dateTime != null) {
      int seconds = DateTime.now()
          .difference(
            DateTime.parse(dateTime),
          )
          .inSeconds;
      if (seconds >= refreshSeconds) {
        flushbar.show(context);
      } else {
        Future.delayed(
          Duration(seconds: refreshSeconds - seconds),
          showRefreshReminder,
        );
      }
    }
  }

  Widget title() {
    String timestamp = 'Last Refreshed: ${DateFormat(
      'kk:mm:ss EEE d MMM',
    ).format(DateTime.parse(dateTime))}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Tooltip(message: file.name, child: Text(file.name)),
        Visibility(
          visible: true,
          child: Tooltip(
            message: timestamp,
            child: Text(
              timestamp,
              style: TextStyle(
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> actions() {
    Widget refresh = Tooltip(
      message: 'Refresh',
      child: IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () async {
          await WiFi().tryCatch(() async {
            _key.currentState.show();
          });
        },
      ),
    );

    Widget search = Tooltip(
      message: 'Search',
      child: IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          showSearch(context: context, delegate: CustomSearchDelegate());
        },
      ),
    );

    return file.provider == null ? [search] : [search, refresh];
  }

  Widget drawer(String text) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Drawer Header'),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            title: Text('Item 1'),
            onTap: () {
              // Update the state of the app.
              // ...
            },
          ),
          ListTile(
            title: Text('Item 2'),
            onTap: () {
              // Update the state of the app.
              // ...
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return spread == null
        ? Scaffold(
            appBar: AppBar(
                //leading: menuButton(),
                ),
            //drawer: drawer(''), TODO
            body: Center(
              child: Container(
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
        : Scaffold(
            appBar: spread.tables.keys.length > 1
                ? AppBar(
                    title: title(),
                    //leading: menuButton(),
                    bottom: TabBar(
                      isScrollable: true,
                      controller: tabController,
                      tabs:
                          spread.tables.keys.map((e) => Tab(text: e)).toList(),
                    ),
                    actions: actions(),
                  )
                : AppBar(
                    title: title(),
                    //leading: menuButton(),
                    actions: actions(),
                  ),
            //drawer: drawer(file.name + ' (last refreshed: ?)'), TODO
            body: RefreshIndicator(
              key: _key,
              onRefresh: () {
                return _refresh();
              },
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                controller: tabController,
                children: spread.tables.keys
                    .map(
                      (e) => Results(spread.tables[e].rows),
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
  }
}

class CustomSearchDelegate extends SearchDelegate<Map<String, String>> {
  bool queryIsMatching(
    int i, {
    List<int> columns,
    @required Spreadsheet spread,
    @required String table,
  }) {
    List<String> subQueries = query.toLowerCase().trim().split(RegExp(r"\s+"));

    if (columns == null) {
      for (int j = 0; j < spread.tables[table].rows[0].length; j++) {
        List<String> toRemove = [];
        String text = FittedText(
          spread.tables[table].rows,
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
          spread.tables[table].rows,
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
    List<List<dynamic>> filteredResults = [];
    final String table = spread.tables.keys.length > 1
        ? spread.tables.keys.toList()[tabController.index]
        : spread.tables.keys.first;

    for (int i = 0; i < spread.tables[table].rows.length; i++) {
      if (query.isNotEmpty) {
        if (i == 0) {
          filteredResults.add(spread.tables[table].rows[i]);
        } else {
          if (queryIsMatching(
            i,
            spread: spread,
            table: table,
          )) {
            filteredResults.add(spread.tables[table].rows[i]);
          }
        }
      }
    }

    return Results(filteredResults);
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
    List<List<dynamic>> filteredSuggestions = [[]];
    final String table = spread.tables.keys.length > 1
        ? spread.tables.keys.toList()[tabController.index]
        : spread.tables.keys.first;

    for (int i = 1; i < spread.tables[table].rows.length; i++) {
      if (query.isNotEmpty) {
        if (queryIsMatching(
          i,
          spread: spread,
          table: table,
        )) {
          filteredSuggestions[0].add(spread.tables[table].rows[i][0]);
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
  }
}
