import 'package:aikitchen/file_handler.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class NeumorphicShareButton extends StatelessWidget {
  final Recipe recipe;
  final double size;
  final Color? color;
  final bool withInnerShadow;

  const NeumorphicShareButton({
    required this.recipe,
    this.size = 24,
    this.color,
    this.withInnerShadow = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? Colors.grey[600];
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _shareRecipe(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: theme.colorScheme.surface.withOpacity(0.9),
              blurRadius: 4,
              offset: const Offset(-2, -2),
            ),
            if (withInnerShadow)
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(-1, -1),
                inset: true,
              ),
          ],
        ),
        child: Icon(
          Icons.share,
          size: size,
          color: iconColor,
        ),
      ),
    );
  }

  Future<void> _shareRecipe(BuildContext context) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      await FileHandler.exportRecipe(recipe);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir: ${e.toString()}')),
      );
    }
  }
}