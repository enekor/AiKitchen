import 'package:aikitchen/widgets/floating_actions.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class TextInput extends StatefulWidget {
  TextInput({
    super.key,
    required this.onSearch,
    required this.isLoading,
    required this.prefixIcon,
    this.hint,
    this.onFav,
    this.isFavorite,
    this.isInnerShadow = false,
  });

  Function(String) onSearch;
  Function? onFav;
  bool isLoading;
  bool? isFavorite;
  Icon prefixIcon;
  String? hint;
  bool isInnerShadow = false;

  @override
  _TextInputState createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
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
          if (!widget.isInnerShadow)
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: widget.prefixIcon,
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(-4, -4),
                    inset: true,
                  ),
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.5),
                    blurRadius: 3,
                    offset: const Offset(4, 4),
                    inset: true,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    labelText: null,
                    hintText: widget.hint,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon:
                widget.isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.search),
            onPressed: () {
              widget.onSearch(nameController.text);
            },
          ),
          if (widget.isFavorite != null && widget.onFav != null)
            IconButton(
              icon: Icon(
                widget.isFavorite! ? Icons.favorite : Icons.favorite_border,
              ),
              onPressed: () {
                widget.onFav!();
              },
            ),
        ],
      ),
    );
  }
}

class BasicTextInput extends StatefulWidget {
  BasicTextInput({
    super.key,
    required this.onSearch,
    this.checkIcon,
    this.hint,
    this.isInnerShadow = false,
    this.padding = const EdgeInsets.all(8),
    this.margin = const EdgeInsets.all(8),
    this.initialValue,
  });

  Function(String) onSearch;
  IconData? checkIcon;
  String? hint;
  bool isInnerShadow = false;
  EdgeInsets padding = const EdgeInsets.all(8);
  EdgeInsets margin = const EdgeInsets.all(8);
  String? initialValue;

  @override
  State<BasicTextInput> createState() => _BasicTextInputState();
}

class _BasicTextInputState extends State<BasicTextInput> {
  final _textConstroller = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _textConstroller.text = widget.initialValue ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: widget.padding,
      margin: widget.margin,
      withInnerShadow: widget.isInnerShadow,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: TextField(
                controller: _textConstroller,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  labelText: null,
                  hintText: widget.hint,
                ),
                onSubmitted: widget.onSearch,
              ),
            ),
          ),
          NeumorphicIconButton(
            context,
            NeumorphicActionButton(
              icon: widget.checkIcon ?? Icons.check,
              onPressed: () {
                widget.onSearch(_textConstroller.text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
