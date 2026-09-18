import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Punto de partida en curso de la preparación, para poder arrancarlo desde
/// fuera de la lista, por ejemplo desde la tarjeta de "Lectura en voz alta"
/// de la cabecera de la receta.
class StepsController extends ChangeNotifier {
  int _currentStep = -1;
  int _startToken = 0;

  int get currentStep => _currentStep;
  bool get started => _currentStep != -1;

  /// Cambia en cada pulsación de "Iniciar". Sirve para que volver a pulsarlo
  /// vuelva a leer el primer paso en voz alta, aunque ya estuviéramos en él y
  /// por tanto el número de paso no cambie.
  int get startToken => _startToken;

  void start() {
    _currentStep = 0;
    _startToken++;
    notifyListeners();
  }

  void goTo(int step) {
    _currentStep = step;
    notifyListeners();
  }
}

/// Pasos de preparación numerados, con el actual resaltado y los anteriores
/// marcados como hechos. Si la lectura por voz está activa en Ajustes, cada
/// paso se lee al mostrarse, a la velocidad configurada.
class StepsList extends StatefulWidget {
  final List<String> steps;
  final StepsController? controller;

  const StepsList({super.key, required this.steps, this.controller});

  @override
  State<StepsList> createState() => _StepsListState();
}

class _StepsListState extends State<StepsList> {
  late final StepsController _controller;
  late final bool _ownsController;
  late FlutterTts _flutterTts;
  int _lastSpoken = -2;
  int _lastStartToken = -1;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? StepsController();
    _controller.addListener(_onControllerChanged);

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('es-ES');
    _flutterTts.setSpeechRate(AppSingleton().velocidadVoz * 0.5);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});

    final step = _controller.currentStep;
    if (step < 0 || step >= widget.steps.length) return;

    // Se lee al cambiar de paso, y también al volver a pulsar "Iniciar"
    // aunque sea sobre el mismo paso.
    final restarted = _controller.startToken != _lastStartToken;
    if (step != _lastSpoken || restarted) {
      _lastSpoken = step;
      _lastStartToken = _controller.startToken;
      _speak(widget.steps[step]);
    }
  }

  void _speak(String text) async {
    if (AppSingleton().useTTS) {
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = _controller.currentStep;

    if (currentStep == -1) {
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
                onPressed: _controller.start,
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
            isCurrent: currentStep == index,
            isDone: currentStep > index,
            isLast: index == widget.steps.length - 1,
            onPrevious: index > 0 ? () => _controller.goTo(index - 1) : null,
            onNext: () => _controller.goTo(index + 1),
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
