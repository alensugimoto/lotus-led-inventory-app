import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime_type/mime_type.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:oauth2_client/google_oauth2_client.dart';

import '../inventory/inventory.dart';
import '../../model/file_data.dart';

final List<String> allowedExtensions = [
  'xlsx',
  'ods',
  'gsheet',
  'html',
  'htm',
];

String _androidClientId =
    '870429610804-87oatltl467p76ba1hb2nbpg7he3hbc6.apps.googleusercontent.com';
String _iosClientId =
    '870429610804-3ni7p17b5rmmml3qi5j5auqrn728j5kg.apps.googleusercontent.com';
List<String> _scopes = ['https://www.googleapis.com/auth/drive.readonly'];

final List<String> allowedMimeTypes = allowedExtensions
    .map(
      (e) => "mimeType = '${mimeFromExtension(e)}'",
    )
    .toList();
Future<List> futureFiles;

//Future<http.Client> getHttpClient() async {
//  //Get Credentials
//  var credentials = await storage.getCredentials();
//  if (credentials == null) {
//    //Needs user authentication
//    var context = navigatorKey.currentState.overlay.context;
//    var client = await clientViaUserConsent(_id, _scopes, (url) {
//      showDialog(
//        barrierDismissible: false,
//        context: context,
//        builder: (context) => AlertDialog(
//          title: Text('User Authentication'),
//          content: RichText(
//            text: TextSpan(
//              children: [
//                TextSpan(
//                  text: 'Please go to the following URL and grant access: ',
//                  style: TextStyle(color: Colors.black),
//                ),
//                TextSpan(
//                  text: url,
//                  style: TextStyle(color: Colors.blue),
//                  recognizer: TapGestureRecognizer()
//                    ..onTap = () async {
//                      if (await canLaunch(url)) {
//                        await launch(url);
//                      } else {
//                        showDialog(
//                          barrierDismissible: false,
//                          context: navigatorKey.currentState.overlay.context,
//                          builder: (context) => AlertDialog(
//                            title: Text('Unable to Launch'),
//                            content: Text(
//                              'Please try copying the link with the'
//                              ' following icon button and pasting'
//                              ' it in a browser.',
//                            ),
//                            actions: <Widget>[
//                              IconButton(
//                                icon: Icon(Icons.content_copy),
//                                onPressed: () async {
//                                  await Clipboard.setData(
//                                    ClipboardData(text: url),
//                                  );
//                                  Navigator.pop(context);
//                                  Flushbar(
//                                    message: 'Copied!',
//                                    duration: Duration(seconds: 3),
//                                  )..show(context);
//                                },
//                              ),
//                            ],
//                          ),
//                        );
//                      }
//                    },
//                ),
//              ],
//            ),
//          ),
//        ),
//      );
//    });
//    Navigator.pop(context);
//    //Save Credentials
//    print(client.credentials.accessToken.expiry);
//    await storage.saveCredentials(
//      client.credentials.accessToken,
//      client.credentials.refreshToken,
//    );
//    return client;
//  } else {
//    //Already authenticated
//    return authenticatedClient(
//      http.Client(),
//      AccessCredentials(
//        AccessToken(
//          credentials["type"],
//          credentials["data"],
//          DateTime.tryParse(
//            credentials["expiry"],
//          ),
//        ),
//        credentials["refreshToken"],
//        _scopes,
//      ),
//    );
//  }
//}

Future<http.Response> getGoogleApiResponse({
  String unencodedPath = '',
  Map<String, String> queryParameters,
}) async {
  var helper = OAuth2Helper(
    GoogleOAuth2Client(
      customUriScheme: 'com.lotusledlights.merchandprice',
      redirectUri: 'com.lotusledlights.merchandprice:/oauth2redirect',
    ),
  );

  helper.setAuthorizationParams(
    grantType: OAuth2Helper.AUTHORIZATION_CODE,
    clientId: Platform.isAndroid ? _androidClientId : _iosClientId,
    scopes: _scopes,
  );

  final Uri uri = Uri.https(
      'www.googleapis.com', '/drive/v3/files$unencodedPath', queryParameters);
  http.Response resp = await helper.get(uri.toString());

  return resp;
}

Future<List> list({
  @required bool filterWithQuery,
  @required String filter,
}) async {
  http.Response resp = await getGoogleApiResponse(
    queryParameters: {
      'q': "(mimeType = 'application/vnd.google-apps.folder' or " +
          "${allowedMimeTypes.join(" or ")}) and " +
          (filterWithQuery ? "name contains '$filter'" : "'$filter' in parents")
    },
  );
  Map<String, dynamic> fileList = json.decode(resp.body);
  return fileList['files'];
}

Future<FileData> download({
  @required String fileId,
  @required String mime,
  @required String provider,
  @required String name,
}) async {
  http.Response resp;

  if (mime == mimeFromExtension('gsheet')) {
    resp = await getGoogleApiResponse(
      unencodedPath: '/$fileId/export',
      queryParameters: {
        'alt': 'media',
        'mimeType': mimeFromExtension('xlsx'),
      },
    );
  } else {
    resp = await getGoogleApiResponse(
      unencodedPath: '/$fileId',
      queryParameters: {
        'alt': 'media',
      },
    );
  }

//  String tempDir = (await getTemporaryDirectory()).path;
//  String appDir = (await getApplicationDocumentsDirectory()).path;

  // resp to zip
//  File zippedFile = await File('$tempDir/$fileId.zip').writeAsBytes(resp.bodyBytes);
//
//  // zip to spreadsheet
//  var zipBytes = zippedFile.readAsBytesSync();
//  var archive = ZipDecoder().decodeBytes(zipBytes);
//  var sheetFile = File('$appDir/$fileId.${extensionFromMime(mime)}')
//    ..createSync(recursive: true)
//    ..writeAsBytesSync(archive[0].content as List<int>);
//
//  // spreadsheet to decoder
//  var bytes = sheetFile.readAsBytesSync();
  var fileData = FileData(
    provider: provider,
    name: name,
    id: fileId,
    mimeType: mime,
    bytes: resp.bodyBytes,
  );
  await fileData.save();

  return fileData;
}

Widget results({
  @required Future<List> futureFiles,
  @required void Function(String id, String name) onFolderTap,
}) {
  return FutureBuilder<List>(
    future: futureFiles,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        List files = snapshot.data;
        return Container(
          padding: EdgeInsets.all(5.0),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: files.length == 0
              ? Center(child: Text('No downloadable files found'))
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    Map file = files[index];
                    String id = file['id'];
                    String name = file['name'];
                    String mime = file['mimeType'];
                    bool isFile = false;
                    if (mime == 'application/vnd.google-apps.folder') {
                      name += '/';
                    } else {
                      isFile = true;
                    }
                    return ListTile(
                      leading: Icon(
                        isFile ? Icons.file_download : Icons.folder,
                      ),
                      title: Text(name),
                      onTap: () async {
                        await internetTryCatch(() async {
                          if (isFile) {
                            var futureFileData = download(
                              fileId: id,
                              mime: mime,
                              provider: 'Google',
                              name: name,
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
                            onFolderTap(id, name.replaceAll('/', ''));
                          }
                        });
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

class GoogleDrive extends StatefulWidget {
  final String fileName;
  final String fileId;

  GoogleDrive({@required this.fileName, @required this.fileId});

  @override
  _GoogleDriveState createState() => _GoogleDriveState();
}

class _GoogleDriveState extends State<GoogleDrive> {
  @override
  void initState() {
    super.initState();
    futureFiles = list(
      filter: widget.fileId,
      filterWithQuery: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: CustomSearchDelegate());
            },
          ),
        ],
      ),
      body: results(
        futureFiles: futureFiles,
        onFolderTap: (String id, String name) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GoogleDrive(
                fileId: id,
                fileName: name,
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<Map<String, String>> {
  String fileId;
  bool clickedSuggestion;

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
    return results(
      futureFiles: clickedSuggestion
          ? list(
              filterWithQuery: false,
              filter: fileId,
            )
          : list(
              filterWithQuery: true,
              filter: query,
            ),
      onFolderTap: (String id, String name) {
        query = name;
        fileId = id;
        clickedSuggestion = true;
        showResults(context);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    clickedSuggestion = false;

    return query.length == 0
        ? Container()
        : results(
            futureFiles: list(
              filterWithQuery: true,
              filter: query,
            ),
            onFolderTap: (String id, String name) {
              query = name;
              fileId = id;
              clickedSuggestion = true;
              showResults(context);
            },
          );
  }
}
