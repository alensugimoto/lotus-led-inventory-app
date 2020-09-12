import 'dart:convert';
import 'dart:async';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:lotus_led_inventory/model/try_catch.dart';
import 'package:lotus_led_inventory/screens/inventory/web_view_container.dart';
import 'package:meta/meta.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart' as js;

import 'file_data.dart';
import 'try_catch.dart';

class Dropbox {
  static const String NAME = 'Dropbox';
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

  static String fileName;
  static String fileId;

  static SpeedDialChild speedDialChild(
    BuildContext context, {
    void Function() onSuccess,
    void Function() onCancel,
  }) {
    return SpeedDialChild(
      child: Center(
        child: Tooltip(
          message: 'Add from $NAME',
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                GLYPH_PATH,
                scale: 9.0,
                fit: BoxFit.none,
              ),
            ),
          ),
        ),
      ),
      onTap: () {
        var options = '''{
          success: function(files) {
            FileName.postMessage(files[0].name);
            FileId.postMessage(files[0].id);
          },
          cancel: function() {
            Cancel.postMessage("");
          },
          extensions: ${ALLOWED_EXTENSIONS.map((e) => "'.$e'").toList().toString()},
        }''';
        var onUnsupportedBrowser = '''function() {
          Browser.postMessage("");
        }''';

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WebViewContainer(
              url: CHOOSER_URL,
              isPicker: true,
              evaluatedJavascript:
                  'loadChooser($options, $onUnsupportedBrowser)',
              javascriptChannels: [
                JavascriptChannel(
                  name: 'FileName',
                  onMessageReceived: (message) {
                    fileName = message.message;
                    print(fileName);
                  },
                ),
                JavascriptChannel(
                  name: 'FileId',
                  onMessageReceived: (message) {
                    fileId = message.message;
                    print(fileId);
                  },
                ),
                JavascriptChannel(
                  name: 'Cancel',
                  onMessageReceived: (message) {
                    Navigator.of(context).pop();
                    print('Cancelled');
                  },
                ),
                JavascriptChannel(
                  name: 'Browser',
                  onMessageReceived: (message) {
                    Flushbar(
                      message: message.message,
                      mainButton: FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Dismiss',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    )..show(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
