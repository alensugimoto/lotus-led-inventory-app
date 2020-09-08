import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:lotus_led_inventory/model/provider_data.dart';
import 'package:lotus_led_inventory/screens/help_and_support/help_and_support.dart';
import 'package:mime_type/mime_type.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:path/path.dart' as p;

import '../../app.dart';
import '../../model/try_catch.dart';
import '../../app_drawer/app_drawer.dart';
import 'fitted_text.dart';
import 'results.dart';
import 'google_drive.dart';
import 'dropbox.dart';
import '../../model/file_data.dart';
import '../../model/spreadsheet.dart';
import '../../model/sheet.dart';

class Inventory extends StatefulWidget {
  final FileData file;

  Inventory(this.file);

  @override
  InventoryState createState() => InventoryState();
}

class InventoryState extends State<Inventory> with TickerProviderStateMixin {
  bool speedDialIsOpen;
  String dateTime;
  Flushbar flushbar;
  int refreshSeconds = 300;
  final _key = GlobalKey<RefreshIndicatorState>();
  static Spreadsheet spread;
  static TabController tabController;

  final List<ProviderData> _providers = [
    ProviderData(
      name: 'Google Drive',
      hasApi: true,
      dialWidget: ClipOval(
        child: Image.asset(
          "assets/DriveGlyph_Color.png",
          scale: 35.0,
          fit: BoxFit.none,
        ),
      ),
      onTapWidget: GoogleDrive(
        fileName: 'Google Drive',
        fileId: 'root',
      ),
    ),
    ProviderData(
      name: 'Dropbox',
      hasApi: true,
      dialWidget: ClipOval(
        child: Image.asset(
          "assets/DropboxGlyph_Blue.png",
          scale: 9.0,
          fit: BoxFit.none,
        ),
      ),
      onTapWidget: Dropbox(
        fileName: 'Dropbox',
        filePath: '',
      ),
    ),
    ProviderData(
      name: 'Device',
      hasApi: false,
      dialWidget: Icon(
        Icons.storage,
        color: Colors.grey,
      ),
    ),
  ];

  List<SpeedDialChild> speedDialChildren() {
    return _providers.map(
      (providerData) {
        return SpeedDialChild(
          child: Center(
            child: Tooltip(
              message: 'Add from ${providerData.name}',
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: providerData.dialWidget,
              ),
            ),
          ),
          onTap: () async {
            if (providerData.hasApi) {
              await _pickFileWithApi(providerData);
            } else {
              await _pickFileWithFilePicker();
            }
          },
        );
      },
    ).toList();
  }

  Future<void> _pickFileWithApi(
    ProviderData providerData,
  ) async {
    await TryCatch.onWifi(() async {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => providerData.onTapWidget,
        ),
      );
    });
  }

  Future<void> _pickFileWithFilePicker() async {
    final futureFileData = _getFutureFileData();

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
  }

  Future<FileData> _getFutureFileData() async {
    const List<String> allowedExtensions = [
      'xlsx',
      'ods',
      'html',
      'htm',
    ];

    final String filePath = await FilePicker.getFilePath(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (filePath == null) {
      return widget.file;
    }

    final String ext = p.extension(filePath).replaceAll('.', '');

    if (allowedExtensions.contains(ext)) {
      final bytes = await File(filePath).readAsBytes();
      final fileData = FileData(
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
        context: App.navigatorKey.currentState.overlay.context,
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

  Widget speedDial() {
    return SpeedDial(
      onOpen: () => setState(() => speedDialIsOpen = true),
      onClose: () => setState(() => speedDialIsOpen = false),
      child: speedDialIsOpen ? Icon(Icons.close) : Icon(Icons.add),
      children: speedDialChildren(),
    );
  }

  @override
  void initState() {
    super.initState();

    speedDialIsOpen = false;
    dateTime = widget.file.dateTime;

    if (widget.file.bytes != null) {
      spread = getSpread(
        widget.file.bytes,
      );
    }

    if (spread != null) {
      tabController = TabController(
        length: spread.tables.keys.length,
        vsync: this,
      );
    } else {
      tabController = TabController(
        length: 0,
        vsync: this,
      );
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

    switch (extensionFromMime(widget.file.mimeType)) {
      case 'htm':
      case 'html':
        {
          final document = parse(bytes);
          final tables = document.getElementsByTagName('table');
          for (int tblIndex = 0; tblIndex < tables.length; tblIndex++) {
            final rows = tables[tblIndex].getElementsByTagName('tr');
            List<Map<int, dynamic>> normalCells = [];
            List<List<dynamic>> normalRows = [];
            for (var _ in rows) {
              normalCells.add({});
            }
            for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
              final cells = rows[rowIndex].querySelectorAll('td, th');
              for (int colIndex = 0, offset = 0;
                  colIndex < cells.length;
                  colIndex++) {
                while (normalCells[rowIndex].containsKey(colIndex + offset)) {
                  offset++;
                }
                final cell = cells[colIndex];
                final colspan = int.parse(cell.attributes['colspan'] ?? '1');
                final rowspan = int.parse(cell.attributes['rowspan'] ?? '1');
                for (int i = 0; i < colspan; i++) {
                  for (int j = 0; j < rowspan; j++) {
                    normalCells[rowIndex + j][colIndex + offset + i] =
                        cell.text;
                  }
                }
              }
              normalRows.add(normalCells[rowIndex].values.toList());
            }
            sheets['$tblIndex'] = Sheet(normalRows);
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
    switch (widget.file.provider) {
      case 'Google':
        {
          download(
            name: widget.file.name,
            provider: widget.file.provider,
            fileId: widget.file.id,
            mime: widget.file.mimeType,
          ).then((value) {
            setState(() {
              spread = getSpread(value.bytes);
              dateTime = value.dateTime;
            });
          });
        }
        break;

      case 'Dropbox':
        {
          Dropbox.download(
            fileName: widget.file.name,
            provider: widget.file.provider,
            dropboxPath: widget.file.id,
            mime: widget.file.mimeType,
          ).then((value) {
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
        message: 'Remember to refresh the list once in a while. The'
            ' refresh button is on the top right corner of the screen.',
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
    String timestamp = '${DateFormat(
      'MMM d, y',
    ).format(DateTime.parse(dateTime))} at ${DateFormat(
      'kk:mm',
    ).format(DateTime.parse(dateTime))}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Tooltip(message: widget.file.name, child: Text(widget.file.name)),
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
          await TryCatch.onWifi(() async {
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

    return widget.file.provider == null ? [search] : [search, refresh];
  }

  @override
  Widget build(BuildContext context) {
    return spread == null
        ? Scaffold(
            appBar: AppBar(),
            drawer: AppDrawer(),
            body: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Choose a file containing at least one data table '
                      'using the green button in the corner.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 30.0),
                    RaisedButton(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Want to read Lotus LED Lights\' inventory but '
                        'don\'t have permission? Click this button for help.',
                      ),
                      onPressed: HelpAndSupport.showRequestMethods,
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: speedDial(),
          )
        : Scaffold(
            appBar: spread.tables.keys.length > 1
                ? AppBar(
                    title: title(),
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
                    actions: actions(),
                  ),
            drawer: AppDrawer(),
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
    List<String> subQueries = query
        .replaceAll(RegExp(r"[\u201d\u201c]"), "\"")
        .replaceAll(RegExp(r"[\u2018\u2019]"), "\'")
        .toLowerCase()
        .trim()
        .split(RegExp(r"\s+"));

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
    final String table = InventoryState.spread.tables.keys.length > 1
        ? InventoryState.spread.tables.keys
            .toList()[InventoryState.tabController.index]
        : InventoryState.spread.tables.keys.first;

    for (int i = 0; i < InventoryState.spread.tables[table].rows.length; i++) {
      if (query.isNotEmpty) {
        if (i == 0) {
          filteredResults.add(InventoryState.spread.tables[table].rows[i]);
        } else {
          if (queryIsMatching(
            i,
            spread: InventoryState.spread,
            table: table,
          )) {
            filteredResults.add(InventoryState.spread.tables[table].rows[i]);
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
    final String table = InventoryState.spread.tables.keys.length > 1
        ? InventoryState.spread.tables.keys
            .toList()[InventoryState.tabController.index]
        : InventoryState.spread.tables.keys.first;

    for (int i = 1; i < InventoryState.spread.tables[table].rows.length; i++) {
      if (query.isNotEmpty) {
        if (queryIsMatching(
          i,
          spread: InventoryState.spread,
          table: table,
        )) {
          filteredSuggestions[0]
              .add(InventoryState.spread.tables[table].rows[i][0]);
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
