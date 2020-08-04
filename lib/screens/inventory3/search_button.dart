import 'package:flutter/material.dart';

class SearchButton extends StatelessWidget {
  final int _flex;

  SearchButton(this._flex);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: _flex,
      child: MaterialButton(
        onPressed: () {},
        color: Colors.blue,
        textColor: Colors.white,
        child: Icon(
          Icons.search,
          size: 24,
        ),
        padding: EdgeInsets.all(10.0),
        shape: CircleBorder(),
      ),
    );
  }
}
