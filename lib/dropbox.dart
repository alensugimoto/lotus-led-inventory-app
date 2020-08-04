import 'dart:io';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:inventory/screens/inventory/inventory.dart';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:dropbox_client/dropbox_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

const String dropbox_clientId = 'flutter-dropbox';
const String dropbox_key = '3ss8bafc9ujv2hx';
const String dropbox_secret = 'oysrishvqq9wff5';

final List<String> allowedExtensions = [
  'xlsx',
  'ods',
];

class DropboxChooser extends StatefulWidget {
  final String filePath;
  final String fileName;

  DropboxChooser({
    @required this.filePath,
    @required this.fileName,
  });

  @override
  DropboxChooserState createState() => DropboxChooserState();
}

class DropboxChooserState extends State<DropboxChooser> {
  String accessToken;
  Future<List> futureFiles;

  @override
  void initState() {
    super.initState();
    initDropbox();
    futureFiles = list(
      //filterWithQuery: false,
      filter: widget.filePath,
    );
  }

  Future initDropbox() async {
    await Dropbox.init(dropbox_clientId, dropbox_key, dropbox_secret);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('dropboxAccessToken');

    setState(() {});
  }

  Future<bool> checkAuthorized(bool authorize) async {
    final token = await Dropbox.getAccessToken();
    if (token != null) {
      if (accessToken == null || accessToken.isEmpty) {
        accessToken = token;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('dropboxAccessToken', accessToken);
      }
      return true;
    }
    if (authorize) {
      if (accessToken != null && accessToken.isNotEmpty) {
        await Dropbox.authorizeWithAccessToken(accessToken);
        final token = await Dropbox.getAccessToken();
        if (token != null) {
          return true;
        }
      } else {
        await Dropbox.authorize();
        final token = await Dropbox.getAccessToken();
        if (token != null) {
          return true;
        }
      }
    }
    return false;
  }

  Future unlink() async {
    await deleteAccessToken();
    await Dropbox.unlink();
  }

  Future deleteAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('dropboxAccessToken');

    setState(() {
      accessToken = null;
    });
  }

  Future<List> list({
    //@required bool filterWithQuery,
    @required String filter,
  }) async {
    if (await checkAuthorized(true)) {
      final List result = await Dropbox.listFolder(filter);
//    if (filterWithQuery) {
//      for (int i = 0; i < result.length; i++) {
//        if (result[i]['filesize'] == null) {
//          result.addAll(await list(
//            filter: result[i]['pathLower'],
//            filterWithQuery: false,
//          ));
//        }
//      }
//      result.removeWhere((element) => !element.contains(filter));
//    }
//    result.removeWhere((element) => element['filesize'] != null
//        ? !element['name'].endsWith('xlsx')
//        : false);
      return result;
    }
    return null;
  }

  Future uploadTest() async {
    if (await checkAuthorized(true)) {
      var tempDir = await getTemporaryDirectory();
      var filepath = '${tempDir.path}/test_upload.txt';
      File(filepath).writeAsStringSync(
          'contents.. from ' + (Platform.isIOS ? 'iOS' : 'Android') + '\n');

      final result =
          await Dropbox.upload(filepath, '/test_upload.txt', (uploaded, total) {
        print('progress $uploaded / $total');
      });
      print(result);
    }
  }

  Future<SpreadsheetDecoder> downloadTest(
      String dropboxPath, String fileName) async {
    if (await checkAuthorized(true)) {
      var tempDir = (await getTemporaryDirectory()).path;
      var filepath = '$tempDir/$fileName';
      await Dropbox.download(dropboxPath, filepath);
      var bytes = File(filepath).readAsBytesSync();
      var decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
      return decoder;
    }
    return null;
  }

  Future<String> getTemporaryLink(path) async {
    final result = await Dropbox.getTemporaryLink(path);
    return result;
  }

  Widget results({
    @required Future<List> futureFiles,
    @required void Function(String path, String name) onFolderTap,
  }) {
    return FutureBuilder<List>(
      future: futureFiles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List list = snapshot.data;
          return Container(
            padding: EdgeInsets.all(5.0),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: list.length == 0
                ? Center(child: Text('No files found'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      Map item = list[index];
                      final fileSize = item['filesize'];
                      final path = item['pathLower'];
                      bool isFile = false;
                      bool isDownloadable = false;
                      var name = item['name'];
                      if (fileSize == null) {
                        name += '/';
                        isDownloadable = true;
                      } else {
                        isFile = true;
                        for (var ext in allowedExtensions) {
                          if (p.extension(name).replaceAll('.', '') == ext) {
                            isDownloadable = true;
                            break;
                          }
                        }
                      }
                      return ListTile(
                        leading: Icon(
                          isFile && isDownloadable
                              ? Icons.file_download
                              : isFile && !isDownloadable
                                  ? Icons.block
                                  : Icons.folder,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: !isDownloadable ? Colors.grey : Colors.black,
                          ),
                        ),
                        onTap: () async {
                          if (isFile && isDownloadable) {
                            Flushbar(
                              message: 'Downloading...',
                              duration: Duration(seconds: 3),
                            )..show(context);
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => Inventory(
                                  org: 'Dropbox',
                                  file: item,
                                ),
                              ),
                              (route) => false,
                            );
                          } else if (isFile && !isDownloadable) {
                            Flushbar(
                              message: 'This file cannot be downloaded.',
                              duration: Duration(seconds: 3),
                            )..show(context);
                          } else {
                            onFolderTap(path, name.replaceAll('/', ''));
                          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: futureFiles != null
          ? results(
              futureFiles: futureFiles,
              onFolderTap: (String path, String name) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DropboxChooser(
                      filePath: path,
                      fileName: name,
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text('Authentication error; please try again.'),
            ),
    );
  }
}

//class CustomSearchDelegate extends SearchDelegate<Map<String, String>> {
//  String fileId;
//  bool clickedSuggestion;
//
//  @override
//  List<Widget> buildActions(BuildContext context) {
//    return [
//      IconButton(
//        icon: Icon(Icons.clear),
//        onPressed: () {
//          query = '';
//        },
//      ),
//    ];
//  }
//
//  @override
//  Widget buildLeading(BuildContext context) {
//    return IconButton(
//      icon: Icon(Icons.arrow_back),
//      onPressed: () {
//        close(context, null);
//      },
//    );
//  }
//
//  @override
//  Widget buildResults(BuildContext context) {
//    return results(
//      futureFiles: clickedSuggestion
//          ? list(
//              filterWithQuery: false,
//              filter: fileId,
//            )
//          : list(
//              filterWithQuery: true,
//              filter: query,
//            ),
//      onFolderTap: (String id, String name) {
//        query = name;
//        fileId = id;
//        clickedSuggestion = true;
//        showResults(context);
//      },
//    );
//  }
//
//  @override
//  Widget buildSuggestions(BuildContext context) {
//    clickedSuggestion = false;
//
//    return query.length == 0
//        ? Container()
//        : results(
//            futureFiles: list(
//              filterWithQuery: true,
//              filter: query,
//            ),
//            onFolderTap: (String id, String name) {
//              query = name;
//              fileId = id;
//              clickedSuggestion = true;
//              showResults(context);
//            },
//          );
//  }
//}
