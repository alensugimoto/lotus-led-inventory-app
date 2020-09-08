import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/try_catch.dart';

class ContactInfoTile extends StatelessWidget {
  final String subtitle;
  final String title;
  final bool isLink;

  ContactInfoTile({
    @required this.subtitle,
    @required this.title,
    @required this.isLink,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Tooltip(
        message: title,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Tooltip(
        message: isLink ? 'Launch URL' : 'Copy text',
        child: Icon(isLink ? Icons.launch : Icons.content_copy),
      ),
      onTap: () async {
        if (isLink) {
          await TryCatch.open(context, title);
        } else {
          Clipboard.setData(ClipboardData(text: title));
          Flushbar(
            message: 'Copied to Clipboard',
            duration: Duration(seconds: 2),
          )..show(context);
        }
      },
    );
  }
}
