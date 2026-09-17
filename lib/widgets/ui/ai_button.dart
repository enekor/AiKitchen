import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Botón de acción de generación por IA.
///
/// Usa el acento de IA del tema en lugar del color primario, para que quede
/// claro que la acción invoca al modelo de lenguaje y no es una operación
/// local instantánea.
class AiButton extends StatelessWidget {
  const AiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.auto_awesome_rounded,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final accent = context.aiAccent;

    final button = FilledButton.icon(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent.color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: accent.color.withValues(alpha: 0.5),
      ),
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Insignia pequeña de "Generado con IA", usada en tarjetas de receta.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label = 'IA'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = context.aiAccent;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: accent.container,
        borderRadius: AppRadius.capsule,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: accent.onContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: accent.onContainer),
          ),
        ],
      ),
    );
  }
}
