import 'package:flutter/material.dart';

class ProviderData {
  final String name;
  final Widget dialWidget;
  final bool hasApi;
  final Widget onTapWidget;

  ProviderData({
    @required this.name,
    @required this.dialWidget,
    @required this.hasApi,
    this.onTapWidget,
  });
}
