import 'package:flutter/material.dart';
import 'package:inventory/google_drive.dart';
import 'package:inventory/dropbox.dart';

class PickFile extends StatelessWidget {
  final String option;

  PickFile(this.option);

  @override
  Widget build(BuildContext context) {
    return option == 'GD'
        ? GoogleDrive(
            fileName: 'Google Drive',
            fileId: 'root',
          )
        : option == 'DB'
            ? DropboxChooser(
                fileName: 'Dropbox',
                filePath: '',
              )
            : Scaffold(
                body: Center(child: Text('There was an error')),
              );
  }
}
