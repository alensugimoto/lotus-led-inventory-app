import 'dart:convert';
import 'dart:io';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lotus_led_inventory/model/try_catch.dart';
import 'package:mime_type/mime_type.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:oauth2_client/google_oauth2_client.dart';

import '../../model/try_catch.dart';
import 'inventory.dart';
import '../../model/file_data.dart';

class GoogleDrive extends StatelessWidget {
  final String fileName;
  final String fileId;

  GoogleDrive({
    this.fileName = NAME,
    this.fileId = ROOT_ID,
  });

  static const String NAME = 'Google Drive';
  static const String ROOT_ID = 'root';
  static const String GLYPH_PATH = 'assets/DriveGlyph_Color.png';
  static const List<String> READ_CONTENT_SCOPES = [
    'https://www.googleapis.com/auth/drive.readonly',
  ];
  static const List<String> READ_METADATA_SCOPES = [
    'https://www.googleapis.com/auth/drive.metadata.readonly',
  ];
  static const List<String> allowedExtensions = [
    'xlsx',
    'ods',
    'gsheet',
    'html',
    'htm',
  ];
  static const List<int> ERRORS_BY_STATUS_CODE = [
    400,
    401,
    403,
    404,
    429,
    500,
    502,
    503,
    504,
  ];
  static const String ANDROID_CLIENT_ID =
      '870429610804-87oatltl467p76ba1hb2nbpg7he3hbc6.apps.googleusercontent.com';
  static const String IOS_CLIENT_ID =
      '870429610804-3ni7p17b5rmmml3qi5j5auqrn728j5kg.apps.googleusercontent.com';

  static final List<String> allowedMimeTypes = allowedExtensions
      .map(
        (e) => "mimeType = '${mimeFromExtension(e)}'",
      )
      .toList();

  static OAuth2Helper getOAuth2Helper(List<String> scopes) {
    var helper = OAuth2Helper(
      GoogleOAuth2Client(
        customUriScheme: 'com.lotusledlights.merchandprice',
        redirectUri: 'com.lotusledlights.merchandprice:/oauth2redirect',
      ),
    );

    helper.setAuthorizationParams(
      grantType: OAuth2Helper.AUTHORIZATION_CODE,
      clientId: Platform.isAndroid ? ANDROID_CLIENT_ID : IOS_CLIENT_ID,
      scopes: scopes,
    );

    return helper;
  }

  static Future<http.Response> getHttpResponse({
    String unencodedPath = '',
    Map<String, String> queryParameters,
  }) async {
    List<String> scopes;

    switch (unencodedPath) {
      case '':
        {
          scopes = READ_METADATA_SCOPES;
        }
        break;

      default:
        {
          scopes = READ_CONTENT_SCOPES;
        }
        break;
    }

    var helper = getOAuth2Helper(scopes);

    final Uri uri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files$unencodedPath',
      queryParameters,
    );
    http.Response resp = await TryCatch.toGetApiResponse(
      () async {
        return await helper.get(uri.toString());
      },
      ERRORS_BY_STATUS_CODE,
    );

    return resp;
  }

  static Future<bool> revokeToken(List<String> scopes) async {
    var helper = getOAuth2Helper(scopes);

    await helper.disconnect();

    return await getTokenFromStorage(scopes);
  }

  static Future<bool> getTokenFromStorage(List<String> scopes) async {
    var helper = getOAuth2Helper(scopes);

    var tknResp = await helper.getTokenFromStorage();
    if (tknResp == null) {
      return false;
    }
    return true;
  }

  static Future<bool> getToken(
    List<String> scopes,
    void Function() onError,
  ) async {
    var helper = getOAuth2Helper(scopes);

    var tknResp = await TryCatch.toGetApiResponse(
      () async {
        return await helper.getToken();
      },
    );
    if (tknResp == null) {
      onError();
      return false;
    }
    return true;
  }

  static Future<List> list({
    @required bool filterWithQuery,
    @required String filter,
  }) async {
    http.Response resp = await getHttpResponse(
      queryParameters: {
        'q': "(mimeType = 'application/vnd.google-apps.folder' or " +
            "${allowedMimeTypes.join(" or ")}) and " +
            (filterWithQuery
                ? "name contains '$filter'"
                : "'$filter' in parents")
      },
    );

    if (resp == null) {
      return [null];
    }

    Map<String, dynamic> fileList = json.decode(resp.body);
    return fileList['files'];
  }

  static Future<FileData> download({
    @required String fileId,
    @required String mime,
    @required String provider,
    @required String name,
  }) async {
    http.Response resp = mime == mimeFromExtension('gsheet')
        ? await getHttpResponse(
            unencodedPath: '/$fileId/export',
            queryParameters: {
              'alt': 'media',
              'mimeType': mimeFromExtension('xlsx'),
            },
          )
        : await getHttpResponse(
            unencodedPath: '/$fileId',
            queryParameters: {
              'alt': 'media',
            },
          );

    if (resp == null) {
      return null;
    }

    var fileData = FileData(
      provider: provider,
      name: name,
      id: fileId,
      mimeType: mime,
      dateTime: DateTime.now().toIso8601String(),
      bytes: resp.bodyBytes,
    );
    await fileData.save();

    return fileData;
  }

  static Widget results({
    @required Future<List> futureFiles,
    @required void Function() onReload,
    @required void Function(String id, String name) onFolderTap,
  }) {
    return FutureBuilder<List>(
      future: futureFiles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List files = snapshot.data;
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: files.length == 0
                ? Center(child: Text('No downloadable files found'))
                : files[0] == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Couldn\'t fetch any files'),
                            SizedBox(height: 10.0),
                            RaisedButton(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Reload',
                              ),
                              onPressed: onReload,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          bool isLoading = false;
                          final Map file = files[index];
                          final String id = file['id'];
                          final String mime = file['mimeType'];
                          String name = file['name'];
                          bool isFile = false;
                          if (mime == 'application/vnd.google-apps.folder') {
                            name += '/';
                          } else {
                            isFile = true;
                          }
                          return StatefulBuilder(
                            builder: (context, setState) => ListTile(
                              leading: isLoading
                                  ? CircularProgressIndicator()
                                  : Icon(
                                      isFile ? Icons.lock_open : Icons.folder,
                                    ),
                              title: Text(name),
                              onTap: () async {
                                await TryCatch.onWifi(() async {
                                  if (isFile) {
                                    setState(() => isLoading = true);

                                    var fileData = await download(
                                      fileId: id,
                                      mime: mime,
                                      provider: 'Google',
                                      name: name,
                                    );

                                    if (fileData != null) {
                                      Navigator.of(
                                        context,
                                      ).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) => Inventory(
                                            fileData,
                                          ),
                                        ),
                                        (route) => false,
                                      );
                                    } else {
                                      setState(() => isLoading = false);
                                      Flushbar(
                                        message: 'We couldn\'t access '
                                            'your file',
                                        duration: Duration(seconds: 2),
                                      )..show(context);
                                    }
                                  } else {
                                    onFolderTap(id, name.replaceAll('/', ''));
                                  }
                                });
                              },
                            ),
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
    Future<List> futureFiles = list(
      filter: fileId,
      filterWithQuery: false,
    );
    bool isLoadingSearch = false;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: <Widget>[
          StatefulBuilder(
            builder: (context, setState) {
              return isLoadingSearch
                  ? Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () async {
                        setState(() => isLoadingSearch = true);

                        await TryCatch.onWifi(() async {
                          List files = await list(
                            filter: '',
                            filterWithQuery: true,
                          );

                          if (files[0] == null) {
                            Flushbar(
                              message:
                                  'In order to search your Google Drive, you need to '
                                  'give us permission to view it.',
                              duration: Duration(seconds: 4),
                            )..show(context);
                          } else {
                            showSearch(
                              context: context,
                              delegate: CustomSearchDelegate(files),
                            );
                          }
                        });

                        setState(() => isLoadingSearch = false);
                      },
                    );
            },
          ),
        ],
      ),
      body: results(
        futureFiles: futureFiles,
        onReload: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GoogleDrive(
                fileId: fileId,
                fileName: fileName,
              ),
            ),
          );
        },
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
  final List files;

  CustomSearchDelegate(this.files);

  Future<List> searchList() async {
    List newList = [];
    for (var file in files) {
      if (file['name'].toLowerCase().contains(query.toLowerCase())) {
        newList.add(file);
      }
    }
    return newList;
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
    return query.length == 0
        ? Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(child: Text('Please enter a query')),
          )
        : GoogleDrive.results(
            futureFiles: searchList(),
            onReload: () {},
            onFolderTap: (String id, String name) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => GoogleDrive(
                    fileId: id,
                    fileName: name,
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return query.length == 0
        ? Container()
        : GoogleDrive.results(
            futureFiles: searchList(),
            onReload: () {},
            onFolderTap: (String id, String name) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => GoogleDrive(
                    fileId: id,
                    fileName: name,
                  ),
                ),
              );
            },
          );
  }
}
