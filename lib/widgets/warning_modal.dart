import 'package:flutter/material.dart';

class WarningModal {
  static Future<dynamic> ShowWarningDialog({
    String? title,
    required String texto,
    required BuildContext context,
    Function? onAccept,
    String? okText,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? "¡Alerta!"),
          content: Text(texto),
          actions: [
            TextButton(
              child: Text(okText ?? "Ok"),
              onPressed:
                  () =>
                      onAccept ??
                      () {
                        Navigator.pop(context);
                      },
            ),
          ],
        );
      },
    );
  }
}
