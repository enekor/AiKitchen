import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart';

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
  final theme = Theme.of(context);
  final highlightColor = action.highlightColor ?? theme.colorScheme.primary;
  final iconColor =
      action.isHighlighted ? highlightColor : theme.iconTheme.color;

  return Tooltip(
    message: action.tooltip ?? '',
    child: GestureDetector(
      onTap: action.onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              action.isHighlighted
                  ? highlightColor.withOpacity(0.1)
                  : theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              blurRadius: action.isHighlighted ? 1 : 3,
              offset:
                  action.isHighlighted
                      ? const Offset(0, 1)
                      : const Offset(2, 2),
            ),
          ],
        ),
        child: Icon(action.icon, size: iconSize, color: iconColor),
      ),
    ),
  );
}
