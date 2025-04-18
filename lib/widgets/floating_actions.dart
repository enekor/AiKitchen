import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class NeumorphicActionButton {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isHighlighted;
  final Color? highlightColor;
  final String? tooltip;

  NeumorphicActionButton({
    required this.icon,
    required this.onPressed,
    this.isHighlighted = false,
    this.highlightColor,
    this.tooltip,
  });
}

class ModularFloatingActions extends StatelessWidget {
  final List<NeumorphicActionButton> actions;
  final double iconSize;
  final double spacing;
  final EdgeInsets padding;
  final double borderRadius;

  const ModularFloatingActions({
    required this.actions,
    this.iconSize = 20,
    this.spacing = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.borderRadius = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  actions.map((action) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: action == actions.last ? 0 : spacing,
                      ),
                      child: _buildActionButton(
                        context,
                        action,
                        iconSize: iconSize,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

Widget NeumorphicIconButton(
  BuildContext context,
  NeumorphicActionButton action,
) {
  return _buildActionButton(context, action);
}

Widget _buildActionButton(
  BuildContext context,
  NeumorphicActionButton action, {
  double iconSize = 20,
}) {
  final highlightColor =
      action.highlightColor ?? Theme.of(context).colorScheme.primary;
  final iconColor =
      action.isHighlighted ? highlightColor : Theme.of(context).iconTheme.color;

  return Tooltip(
    message: action.tooltip ?? '',
    child: GestureDetector(
      onTap: action.onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (!action.isHighlighted)
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            if (action.isHighlighted)
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(-1, -1),
                inset: true,
              ),
          ],
        ),
        child: Icon(action.icon, size: iconSize, color: iconColor),
      ),
    ),
  );
}
