import 'package:flutter/material.dart';

Widget getTextButton(
  String text, {
  required Function()? onPressed,
  double? textSize,
}) {
  return ElevatedButton(
    style: ButtonStyle(
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              8.0), // Set your desired border radius value here
        ),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.all(8.0), // Adjust this value as needed
      child: Text(
        text,
        style: TextStyle(fontSize: textSize ?? 24),
      ),
    ),
    onPressed: onPressed != null
        ? () {
            onPressed();
          }
        : null,
  );
}
