import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class NeumorphicSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;
  final double thumbSize;
  final Duration animationDuration;
  final bool disabled;

  const NeumorphicSwitch({
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width = 50.0,
    this.height = 30.0,
    this.thumbSize = 24.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.disabled = false,
    Key? key,
  }) : super(key: key);

  @override
  _NeumorphicSwitchState createState() => _NeumorphicSwitchState();
}

class _NeumorphicSwitchState extends State<NeumorphicSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(NeumorphicSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    final inactiveColor =
        widget.inactiveColor ?? theme.colorScheme.surfaceVariant;

    return GestureDetector(
      onTap: () {
        if (!widget.disabled) {
          setState(() => _value = !_value);
          widget.onChanged(_value);
        }
      },
      child: AnimatedContainer(
        duration: widget.animationDuration,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height / 2),
          color: _value ? activeColor : inactiveColor,
          boxShadow: [
            // Sombra exterior (dependiendo del estado)
            if (!_value) ...[
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
              BoxShadow(
                color: theme.colorScheme.surface.withOpacity(0.7),
                blurRadius: 4,
                offset: const Offset(-2, -2),
              ),
            ],
            // Sombra interior cuando está activo
            if (_value)
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(-1, -1),
                inset: true,
              ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all((widget.height - widget.thumbSize) / 2),
          child: AnimatedAlign(
            duration: widget.animationDuration,
            alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: widget.thumbSize,
              height: widget.thumbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                boxShadow: [
                  if (!_value) ...[
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                    BoxShadow(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      blurRadius: 2,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                  if (_value)
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
