import 'dart:convert';
import 'dart:async';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:lotus_led_inventory/model/try_catch.dart';
import 'package:meta/meta.dart';
import 'package:mime_type/mime_type.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import '../../model/file_data.dart';
import '../../model/try_catch.dart';
import 'inventory.dart';

class Dropbox extends StatelessWidget {
  final String filePath;
  final String fileName;

  Dropbox({
    this.filePath = ROOT_PATH,
    this.fileName = NAME,
  });

  static const String NAME = 'Dropbox';
  static const String ROOT_PATH = '';
  static const String GLYPH_PATH = 'assets/DropboxGlyph_Blue.png';
  static const String APP_KEY = '3ss8bafc9ujv2hx';
  static const String CHOOSER_URL =
      'https://alensugimoto.github.io/lotus-led-inventory-app/dropbox-chooser.html';
  static const List<String> READ_CONTENT_SCOPES = [
    'files.content.read',
    'files.metadata.read',
  ];
  static const List<String> READ_METADATA_SCOPES = [
    'files.metadata.read',
  ];
  static const List<String> ALLOWED_EXTENSIONS = [
    'xlsx',
    'ods',
    'html',
    'htm',
  ];

  static final List<int> errorsByStatusCode = [
    400,
    401,
    403,
    409,
    429,
  ]..addAll([for (var i = 500; i < 600; i++) i]);

  static OAuth2Helper getOAuth2Helper(List<String> scopes) {
    var helper = OAuth2Helper(
      DropboxOAuth2Client(
        customUriScheme: 'com.lotusledlights.merchandprice',
        redirectUri: 'com.lotusledlights.merchandprice:/oauth2redirect',
      ),
    );

    helper.setAuthorizationParams(
      grantType: OAuth2Helper.AUTHORIZATION_CODE,
      clientId: APP_KEY,
      scopes: scopes,
    );

    return helper;
  }

  static Future<http.Response> getHttpResponse({
    @required bool isRPC,
    @required String unencodedPath,
    @required Map<String, String> queryParameters,
  }) async {
    List<String> scopes;

    switch (unencodedPath) {
      case '/list_folder':
      case '/search_v2':
        {
          scopes = READ_METADATA_SCOPES;
        }
        break;

      case '/download':
        {
          scopes = READ_CONTENT_SCOPES;
        }
        break;
    }

    var helper = getOAuth2Helper(scopes);

    var arg = json.encode(queryParameters);
    http.Response resp = await TryCatch.toGetApiResponse(
      () async {
        return await (isRPC
            ? helper.post(
                Uri.https(
                  'api.dropboxapi.com',
                  '/2/files$unencodedPath',
                ).toString(),
                body: arg,
                headers: {'Content-Type': 'application/json'},
              )
            : helper.post(
                Uri.https(
                  'content.dropboxapi.com',
                  '/2/files$unencodedPath',
                ).toString(),
                headers: {'Dropbox-API-Arg': arg},
              ));
      },
      errorsByStatusCode,
    );

    return resp;
  }

  static Future<bool> revokeToken(List<String> scopes) async {
    var helper = getOAuth2Helper(scopes);

    var tknResp = await helper.getTokenFromStorage();
    if (tknResp != null) {
      await helper.post('https://api.dropboxapi.com/2/auth/token/revoke');
      await helper.tokenStorage.deleteToken(helper.scopes);
    }

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
    if (filterWithQuery) {
      http.Response resp = await getHttpResponse(
        isRPC: true,
        unencodedPath: '/search_v2',
        queryParameters: {'query': filter},
      );

      if (resp == null) {
        return [null];
      }

      Map<String, dynamic> fileList = json.decode(resp.body);
      return fileList['matches'].map((e) => e['metadata']['metadata']).toList();
    } else {
      http.Response resp = await getHttpResponse(
        isRPC: true,
        unencodedPath: '/list_folder',
        queryParameters: {'path': filter},
      );

      if (resp == null) {
        return [null];
      }

      Map<String, dynamic> fileList = json.decode(resp.body);
      return fileList['entries'];
    }
  }

  static Future<FileData> download({
    @required String dropboxPath,
    @required String fileName,
    @required String provider,
    @required String mime,
  }) async {
    http.Response resp = await getHttpResponse(
      isRPC: false,
      unencodedPath: '/download',
      queryParameters: {
        'path': dropboxPath,
      },
    );

    if (resp == null) {
      return null;
    }

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

  static Widget results({
    @required Future<List> futureFiles,
    @required void Function() onReload,
    @required void Function(String path, String name) onFolderTap,
  }) {
    return FutureBuilder<List>(
      future: futureFiles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List list = snapshot.data;
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: list.length == 0
                ? Center(child: Text('No files found'))
                : list[0] == null
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
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          bool isLoading = false;
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
                            for (var ext in ALLOWED_EXTENSIONS) {
                              if (p.extension(name).replaceAll('.', '') ==
                                  ext) {
                                isDownloadable = true;
                                break;
                              }
                            }
                          }
                          return StatefulBuilder(
                            builder: (context, setState) => ListTile(
                              leading: isLoading
                                  ? CircularProgressIndicator()
                                  : Icon(
                                      isFile && isDownloadable
                                          ? Icons.lock_open
                                          : isFile && !isDownloadable
                                              ? Icons.lock
                                              : Icons.folder,
                                    ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  color: !isDownloadable
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              onTap: () async {
                                if (isFile && !isDownloadable) {
                                  Flushbar(
                                    message: 'This file cannot be read.',
                                    duration: Duration(seconds: 3),
                                  )..show(context);
                                } else {
                                  await TryCatch.onWifi(() async {
                                    if (isFile && isDownloadable) {
                                      setState(() => isLoading = true);

                                      var fileData = await download(
                                        dropboxPath: path,
                                        fileName: name,
                                        provider: 'Dropbox',
                                        mime: mimeFromExtension(
                                          p.extension(name).replaceAll('.', ''),
                                        ),
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
                                      onFolderTap(
                                        path,
                                        name.replaceAll('/', ''),
                                      );
                                    }
                                  });
                                }
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
    Future<List> futureFiles = Dropbox.list(
      filterWithQuery: false,
      filter: filePath,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: Dropbox.results(
        futureFiles: futureFiles,
        onReload: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Dropbox(
                filePath: filePath,
                fileName: fileName,
              ),
            ),
          );
        },
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
      ),
    );
  }
}

class DropboxOAuth2Client extends OAuth2Client {
  DropboxOAuth2Client({
    @required String redirectUri,
    @required String customUriScheme,
  }) : super(
          authorizeUrl: 'https://www.dropbox.com/oauth2/authorize',
          tokenUrl: 'https://api.dropboxapi.com/oauth2/token',
          revokeUrl: 'https://api.dropboxapi.com/2/auth/token/revoke',
          redirectUri: redirectUri,
          customUriScheme: customUriScheme,
        );
}
