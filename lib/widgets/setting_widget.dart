import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        // Forma asimétrica asimétrica característica de M3 Expressive
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.text,
              style: GoogleFonts.robotoFlex(
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          Switch(
            value: currentValue,
            onChanged: (bool value) {
              setState(() => currentValue = value);
              widget.onChange(value);
            },
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(42),
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: GoogleFonts.robotoFlex(
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 24, // Barra gruesa M3 Expressive (estilo imagen 2)
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.1),
              thumbColor: theme.colorScheme.onPrimary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Pulgar invisible o integrado
              overlayColor: Colors.transparent,
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: currentValue.toDouble(),
              min: 1,
              max: widget.maxValue.toDouble(),
              divisions: widget.divisions,
              onChanged: (double value) {
                setState(() => currentValue = value.toInt());
                widget.onChange(value.toInt());
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              currentValue.toString(),
              style: GoogleFonts.robotoFlex(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
            ),
          )
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _showSelectionModal,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
          borderRadius: const BorderRadius.all(Radius.circular(42)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.text,
                    style: GoogleFonts.robotoFlex(
                      textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedValues.isEmpty ? 'Seleccionar' : selectedValues.join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.unfold_more_rounded, color: theme.colorScheme.secondary),
          ],
        ),
      ),
    );
  }

  void _showSelectionModal() async {
    final theme = Theme.of(context);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExpressiveSelectionModal(
        text: widget.text,
        options: widget.options,
        initialSelected: selectedValues,
      ),
    );
    if (result != null) {
      setState(() => selectedValues = result);
      widget.onChange(selectedValues);
    }
  }
}

class _ExpressiveSelectionModal extends StatefulWidget {
  final String text;
  final List<String> options;
  final List<String> initialSelected;

  const _ExpressiveSelectionModal({required this.text, required this.options, required this.initialSelected});

  @override
  State<_ExpressiveSelectionModal> createState() => _ExpressiveSelectionModalState();
}

class _ExpressiveSelectionModalState extends State<_ExpressiveSelectionModal> {
  late List<String> tempSelected;

  @override
  void initState() {
    super.initState();
    tempSelected = List<String>.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 48, height: 6, decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(3))),
          ),
          const SizedBox(height: 32),
          Text(widget.text, style: GoogleFonts.robotoFlex(textStyle: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final isSelected = tempSelected.contains(option);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => isSelected ? tempSelected.remove(option) : tempSelected.add(option)),
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          Icon(isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Text(option, style: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : null, fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, tempSelected),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
