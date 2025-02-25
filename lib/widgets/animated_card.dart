import 'package:flutter/material.dart';

class AnimatedCard extends StatefulWidget {
  final String? text;
  final Icon? icon;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? alwaysVisible;

  const AnimatedCard({
    super.key,
    this.text,
    this.icon,
    required this.children,
    this.trailing,
    this.alwaysVisible
  });

  @override
  State<AnimatedCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<AnimatedCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Bordes redondeados
      ),
      elevation: 4, // Sombra
      color: Theme.of(context).colorScheme.surfaceContainerHighest, // Color dinámico
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera del card siempre visible
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
                      turns: _isExpanded ? 0.5 : 0,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
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
                crossFadeState: _isExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
              ),
              if (widget.trailing != null)
                widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
} 

