import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/kitchen_timers_widgets.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Modo cocina: un paso por pantalla, con letra grande, la pantalla siempre
/// encendida y botones amplios para usarlo con las manos ocupadas.
///
/// Si la lectura en voz alta está activa, cada paso se lee al llegar a él.
/// Los tiempos del texto ofrecen un temporizador con un toque, y en teclado
/// las flechas y la barra espaciadora pasan de paso.
class CookingModeScreen extends StatefulWidget {
  const CookingModeScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  final PageController _pages = PageController();
  late final IngredientsController _ingredients =
      IngredientsController(widget.recipe.ingredientes.length);
  final FlutterTts _tts = FlutterTts();
  late bool _voice = AppSingleton().useTTS;
  int _step = 0;

  List<String> get _steps => widget.recipe.preparacion;
  bool get _isLast => _step == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _keepScreenOn(true);
    _tts.setLanguage('es-ES');
    _tts.setSpeechRate(AppSingleton().velocidadVoz * 0.5);
    WidgetsBinding.instance.addPostFrameCallback((_) => _readStep());
  }

  @override
  void dispose() {
    _keepScreenOn(false);
    _tts.stop();
    _pages.dispose();
    _ingredients.dispose();
    super.dispose();
  }

  /// En algunas plataformas no hay forma de impedir que se apague la
  /// pantalla. No es motivo para no dejar cocinar.
  Future<void> _keepScreenOn(bool on) async {
    try {
      on ? await WakelockPlus.enable() : await WakelockPlus.disable();
    } catch (e) {
      debugPrint('No se pudo cambiar el bloqueo de pantalla: $e');
    }
  }

  void _readStep({bool force = false}) {
    if (_steps.isEmpty || (!_voice && !force)) return;
    _tts.stop();
    _tts.speak('Paso ${_step + 1}. ${_steps[_step]}');
  }

  void _toggleVoice() {
    setState(() {
      _voice = !_voice;
      // Mismo ajuste que en Ajustes y en la ficha de la receta.
      AppSingleton().setUseTTS = _voice;
    });
    _voice ? _readStep() : _tts.stop();
  }

  void _goTo(int step) {
    if (step < 0 || step >= _steps.length) return;
    _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _next() => _isLast ? _finish() : _goTo(_step + 1);
  void _previous() => _goTo(_step - 1);

  void _onPageChanged(int step) {
    setState(() => _step = step);
    _readStep();
  }

  Future<void> _finish() async {
    _tts.stop();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded),
        title: const Text('¡A la mesa!'),
        content: Text('Has terminado "${widget.recipe.nombre}". ¡Que aproveche!'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  void _showIngredients() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            0,
            Spacing.lg,
            Spacing.xl,
          ),
          children: [
            Text(
              'Ingredientes · ${widget.recipe.raciones} raciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.md),
            IngredientsList(
              ingredients: widget.recipe.ingredientes,
              controller: _ingredients,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.recipe.nombre)),
        body: const EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Esta receta no tiene pasos',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _showIngredients,
            tooltip: 'Ver ingredientes',
            icon: const Icon(Icons.format_list_bulleted_rounded),
          ),
          IconButton(
            onPressed: _toggleVoice,
            tooltip: _voice ? 'Desactivar lectura en voz alta' : 'Activar lectura en voz alta',
            icon: Icon(_voice ? Icons.volume_up_rounded : Icons.volume_off_rounded),
          ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
          const SingleActivator(LogicalKeyboardKey.space): _next,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _previous,
        },
        child: Focus(
          autofocus: true,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.sm,
                    Spacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paso ${_step + 1} de ${_steps.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      ClipRRect(
                        borderRadius: AppRadius.small,
                        child: LinearProgressIndicator(
                          value: (_step + 1) / _steps.length,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const TimersBar(
                  padding: EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    0,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _steps.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) => _StepPage(
                      number: index + 1,
                      text: _steps[index],
                    ),
                  ),
                ),
                _Controls(
                  canGoBack: _step > 0,
                  isLast: _isLast,
                  onPrevious: _previous,
                  onRepeat: () => _readStep(force: true),
                  onNext: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text('$number', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                text,
                style: theme.textTheme.headlineSmall?.copyWith(height: 1.4),
              ),
              const SizedBox(height: Spacing.xl),
              StepTimerButtons(text: text, stepNumber: number),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botones grandes al pie, al alcance del pulgar.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.canGoBack,
    required this.isLast,
    required this.onPrevious,
    required this.onRepeat,
    required this.onNext,
  });

  final bool canGoBack;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback onRepeat;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size.fromHeight(56);

    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canGoBack ? onPrevious : null,
              style: OutlinedButton.styleFrom(minimumSize: buttonSize),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Anterior'),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          IconButton.filledTonal(
            onPressed: onRepeat,
            tooltip: 'Leer el paso otra vez',
            iconSize: 28,
            icon: const Icon(Icons.replay_rounded),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              style: FilledButton.styleFrom(minimumSize: buttonSize),
              icon: Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(isLast ? 'Terminar' : 'Siguiente'),
            ),
          ),
        ],
      ),
    );
  }
}
