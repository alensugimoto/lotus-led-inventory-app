import 'package:flutter/material.dart';
import 'fitted_text.dart';

class QuantityList extends StatelessWidget {
  final int index;
  final List<Map<String, String>> filteredLights;
  final List<String> headers;

  QuantityList(this.index, this.filteredLights, this.headers);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: headers.length - 2,
        itemBuilder: (context, index) {
          return Container(
            width: 90.0,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FittedText(
                      filteredLights[this.index][headers[index + 2]].isEmpty
                          ? '0'
                          : filteredLights[this.index][headers[index + 2]],
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                    FittedText(
                      headers[index + 2].isEmpty ? '?' : headers[index + 2],
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
