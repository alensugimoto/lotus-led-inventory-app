import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lotus_led_inventory/screens/inventory/inventory.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as p;

import '../app.dart';
import 'file_data.dart';

class DeviceStorage {
  static const String NAME = 'Device Storage';
  static const List<String> ALLOWED_EXTENSIONS = [
    'xlsx',
    'ods',
    'html',
    'htm',
  ];

  static Future<FileData> _getFileDataWithFilePicker() async {
    String filePath;
    try {
      filePath = await FilePicker.getFilePath(
        type: FileType.custom,
        allowedExtensions: ALLOWED_EXTENSIONS,
      );
    } catch (_) {
      return null;
    }

    if (filePath == null) {
      return null;
    }

    final String ext = p.extension(filePath).replaceAll('.', '');

    if (ALLOWED_EXTENSIONS.contains(ext)) {
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
            ' one of the following: ${ALLOWED_EXTENSIONS.join(', ')}.',
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

  static SpeedDialChild speedDialChild(
    BuildContext context, {
    void Function() beforeAwait,
    void Function() afterAwait,
  }) {
    return SpeedDialChild(
      child: Center(
        child: Tooltip(
          message: 'Add from $NAME',
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.storage,
              color: Colors.grey,
            ),
          ),
        ),
      ),
      onTap: () async {
        if (beforeAwait != null) {
          beforeAwait();
        }

        final fileData = await _getFileDataWithFilePicker();

        if (fileData != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => Inventory(fileData),
            ),
            (route) => false,
          );
        } else {
          if (afterAwait != null) {
            afterAwait();
          }
        }
      },
    );
  }
}
