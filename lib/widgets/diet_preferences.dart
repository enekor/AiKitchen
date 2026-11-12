import 'package:aikitchen/models/tipo_receta.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Resumen siempre visible de la dieta y las alergias con las que se generan
/// las recetas. Tocarlo abre el editor. Antes esto vivía solo en Ajustes, a
/// varios toques de distancia, y era fácil olvidar que estaba activo.
class DietPreferencesBar extends StatelessWidget {
  const DietPreferencesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: AppSingleton().preferenciasCambiadas,
      builder: (context, _, _) {
        final tipos = AppSingleton().preferenciasCocina;
        final diet = tipos.first;
        final restrictions = tipos.skip(1).toList();

        return Material(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: AppRadius.medium,
          child: InkWell(
            borderRadius: AppRadius.medium,
            onTap: () => DietPreferencesSheet.show(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    restrictions.isEmpty
                        ? Icons.restaurant_rounded
                        : Icons.no_food_outlined,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dieta: ${diet.label}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        Text(
                          restrictions.isEmpty
                              ? 'Sin alergias ni restricciones'
                              : restrictions.map((t) => t.label).join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer
                                .withValues(alpha: 0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Cambiar',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Editor de dieta (una) y restricciones (varias). Guarda cada cambio al
/// momento: no hay botón de aceptar que olvidar.
class DietPreferencesSheet extends StatefulWidget {
  const DietPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const DietPreferencesSheet(),
    );
  }

  @override
  State<DietPreferencesSheet> createState() => _DietPreferencesSheetState();
}

class _DietPreferencesSheetState extends State<DietPreferencesSheet> {
  late TipoReceta _diet;
  late Set<TipoReceta> _restrictions;

  @override
  void initState() {
    super.initState();
    final tipos = AppSingleton().preferenciasCocina;
    _diet = tipos.first;
    _restrictions = tipos.skip(1).toSet();
  }

  void _save() {
    AppSingleton().setPreferenciasCocina = [
      _diet,
      for (final t in TipoReceta.restricciones)
        if (_restrictions.contains(t)) t,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          0,
          Spacing.xl,
          Spacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu forma de comer', style: theme.textTheme.headlineSmall),
            const SizedBox(height: Spacing.xs),
            Text(
              'Las recetas, el menú semanal y la lista de la compra que genere '
              'la IA lo tendrán en cuenta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text('Dieta', style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final diet in TipoReceta.dietas)
                  ChoiceChip(
                    label: Text(diet.label),
                    selected: _diet == diet,
                    onSelected: (_) {
                      setState(() => _diet = diet);
                      _save();
                    },
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'Alergias, intolerancias y cosas a evitar',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final restriction in TipoReceta.restricciones)
                  FilterChip(
                    label: Text(restriction.label),
                    selected: _restrictions.contains(restriction),
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? _restrictions.add(restriction)
                            : _restrictions.remove(restriction);
                      });
                      _save();
                    },
                  ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'La IA puede equivocarse. Con una alergia seria, revisa '
                    'siempre los ingredientes y el etiquetado de los productos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
