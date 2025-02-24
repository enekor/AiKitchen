import 'package:flutter/material.dart';

class SwitchSetting extends StatefulWidget {
  final bool initialValue;
  final String text;
  final ValueChanged<bool> onChange;

  SwitchSetting({
    required this.initialValue,
    required this.text,
    required this.onChange,
  });

  @override
  _SwitchSettingState createState() => _SwitchSettingState();
}

class _SwitchSettingState extends State<SwitchSetting> {
  late bool currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.text),
        Switch(
          value: currentValue,
          onChanged: (bool value) {
            setState(() {
              currentValue = value;
            });
            widget.onChange(value);
          },
        ),
      ],
    );
  }
}

class ScrollbarSetting extends StatefulWidget {
  final int initialValue;
  final String text;
  final ValueChanged<int> onChange;
  final int divisions;
  final int maxValue;

  ScrollbarSetting({
    required this.initialValue,
    required this.text,
    required this.onChange,
    required this.maxValue,
    required this.divisions
  });

  @override
  _ScrollbarSettingState createState() => _ScrollbarSettingState();
}

class _ScrollbarSettingState extends State<ScrollbarSetting> {
  late int currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.text),
        Slider(
          value: currentValue.toDouble(),
          min: 1,
          max: widget.maxValue.toDouble(),
          divisions: widget.divisions,
          label: currentValue.toString(),
          onChanged: (double value) {
            setState(() {
              currentValue = value.toInt();
            });
            widget.onChange(value.toInt());
          },
        ),
      ],
    );
  }
}

class TextSetting extends StatefulWidget {
  final String initialValue;
  final String text;
  final ValueChanged<String> onChange;

  TextSetting({
    required this.initialValue,
    required this.text,
    required this.onChange,
  });

  @override
  _TextSettingState createState() => _TextSettingState();
}

class _TextSettingState extends State<TextSetting> {
  late TextEditingController controller = TextEditingController();

  // @override
  // void initState() {
  //   super.initState();
  //   controller = TextEditingController(text: widget.initialValue);
  // }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.text),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(hintText: widget.initialValue),
                controller: controller,
                
              ),
            ),
            IconButton(onPressed: ()=>widget.onChange(controller.text), icon: Icon(Icons.check_rounded))
          ],
        ),
      ],
    );
  }
}