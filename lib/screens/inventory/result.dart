import 'package:flutter/material.dart';

import 'fitted_text.dart';

class Result extends StatelessWidget {
  final int index;
  final List<List<dynamic>> filteredLights;

  Result(this.index, this.filteredLights);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedText(
          filteredLights,
          row: this.index,
          column: 0,
          linkIsColored: false,
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: filteredLights[0].length,
          itemBuilder: (context, index) {
            return FittedText(
              filteredLights,
              row: this.index,
            ).checkIsEmpty(
              start: index,
              end: index + 1,
            )
                ? Container()
                : ListTile(
                    title: FittedText(
                      filteredLights,
                      row: this.index,
                      column: index,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      infiniteLines: true,
                    ),
                    subtitle: FittedText(
                      filteredLights,
                      row: 0,
                    ).checkIsEmpty(
                      start: index,
                      end: index + 1,
                    )
                        ? Container()
                        : FittedText(
                            filteredLights,
                            row: 0,
                            column: index,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w400,
                            infiniteLines: true,
                          ),
                  );
          },
        ),
      ),
    );
  }
}
