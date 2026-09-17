import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/ui/app_card.dart';
import 'package:flutter/material.dart';

/// Ajuste de interruptor, dentro de una `AppCard`.
class SwitchSetting extends StatefulWidget {
  final bool initialValue;
  final String text;
  final String? subtitle;
  final ValueChanged<bool> onChange;

  const SwitchSetting({
    super.key,
    required this.initialValue,
    required this.text,
    required this.onChange,
    this.subtitle,
  });

  @override
  State<SwitchSetting> createState() => _SwitchSettingState();
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
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.text, style: theme.textTheme.titleMedium),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: currentValue,
            onChanged: (value) {
              setState(() => currentValue = value);
              widget.onChange(value);
            },
          ),
        ],
      ),
    );
  }
}

/// Ajuste numérico entero mediante un deslizador, con el valor a la vista.
class ScrollbarSetting extends StatefulWidget {
  final int initialValue;
  final String text;
  final ValueChanged<int> onChange;
  final int divisions;
  final int maxValue;
  final int minValue;

  const ScrollbarSetting({
    super.key,
    required this.initialValue,
    required this.text,
    required this.onChange,
    required this.maxValue,
    required this.divisions,
    this.minValue = 1,
  });

  @override
  State<ScrollbarSetting> createState() => _ScrollbarSettingState();
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.text, style: theme.textTheme.titleMedium),
              Text(
                currentValue.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: currentValue.toDouble(),
            min: widget.minValue.toDouble(),
            max: widget.maxValue.toDouble(),
            divisions: widget.divisions,
            onChanged: (value) {
              setState(() => currentValue = value.toInt());
              widget.onChange(value.toInt());
            },
          ),
        ],
      ),
    );
  }
}

/// Ajuste numérico decimal, para velocidad de voz o creatividad de la IA.
class DecimalSliderSetting extends StatefulWidget {
  const DecimalSliderSetting({
    super.key,
    required this.initialValue,
    required this.text,
    required this.onChange,
    required this.min,
    required this.max,
    this.divisions,
    this.labelBuilder,
  });

  final double initialValue;
  final String text;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChange;
  final String Function(double value)? labelBuilder;

  @override
  State<DecimalSliderSetting> createState() => _DecimalSliderSettingState();
}

class _DecimalSliderSettingState extends State<DecimalSliderSetting> {
  late double currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.labelBuilder?.call(currentValue) ??
        currentValue.toStringAsFixed(1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.text, style: theme.textTheme.titleMedium),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: currentValue,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: (value) {
              setState(() => currentValue = value);
              widget.onChange(value);
            },
          ),
        ],
      ),
    );
  }
}

/// Ajuste de selección múltiple mediante una hoja inferior.
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
  State<MultiListSetting> createState() => _MultiListSettingState();
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
    return AppCard(
      onTap: _showSelectionModal,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.text, style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.xs),
                Text(
                  selectedValues.isEmpty ? 'Sin seleccionar' : selectedValues.join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.unfold_more_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  void _showSelectionModal() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SelectionSheet(
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

/// Ajuste de selección única mediante una hoja inferior.
class SingleListSetting extends StatefulWidget {
  final String initialValue;
  final String text;
  final List<String> options;
  final ValueChanged<String> onChange;

  const SingleListSetting({
    super.key,
    required this.initialValue,
    required this.text,
    required this.options,
    required this.onChange,
  });

  @override
  State<SingleListSetting> createState() => _SingleListSettingState();
}

class _SingleListSettingState extends State<SingleListSetting> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: _showSelectionModal,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.text, style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.xs),
                Text(
                  selectedValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.unfold_more_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  void _showSelectionModal() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SelectionSheet(
        text: widget.text,
        options: widget.options,
        initialSelected: [selectedValue],
        singleChoice: true,
      ),
    );
    if (result != null) {
      setState(() => selectedValue = result);
      widget.onChange(selectedValue);
    }
  }
}

/// Hoja de selección compartida por [SingleListSetting] y [MultiListSetting].
///
/// Si [singleChoice] es `true`, tocar una opción cierra la hoja y devuelve un
/// `String`; si no, hay que confirmar y devuelve un `List<String>`.
class _SelectionSheet extends StatefulWidget {
  const _SelectionSheet({
    required this.text,
    required this.options,
    required this.initialSelected,
    this.singleChoice = false,
  });

  final String text;
  final List<String> options;
  final List<String> initialSelected;
  final bool singleChoice;

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        // Alto máximo en vez de fijo: en apaisado la pantalla es baja y una
        // altura proporcional dejaba la hoja ocupando casi todo.
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.text, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Spacing.lg),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final isSelected = _selected.contains(option);
                return AppCard(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLowest,
                  onTap: () {
                    if (widget.singleChoice) {
                      Navigator.pop(context, option);
                      return;
                    }
                    setState(() {
                      isSelected ? _selected.remove(option) : _selected.add(option);
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        widget.singleChoice
                            ? (isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded)
                            : (isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined),
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Text(
                          option,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (!widget.singleChoice) ...[
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ajuste de texto libre, con guardado explícito.
///
/// Se usa para valores que el usuario teclea y conviene revisar antes de
/// aplicar, como la clave de API o la dirección del proxy.
class TextFieldSetting extends StatefulWidget {
  const TextFieldSetting({
    super.key,
    required this.initialValue,
    required this.text,
    required this.onSave,
    this.hint,
    this.helper,
    this.obscure = false,
  });

  final String initialValue;
  final String text;
  final String? hint;
  final String? helper;
  final bool obscure;
  final ValueChanged<String> onSave;

  @override
  State<TextFieldSetting> createState() => _TextFieldSettingState();
}

class _TextFieldSettingState extends State<TextFieldSetting> {
  late final TextEditingController _controller;
  late String _saved;
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _saved = widget.initialValue;
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _dirty => _controller.text != _saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.text, style: theme.textTheme.titleMedium),
          if (widget.helper != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              widget.helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _controller,
            obscureText: widget.obscure && _hidden,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      ),
                      tooltip: _hidden ? 'Mostrar' : 'Ocultar',
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              // Deshabilitado mientras no haya cambios, para que se vea de un
              // vistazo si queda algo por guardar.
              onPressed: _dirty
                  ? () {
                      final value = _controller.text.trim();
                      widget.onSave(value);
                      setState(() => _saved = value);
                    }
                  : null,
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
