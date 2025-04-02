import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart';

class NeumorphicSelections extends StatefulWidget {
  const NeumorphicSelections({
    super.key,
    required this.items,
    required this.onSelected,
    this.isInner = false,
    this.padding = const EdgeInsets.all(8),
    this.margin = const EdgeInsets.all(8),
  });
  final List<String> items;
  final Function(int) onSelected;
  final bool isInner;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  State<NeumorphicSelections> createState() => _NeumorphicSelectionsState();
}

class _NeumorphicSelectionsState extends State<NeumorphicSelections> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: widget.padding,
      margin: widget.margin,
      withInnerShadow: widget.isInner,
      child: Row(
        children:
            widget.items.map((item) {
              int index = widget.items.indexOf(item);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selected = index;
                    });
                    widget.onSelected(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          selected == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        item,
                        style: TextStyle(
                          color:
                              selected == index
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
