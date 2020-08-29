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
        title: Text(
          FittedText(
            filteredLights,
            row: this.index,
            column: 0,
          ).fittedTextText(),
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
                    title: Text(
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
                    subtitle: FittedText(
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
                  );
          },
        ),
      ),
    );
  }
}
