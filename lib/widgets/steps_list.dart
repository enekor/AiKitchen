import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Pasos de preparación numerados, con el actual resaltado y los anteriores
/// marcados como hechos. Si la lectura por voz está activa en Ajustes, cada
/// paso se lee al mostrarse, a la velocidad configurada.
class StepsList extends StatefulWidget {
  final List<String> steps;

  const StepsList({super.key, required this.steps});

  @override
  State<StepsList> createState() => _StepsListState();
}

class _StepsListState extends State<StepsList> {
  int _currentStep = -1;
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('es-ES');
    _flutterTts.setSpeechRate(AppSingleton().velocidadVoz * 0.5);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    if (AppSingleton().useTTS) {
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentStep == -1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: Spacing.xl),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _currentStep = 0);
                  _speak(widget.steps[0]);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Comenzar a cocinar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < widget.steps.length; index++) ...[
          if (index > 0) const SizedBox(height: Spacing.md),
          _StepCard(
            number: index + 1,
            text: widget.steps[index],
            isCurrent: _currentStep == index,
            isDone: _currentStep > index,
            isLast: index == widget.steps.length - 1,
            onPrevious: index > 0
                ? () {
                    setState(() => _currentStep--);
                    _speak(widget.steps[_currentStep]);
                  }
                : null,
            onNext: () {
              setState(() => _currentStep++);
              if (_currentStep < widget.steps.length) {
                _speak(widget.steps[_currentStep]);
              }
            },
            onFinish: () => Navigator.pop(context),
          ),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.text,
    required this.isCurrent,
    required this.isDone,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  final int number;
  final String text;
  final bool isCurrent;
  final bool isDone;
  final bool isLast;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$number',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: isCurrent
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (isDone)
                Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isCurrent
                  ? theme.colorScheme.onPrimaryContainer
                  : (isDone
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface),
              decoration: isDone && !isCurrent ? TextDecoration.lineThrough : null,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(height: Spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onPrevious != null)
                  TextButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Anterior'),
                  )
                else
                  const SizedBox.shrink(),
                if (!isLast)
                  FilledButton(onPressed: onNext, child: const Text('Siguiente'))
                else
                  FilledButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.celebration_rounded),
                    label: const Text('Terminar'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
