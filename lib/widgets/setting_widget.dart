import 'package:aikitchen/widgets/neumorphic_switch.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:flutter/material.dart';

class SwitchSetting extends StatefulWidget {
  final bool initialValue;
  final String text;
  final ValueChanged<bool> onChange;

  const SwitchSetting({
    super.key,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.text),
        NeumorphicSwitch(
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

  const ScrollbarSetting({
    super.key,
    required this.initialValue,
    required this.text,
    required this.onChange,
    required this.maxValue,
    required this.divisions,
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
  final Function(String) onSave;

  const TextSetting({
    super.key,
    required this.initialValue,
    required this.text,
    required this.onSave,
  });

  @override
  _TextSettingState createState() => _TextSettingState();
}

class _TextSettingState extends State<TextSetting> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.text),
        BasicTextInput(
          isInnerShadow: true,
          padding: EdgeInsets.all(2),
          onSearch: widget.onSave,
          initialValue: widget.initialValue,
          checkIcon: Icons.save_rounded,
          hint: "Borde pero gracioso",
        ),
      ],
    );
  }
}

class ListSetting extends StatefulWidget {
  final String initialValue;
  final String text;
  final List<String> options;
  final ValueChanged<String> onChange;

  const ListSetting({
    super.key,
    required this.initialValue,
    required this.text,
    required this.options,
    required this.onChange,
  });

  @override
  _ListSettingState createState() => _ListSettingState();
}

class _ListSettingState extends State<ListSetting> {
  late String currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: Text(widget.text)),
        Expanded(
          flex: 4,
          child: DropdownButton<String>(
            value: currentValue,
            items:
                widget.options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  currentValue = value;
                });
                widget.onChange(value);
              }
            },
          ),
        ),
      ],
    );
  }
}
