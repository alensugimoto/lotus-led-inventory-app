import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FittedText extends StatelessWidget {
  final List<List<dynamic>> filteredResults;
  final int row;
  final int column;
  final double fontSize;
  final bool includeLabel;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  FittedText(
    this.filteredResults, {
    @required this.row,
    this.column,
    this.includeLabel = false,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
  });

  bool checkIsEmpty({int start = 0, int end, bool isLabel = false}) {
    bool overflow = false;
    List<dynamic> cells = isLabel ? filteredResults[0] : filteredResults[row];

    if (start >= cells.length) {
      return true;
    }

    if (end == null) {
      end = cells.length;
    } else if (end > cells.length) {
      overflow = true;
    }

    int n = 0;
    for (int i = 0; i < cells.length; i++) {
      if (i >= start && i < end && cells[i] == null) {
        n += 1;
      }
    }

    if (n == (overflow ? cells.length : end) - start) {
      return true;
    } else {
      return false;
    }
  }

  String fittedTextText([bool isLabel = false]) {
    if (checkIsEmpty(start: column, end: column + 1)) {
      return '';
    } else {
      var cellContent =
          isLabel ? filteredResults[0][column] : filteredResults[row][column];

      if (cellContent == null) {
        return '';
      } else if (cellContent.runtimeType == String) {
        return cellContent + (isLabel ? ': ' : '');
      } else if (cellContent.runtimeType == int ||
          cellContent.runtimeType == double) {
        return NumberFormat().format(cellContent) + (isLabel ? ': ' : '');
      } else {
        return '<?>' + (isLabel ? ': ' : '');
      }
//      if (row == 0) {
//        if (cellContent == null) {
//          return '';
//        } else if (cellContent.runtimeType == String) {
//          return cellContent;
//        } else if (cellContent.runtimeType == int ||
//            cellContent.runtimeType == double) {
//          return cellContent.toString().replaceAll(
//            RegExp(r"([.]*0)(?!.*\d)"),
//            '',
//          );
//        } else {
//          return '<?>';
//        }
//      } else {
//        if (column == 1) {
//          if (cellContent == null) {
//            return '';
//          } else if (cellContent.runtimeType == String) {
//            cellContent = cellContent.replaceAll('\$', '');
//            if (double.tryParse(cellContent) == null) {
//              return '\$<?>';
//            } else {
//              return '\$${NumberFormat("#,##0.00", "en_US").format(
//                double.parse(cellContent),
//              )}';
//            }
//          } else if (cellContent.runtimeType == int ||
//              cellContent.runtimeType == double) {
//            return '\$${NumberFormat("#,##0.00", "en_US").format(cellContent)}';
//          } else {
//            return '<?>';
//          }
//        } else {
//          if (cellContent == null) {
//            return '';
//          } else if (cellContent.runtimeType == String) {
//            return cellContent;
//          } else if (cellContent.runtimeType == int ||
//              cellContent.runtimeType == double) {
//            return cellContent.toString().replaceAll(
//              RegExp(r"([.]*0)(?!.*\d)"),
//              '',
//            );
//          } else {
//            return '<?>';
//          }
//        }
//      }
    }
  }

//  Widget textList(
//    String text, {
//    @required double fontSize,
//    Color color,
//  }) {
//    List<String> words = text.trim().split(RegExp(r"\s+"));
//    List<Widget> textWidgets = [];
//    for (int i = 0; i < words.length; i++) {
//      textWidgets.add(Flexible(
//        child: Text(
//          words[i] + (i == words.length ? '' : ' '),
//          maxLines: 1,
//          textAlign: textAlign,
//          overflow: TextOverflow.ellipsis,
//          style: TextStyle(
//            color: color ?? Colors.black,
//            fontSize: fontSize,
//            fontWeight: fontWeight,
//          ),
//        ),
//      ));
//    }
//    return Row(
//      children: textWidgets,
//    );
//  }

  @override
  Widget build(BuildContext context) {
    String text = fittedTextText();
    String label = fittedTextText(true);

    return Tooltip(
      message: label + text,
      child: includeLabel
          ?
//      textList(
//              text,
//              fontSize: fontSize,
//            )
          RichText(
              maxLines: 1,
              textAlign: textAlign,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: fontSize / 1.5,
                      fontWeight: fontWeight,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                    ),
                  ),
                ],
              ),
            )
          :
//      textList(
//              text,
//              fontSize: fontSize,
//            ),
          Text(
              text,
              maxLines: 1,
              textAlign: textAlign,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
    );
//    return FittedBox(
//      alignment: Alignment.center,
//      fit: BoxFit.scaleDown,
//      child: ConstrainedBox(
//        constraints: BoxConstraints(
//          minWidth: 1.0,
//        ),
//        child: Text(
//          fittedTextText(),
//          style: TextStyle(
//            fontSize: fontSize,
//            fontWeight: fontWeight,
//          ),
//        ),
//      ),
//    );
  }
}
