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

class MultiListSetting extends StatefulWidget {
  final List<String> initialValues;
  final String text;
  final List<String> options;
  final ValueChanged<List<String>> onChange;

  const MultiListSetting({
    super.key,
    required this.initialValues,
    required this.text,
    required this.options,
    required this.onChange,
  });

  @override
  _MultiListSettingState createState() => _MultiListSettingState();
}

class _MultiListSettingState extends State<MultiListSetting> {
  late List<String> selectedValues;

  @override
  void initState() {
    super.initState();
    selectedValues = List<String>.from(widget.initialValues);
  }

  void _showMultiSelectDialog() async {
    final List<String> tempSelected = List<String>.from(selectedValues);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(widget.text),
              content: SingleChildScrollView(
                child: Column(
                  children:
                      widget.options.map((option) {
                        return CheckboxListTile(
                          value: tempSelected.contains(option),
                          title: Text(option),
                          onChanged: (checked) {
                            setStateDialog(() {
                              if (checked == true) {
                                tempSelected.add(option);
                              } else {
                                tempSelected.remove(option);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedValues),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempSelected),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedValues = result;
      });
      widget.onChange(selectedValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: Text(widget.text)),
        Expanded(
          flex: 4,
          child: InkWell(
            onTap: _showMultiSelectDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedValues.isEmpty
                    ? 'Selecciona...'
                    : selectedValues.join(', '),
                style: TextStyle(
                  color:
                      selectedValues.isEmpty
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
