import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final bool withInnerShadow;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double elevation;

  const NeumorphicCard({
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 15.0,
    this.withInnerShadow = false,
    this.color,
    this.onTap,
    this.onLongPress,
    this.elevation = 4.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.surface;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: cardColor,
            boxShadow:
                !withInnerShadow
                    ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                        offset: const Offset(-4, -4),
                        blurRadius: 8,
                      ),
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.5),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                        offset: const Offset(-4, -4),
                        blurRadius: 8,
                        inset: true,
                      ),
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.5),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                        inset: true,
                      ),
                    ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
