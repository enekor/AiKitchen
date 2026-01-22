import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IngredientsList extends StatelessWidget {
  final List<String> ingredients;

  const IngredientsList({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: ingredients.map((ingredient) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(28),
          ),
          border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.onSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                ingredient,
                style: GoogleFonts.robotoFlex(
                  textStyle: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
