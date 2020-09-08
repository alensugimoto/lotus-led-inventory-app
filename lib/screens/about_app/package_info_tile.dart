import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

class PackageInfoTile extends StatelessWidget {
  final String subtitle;
  final String Function(PackageInfo) getTitle;

  PackageInfoTile({
    @required this.getTitle,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      subtitle: subtitle == null ? null : Text(subtitle),
      title: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            PackageInfo _packageInfo = snapshot.data;
            return Text(getTitle(_packageInfo));
          } else if (snapshot.hasError) {
            return Text('Unknown');
          }
          return Text('Calculating...');
        },
      ),
    );
  }
}
