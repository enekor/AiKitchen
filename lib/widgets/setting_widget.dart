import 'package:flutter/material.dart';

class SwitchSetting extends StatelessWidget {
  final bool initialValue;
  final String text;
  final ValueChanged<bool> onChange;

  SwitchSetting({
    required this.initialValue,
    required this.text,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(text), Switch(value: initialValue, onChanged: onChange)],
    );
  }
}
