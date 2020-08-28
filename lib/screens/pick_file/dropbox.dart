import 'dart:convert';
import 'dart:async';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:mime_type/mime_type.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import '../../model/file_data.dart';
import '../../wi_fi.dart';
import '../inventory/inventory.dart';

final List<String> allowedExtensions = [
  'xlsx',
  'ods',
  'html',
  'htm',
];

const String dropbox_key = '3ss8bafc9ujv2hx';
const String dropbox_secret = 'oysrishvqq9wff5';

Future<http.Response> getDropboxApiResponse({
  @required bool isRPC,
  String unencodedPath = '',
  @required Map<String, String> queryParameters,
}) async {
  var helper = OAuth2Helper(
    DropboxOAuth2Client(
      customUriScheme: 'com.lotusledlights.merchandprice',
      redirectUri: 'com.lotusledlights.merchandprice:/oauth2redirect',
    ),
  );

  helper.setAuthorizationParams(
    grantType: OAuth2Helper.AUTHORIZATION_CODE,
    clientId: dropbox_key,
    clientSecret: dropbox_secret,
  );

  var arg = json.encode(queryParameters);
  http.Response resp = isRPC
      ? await helper.post(
          Uri.https(
            'api.dropboxapi.com',
            '/2/files$unencodedPath',
          ).toString(),
          body: arg,
          headers: {'Content-Type': 'application/json'},
        )
      : await helper.post(
          Uri.https(
            'content.dropboxapi.com',
            '/2/files$unencodedPath',
          ).toString(),
          headers: {'Dropbox-API-Arg': arg},
        );

  return resp;
}

Future<List> list({
  @required bool filterWithQuery,
  @required String filter,
}) async {
  if (filterWithQuery) {
    http.Response resp = await getDropboxApiResponse(
      isRPC: true,
      unencodedPath: '/search_v2',
      queryParameters: {'query': filter},
    );
    Map<String, dynamic> fileList = json.decode(resp.body);
    print(resp.body);
    return fileList['matches'].map((e) => e['metadata']['metadata']).toList();
  } else {
    http.Response resp = await getDropboxApiResponse(
      isRPC: true,
      unencodedPath: '/list_folder',
      queryParameters: {'path': filter},
    );
    Map<String, dynamic> fileList = json.decode(resp.body);
    return fileList['entries'];
  }
}

Future<FileData> download({
  @required String dropboxPath,
  @required String fileName,
  @required String provider,
  @required String mime,
}) async {
  http.Response resp = await getDropboxApiResponse(
    isRPC: false,
    unencodedPath: '/download',
    queryParameters: {
      'path': dropboxPath,
    },
  );
  var fileData = FileData(
    provider: provider,
    name: fileName,
    id: dropboxPath,
    mimeType: mime,
    dateTime: DateTime.now().toIso8601String(),
    bytes: resp.bodyBytes,
  );
  await fileData.save();

  return fileData;
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
                    final fileSize = item['size'];
                    final path = item['path_lower'];
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
                        if (isFile && !isDownloadable) {
                          Flushbar(
                            message: 'This file cannot be read.',
                            duration: Duration(seconds: 3),
                          )..show(context);
                        } else {
                          await WiFi().tryCatch(() async {
                            if (isFile && isDownloadable) {
                              var futureFileData = download(
                                dropboxPath: path,
                                fileName: name,
                                provider: 'Dropbox',
                                mime: mimeFromExtension(
                                  p.extension(name).replaceAll('.', ''),
                                ),
                              );
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
                            } else {
                              onFolderTap(path, name.replaceAll('/', ''));
                            }
                          });
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

class Dropbox extends StatefulWidget {
  final String filePath;
  final String fileName;

  Dropbox({
    @required this.filePath,
    @required this.fileName,
  });

  @override
  DropboxState createState() => DropboxState();
}

class DropboxState extends State<Dropbox> {
  Future<List> futureFiles;

  @override
  void initState() {
    super.initState();
    futureFiles = list(
      filterWithQuery: false,
      filter: widget.filePath,
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
                    builder: (context) => Dropbox(
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

class DropboxOAuth2Client extends OAuth2Client {
  DropboxOAuth2Client({
    @required String redirectUri,
    @required String customUriScheme,
  }) : super(
          authorizeUrl: 'https://www.dropbox.com/oauth2/authorize',
          tokenUrl: 'https://api.dropboxapi.com/oauth2/token',
          redirectUri: redirectUri,
          customUriScheme: customUriScheme,
        );
}
