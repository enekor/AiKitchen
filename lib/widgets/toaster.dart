import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Toaster {
  static void showToast(
    String message, {
    bool long = false,
    ToastType type = ToastType.info,
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (type) {
      case ToastType.success:
        backgroundColor = const Color(0xFF66BB6A); // Green from cooking theme
        break;
      case ToastType.error:
        backgroundColor = const Color(0xFFE57373); // Red from cooking theme
        break;
      case ToastType.warning:
        backgroundColor = const Color(0xFFFFB74D); // Yellow from cooking theme
        textColor = Colors.black87;
        break;
      case ToastType.info:
      default:
        backgroundColor = const Color(0xFF5C6BC0); // Purple-blue
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: long ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: long ? 3 : 2,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
      webShowClose: true,
    );
  }

  static void showSuccess(String message, {bool long = false}) {
    showToast(message, long: long, type: ToastType.success);
  }

  static void showError(String message, {bool long = false}) {
    showToast(message, long: long, type: ToastType.error);
  }

  static void showWarning(String message, {bool long = false}) {
    showToast(message, long: long, type: ToastType.warning);
  }
}

enum ToastType { success, error, warning, info }
