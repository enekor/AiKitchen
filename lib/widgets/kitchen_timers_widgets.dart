import 'package:aikitchen/services/kitchen_timers.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/utils/step_durations.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

/// Temporizadores en marcha, con su cuenta atrás. No ocupa nada si no hay
/// ninguno. Tocar uno lo pausa o lo reanuda; la cruz lo quita.
class TimersBar extends StatelessWidget {
  const TimersBar({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final timers = KitchenTimers.instance;

    return ListenableBuilder(
      listenable: timers,
      builder: (context, _) {
        if (timers.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: padding,
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final timer in timers.timers) _TimerChip(timer: timer),
            ],
          ),
        );
      },
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.timer});

  final KitchenTimer timer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timers = KitchenTimers.instance;

    final Color background;
    final Color foreground;
    final IconData icon;
    final String status;

    if (timer.isFinished) {
      background = theme.colorScheme.errorContainer;
      foreground = theme.colorScheme.onErrorContainer;
      icon = Icons.alarm_on_rounded;
      status = '¡Listo!';
    } else if (timer.isPaused) {
      background = theme.colorScheme.surfaceContainerHigh;
      foreground = theme.colorScheme.onSurfaceVariant;
      icon = Icons.pause_rounded;
      status = formatCountdown(timers.remaining(timer));
    } else {
      background = theme.colorScheme.secondaryContainer;
      foreground = theme.colorScheme.onSecondaryContainer;
      icon = Icons.timer_outlined;
      status = formatCountdown(timers.remaining(timer));
    }

    return Semantics(
      label: 'Temporizador ${timer.label}, $status',
      child: InputChip(
        backgroundColor: background,
        side: BorderSide.none,
        avatar: Icon(icon, size: 18, color: foreground),
        label: Text(
          '${timer.label} · $status',
          style: theme.textTheme.labelLarge?.copyWith(
            color: foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        tooltip: timer.isFinished
            ? 'Quitar'
            : (timer.isPaused ? 'Reanudar' : 'Pausar'),
        onPressed: timer.isFinished
            ? () => timers.cancel(timer)
            : () => timers.togglePause(timer),
        deleteIcon: Icon(Icons.close_rounded, size: 18, color: foreground),
        deleteButtonTooltipMessage: 'Quitar temporizador',
        onDeleted: () => timers.cancel(timer),
      ),
    );
  }
}

/// Un botón por cada tiempo que aparezca en el texto de un paso ("hornea 20
/// minutos"), que arranca un temporizador con ese tiempo.
class StepTimerButtons extends StatelessWidget {
  const StepTimerButtons({
    super.key,
    required this.text,
    required this.stepNumber,
  });

  final String text;
  final int stepNumber;

  @override
  Widget build(BuildContext context) {
    final durations = StepDurations.find(text);
    if (durations.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final found in durations)
          ActionChip(
            avatar: const Icon(Icons.timer_outlined, size: 18),
            label: Text('Temporizador ${found.label}'),
            onPressed: () {
              KitchenTimers.instance.start(
                'Paso $stepNumber · ${found.label}',
                found.duration,
              );
              Toaster.showSuccess('Temporizador de ${found.label} en marcha');
            },
          ),
      ],
    );
  }
}
