import 'package:flutter/material.dart';
import 'fitted_text.dart';

class QuantityList extends StatelessWidget {
  final int index;
  final List<List<dynamic>> filteredLights;

  QuantityList(this.index, this.filteredLights);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: filteredLights[0].length - 3,
        itemBuilder: (context, index) {
          index += 3;
          return FittedText(
            filteredLights,
            row: this.index,
          ).checkIsEmpty(
            start: index,
            end: index + 1,
          )
              ? Container()
              : Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 5.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          FittedText(
                            filteredLights,
                            row: this.index,
                            column: index,
                          ).fittedTextText(),
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        FittedText(
                          filteredLights,
                          row: 0,
                        ).checkIsEmpty(
                          start: index,
                          end: index + 1,
                        )
                            ? Container()
                            : Text(
                                FittedText(
                                  filteredLights,
                                  row: 0,
                                  column: index,
                                ).fittedTextText(),
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
