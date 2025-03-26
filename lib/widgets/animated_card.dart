import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class AnimatedCard extends StatefulWidget {
  final String? text;
  final Icon? icon;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? alwaysVisible;
  bool isExpanded;
  final bool isInnerShadow;
  final VoidCallback? onTap;

  AnimatedCard({
    super.key,
    this.text,
    this.icon,
    required this.children,
    this.trailing,
    this.alwaysVisible,
    this.isExpanded = false,
    this.isInnerShadow = false,
    this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<AnimatedCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          if (widget.isInnerShadow)
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              offset: const Offset(-4, -4),
              blurRadius: 8,
              inset: true,
            ),
          if (widget.isInnerShadow)
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
              offset: const Offset(4, 4),
              blurRadius: 8,
              inset: true,
            ),
          if (!widget.isInnerShadow)
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
          if (!widget.isInnerShadow) BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
        ],
      ),
      
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera del card siempre visible
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
              ),

              child: InkWell(
                onTap: () {
                  if (widget.onTap != null) widget.onTap!();
                },
                child:
                    widget.alwaysVisible ??
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          widget.icon ?? const Icon(Icons.info),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.text ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 300),
                            turns: widget.isExpanded ? 0.5 : 0,
                            child: const Icon(Icons.keyboard_arrow_down),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
            // Contenido expandible
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: Container(),
              secondChild: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.children,
                ),
              ),
              crossFadeState:
                  widget.isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      )
    );
  }
}
