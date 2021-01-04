import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:mime_type/mime_type.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:path/path.dart' as p;


import '../../model/provider_data.dart';
import '../../model/shared_prefs.dart';
import '../help_and_support/help_and_support.dart';
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

class Home extends StatefulWidget {
  final List<FileData> files;

  Home(this.files);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with TickerProviderStateMixin {
  bool speedDialIsOpen;
  SnackBar snackBar;
  bool isLoading;
  int selectedIndex;
  FileData file;

  static Spreadsheet spread;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final List<ProviderData> _providers = [
    ProviderData(
      name: GoogleDrive.NAME,
      hasApi: true,
      dialWidget: ClipOval(
        child: Image.asset(
          GoogleDrive.GLYPH_PATH,
          scale: 35.0,
          fit: BoxFit.none,
        ),
      ),
      onTapWidget: GoogleDrive(),
    ),
    ProviderData(
      name: Dropbox.NAME,
      hasApi: true,
      dialWidget: ClipOval(
        child: Image.asset(
          Dropbox.GLYPH_PATH,
          scale: 9.0,
          fit: BoxFit.none,
        ),
      ),
      onTapWidget: Dropbox(),
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

  Widget speedDial() {
    return SpeedDial(
      onOpen: () => setState(() => speedDialIsOpen = true),
      onClose: () => setState(() => speedDialIsOpen = false),
      child: speedDialIsOpen ? Icon(Icons.close) : Icon(Icons.add),
      children: speedDialChildren(),
    );
  }

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
    setState(() => isLoading = true);

    final fileData = await _getFutureFileDataWithFilePicker();

    if (fileData != null) {
      final files = await SharedPrefs.getFiles();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => Home(files..add(fileData)),
        ),
        (route) => false,
      );
    }

    setState(() => isLoading = false);
  }

  Future<FileData> _getFutureFileDataWithFilePicker() async {
    const List<String> allowedExtensions = [
      'xlsx',
      'ods',
      'html',
      'htm',
    ];

    String filePath;
    try {
      filePath = await FilePicker.getFilePath(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
    } catch (_) {}

    if (filePath == null) {
      return null;
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

      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.files.length - 1;
    file = widget.files.isEmpty
        ? FileData.fromJson({})
        : widget.files[selectedIndex];
    speedDialIsOpen = false;
    isLoading = false;

    if (file.bytes != null) {
      spread = getSpread(file.bytes);
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await refreshReminder(() async {
          int snooze = await getSnoozeInSeconds();
          if (file.dateTime != null && snooze != 0 && file.provider != null) {
            int seconds = DateTime.now()
                .difference(
                  DateTime.parse(file.dateTime),
                )
                .inSeconds;
            if (seconds >= snooze) {
              _scaffoldKey.currentState?.showSnackBar(snackBar);
            } else {
              Future.delayed(
                Duration(seconds: snooze - seconds),
                () async {
                  await refreshReminder(() async {
                    _scaffoldKey.currentState?.removeCurrentSnackBar();
                    _scaffoldKey.currentState?.showSnackBar(snackBar);
                  });
                },
              );
            }
          }
        });
      },
    );
  }

  void _setSelectedIndex(int index) {
    setState(() {
      selectedIndex = index;
      file = widget.files[selectedIndex];
      if (file.bytes != null) {
        spread = getSpread(file.bytes);
      }
    });
  }

  void _setFile(FileData newFile) {
    setState(() {
      file = newFile;
      if (file.bytes != null) {
        spread = getSpread(file.bytes);
      }
    });
  }

  Spreadsheet getSpread(List<int> bytes) {
    Map<String, Sheet> sheets = {};

    switch (extensionFromMime(file.mimeType)) {
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

  Future<void> setSpread() async {
    FileData fileData;

    switch (file.provider) {
      case 'Google':
        {
          fileData = await GoogleDrive.download(
            name: file.name,
            provider: file.provider,
            fileId: file.id,
            mime: file.mimeType,
          );
        }
        break;

      case 'Dropbox':
        {
          fileData = await Dropbox.download(
            fileName: file.name,
            provider: file.provider,
            dropboxPath: file.id,
            mime: file.mimeType,
          );
        }
        break;
    }

    if (fileData == null) {
      Flushbar(
        message: 'Failed to refresh',
        duration: Duration(seconds: 2),
      )..show(context);
    } else {
      _setFile(fileData);
    }
  }

  Future<int> getSnoozeInSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(SharedPrefs.SNOOZE) * 60;
  }

  Future<Null> _refresh() async {
    await snooze();
    await setSpread();
    return null;
  }

  Future<void> snooze() async {
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    int snooze = await getSnoozeInSeconds();

    if (snooze != 0 && file.provider != null) {
      Future.delayed(
        Duration(seconds: snooze),
        () async {
          await refreshReminder(() async {
            _scaffoldKey.currentState?.removeCurrentSnackBar();
            _scaffoldKey.currentState?.showSnackBar(snackBar);
          });
        },
      );
    }
  }

  Future<void> refreshReminder(Future<void> Function() show) async {
    if (snackBar == null) {
      snackBar = SnackBar(
        content: Text(
          'Remember to refresh the list once in a while. The'
          ' refresh button is on the top right corner of the screen.',
        ),
        action: SnackBarAction(
          onPressed: () async {
            await snooze();
          },
          label: 'Snooze',
        ),
        duration: Duration(days: 365),
      );
    }
    await show();
  }

  Widget title() {
    String timestamp = 'Updated: ${DateFormat.Hm().format(
      DateTime.parse(file.dateTime),
    )} ${DateFormat('d MMM y').format(
      DateTime.parse(file.dateTime),
    )}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Tooltip(
          message: file.name,
          child: Text(file.name),
        ),
        Tooltip(
          message: timestamp,
          child: Text(
            timestamp,
            style: TextStyle(
              fontSize: 11.9,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> actions(bool enabled) {
    final flushbar = Flushbar(
      message: 'Please complete step one before using this button.',
      duration: Duration(seconds: 4),
    );

    Widget refresh = Tooltip(
      message: 'Refresh',
      child: IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () async {
          if (enabled) {
            await TryCatch.onWifi(() async {
              _refreshKey.currentState?.show();
            });
          } else {
            flushbar.show(context);
          }
        },
      ),
    );

    Widget search = Tooltip(
      message: 'Search',
      child: IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          if (enabled) {
            showSearch(context: context, delegate: CustomSearchDelegate());
          } else {
            flushbar.show(context);
          }
        },
      ),
    );

    return !enabled
        ? [search, refresh]
        : file.provider == null
            ? [search]
            : [search, refresh];
  }

  BottomNavigationBar bottomNavigationBar() {
    return widget.files.length < 2
        ? null
        : BottomNavigationBar(
            items: widget.files
                .map((file) => BottomNavigationBarItem(
                      icon: Icon(IconData(file.name.codeUnits.first)),
                      label: file.name,
                    ))
                .toList(),
            currentIndex: selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            onTap: _setSelectedIndex,
          );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading == true
        ? Scaffold(
            appBar: AppBar(),
            drawer: AppDrawer(),
            body: Center(
              child: CircularProgressIndicator(),
            ),
            bottomNavigationBar: bottomNavigationBar(),
          )
        : spread == null
            ? Scaffold(
                appBar: AppBar(
                  title: Text('Set-Up Screen'),
                  actions: actions(false),
                ),
                drawer: AppDrawer(),
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ListTile(
                          title: Text(
                            'Choose a file containing at least one data table '
                            'using the green "+" button in the corner below.',
                          ),
                          leading: Icon(Icons.filter_1),
                        ),
                        ListTile(
                          title: Text(
                            'Use the newly loaded page and the search button '
                            'in the top right corner to navigate through the contents '
                            'of the file.',
                          ),
                          leading: Icon(Icons.filter_2),
                        ),
                        ListTile(
                          title: Text(
                            'Press the refresh button in the top right corner '
                            'once in a while to get the lastest version of '
                            'your file.',
                          ),
                          leading: Icon(Icons.filter_3),
                        ),
                        SizedBox(height: 30.0),
                        RaisedButton(
                          padding: EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 8.0,
                          ),
                          child: ListTile(
                            title: Text(
                              'Want to have access to Lotus LED Lights Inc.\'s models, '
                              'inventory, and prices but don\'t have permission? '
                              'Click this button for help.',
                            ),
                            leading: Icon(Icons.help),
                          ),
                          onPressed: HelpAndSupport.showRequestMethods,
                        ),
                      ],
                    ),
                  ),
                ),
                floatingActionButton: speedDial(),
                bottomNavigationBar: bottomNavigationBar(),
              )
            : DefaultTabController(
                length: spread.tables.keys.length,
                child: Scaffold(
                  key: _scaffoldKey,
                  appBar: spread.tables.keys.length > 1
                      ? AppBar(
                          title: title(),
                          bottom: TabBar(
                            isScrollable: true,
                            tabs: spread.tables.keys
                                .map((e) => Tab(text: e))
                                .toList(),
                          ),
                          actions: actions(true),
                        )
                      : AppBar(
                          title: title(),
                          actions: actions(true),
                        ),
                  drawer: AppDrawer(),
                  body: RefreshIndicator(
                    key: _refreshKey,
                    onRefresh: _refresh,
                    child: TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      children: spread.tables.keys
                          .map((key) => Results(spread.tables[key].rows))
                          .toList(),
                    ),
                  ),
                  floatingActionButton: speedDial(),
                  bottomNavigationBar: bottomNavigationBar(),
                ),
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

    for (var key in HomeState.spread.tables.keys) {
      for (int i = 0; i < HomeState.spread.tables[key].rows.length; i++) {
        if (query.isNotEmpty) {
          if (i == 0) {
            filteredResults.add(HomeState.spread.tables[key].rows[i]);
          } else {
            if (queryIsMatching(
              i,
              spread: HomeState.spread,
              table: key,
            )) {
              filteredResults.add(HomeState.spread.tables[key].rows[i]);
            }
          }
        }
      }
    }

    return Results(filteredResults);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<List<dynamic>> filteredSuggestions = [[]];

    for (var key in HomeState.spread.tables.keys) {
      for (int i = 1; i < HomeState.spread.tables[key].rows.length; i++) {
        if (query.isNotEmpty) {
          if (queryIsMatching(
            i,
            spread: HomeState.spread,
            table: key,
          )) {
            filteredSuggestions[0].add(HomeState.spread.tables[key].rows[i][0]);
          }
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
