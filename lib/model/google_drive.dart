import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:lotus_led_inventory/model/try_catch.dart';
import 'package:lotus_led_inventory/screens/inventory/web_view_container.dart';
import 'package:mime_type/mime_type.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:oauth2_client/google_oauth2_client.dart';
import 'package:webview_flutter/webview_flutter.dart' as js;

import 'file_data.dart';

class GoogleDrive {
  static const String NAME = 'Google Drive';
  static const String GLYPH_PATH = 'assets/DriveGlyph_Color.png';
  static const String PICKER_URL =
      'https://alensugimoto.github.io/lotus-led-inventory-app/google-picker.html';
  static const List<String> READ_SCOPES = [
    'https://www.googleapis.com/auth/drive.readonly',
  ];
  static const String ANDROID_CLIENT_ID =
      '870429610804-87oatltl467p76ba1hb2nbpg7he3hbc6.apps.googleusercontent.com';
  static const String IOS_CLIENT_ID =
      '870429610804-3ni7p17b5rmmml3qi5j5auqrn728j5kg.apps.googleusercontent.com';
  static const List<String> ALLOWED_EXTENSIONS = [
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
    var helper = getOAuth2Helper(READ_SCOPES);

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

  static String fileName;
  static String fileId;

  static SpeedDialChild speedDialChild(BuildContext context) {
    return SpeedDialChild(
      child: Center(
        child: Tooltip(
          message: 'Add from $NAME',
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                GLYPH_PATH,
                scale: 35.0,
                fit: BoxFit.none,
              ),
            ),
          ),
        ),
      ),
      onTap: () {
        var mimeTypes = ALLOWED_EXTENSIONS
            .map(
              (e) => mimeFromExtension(e),
            )
            .join(',');
        var options = '''{
          success: function(files) {
            FileName.postMessage(files[0].name);
            FileId.postMessage(files[0].id);
          },
          cancel: function() {
            Cancel.postMessage("");
          },
          mimeTypes: "$mimeTypes",
        }''';

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WebViewContainer(
              url: PICKER_URL,
              isPicker: true,
              evaluatedJavascript: 'loadPicker($options)',
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
              ],
            ),
          ),
        );
      },
    );
  }
}
