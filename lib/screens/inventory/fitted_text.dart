import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linkify/linkify.dart';
import 'package:lotus_led_inventory/model/try_catch.dart';

class FittedText extends StatelessWidget {
  final List<List<dynamic>> filteredResults;
  final int row;
  final int column;
  final double fontSize;
  final bool includeTooltipLabel;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final Color textColor;
  final bool linkIsColored;
  final bool infiniteLines;

  FittedText(
    this.filteredResults, {
    @required this.row,
    this.column,
    this.includeTooltipLabel = true,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.textColor,
    this.linkIsColored = true,
    this.infiniteLines = false,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    String text = fittedTextText();
    String label = !includeTooltipLabel ? '' : fittedTextText(true);

    Widget textWidget = Text.rich(
      TextSpan(
        children: linkify(text)
            .map<TextSpan>((e) => (e is LinkableElement)
                ? TextSpan(
                    text: e.text,
                    style: TextStyle(
                      color:
                          linkIsColored ? Theme.of(context).primaryColor : null,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await TryCatch.open(context, e.url);
                      },
                  )
                : TextSpan(
                    text: e.text,
                  ))
            .toList(),
      ),
      maxLines: infiniteLines ? null : 1,
      overflow: infiniteLines ? null : TextOverflow.ellipsis,
      textAlign: textAlign,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );

    return infiniteLines
        ? textWidget
        : Tooltip(
            message: label + text,
            child: textWidget,
          );
  }
}
