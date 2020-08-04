import 'package:flutter/material.dart';
import 'search_bar.dart';
import 'search_button.dart';

class SearchSection extends StatelessWidget {
  final double _spacing;

  SearchSection(this._spacing);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[200],
      ),
      child: Column(
        children: <Widget>[
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              SizedBox(width: _spacing),
              SearchBar(1, 'Model Number', '', true),
              SizedBox(width: _spacing),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            children: <Widget>[
              SizedBox(width: _spacing),
              SearchBar(13, 'Qty', '1', true),
              SizedBox(width: _spacing),
              SearchBar(11, '%Disc', '0', true),
              SizedBox(width: _spacing),
              SearchButton(4),
              SizedBox(width: _spacing),
            ],
          ),
          SizedBox(height: _spacing),
        ],
      ),
    );
  }
}
