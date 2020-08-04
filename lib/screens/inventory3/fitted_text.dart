import 'package:flutter/material.dart';

class FittedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  FittedText(this.text, {this.fontSize, this.fontWeight});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      alignment: Alignment.center,
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 1.0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
