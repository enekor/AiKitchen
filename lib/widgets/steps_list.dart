import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StepsList extends StatefulWidget {
  final List<String> steps;
  final String title;

  const StepsList({
    super.key,
    required this.steps,
    this.title = 'Pasos a seguir',
  });

  @override
  State<StepsList> createState() => _StepsListState();
}

class _StepsListState extends State<StepsList> {
  int _currentStep = 0;
  late FlutterTts _flutterTts;
  bool _showStepper = false; // Controla si se muestra el Stepper

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();

    // Configuración opcional para asegurarte de que funcione correctamente
    _flutterTts.setLanguage("es-ES"); // Idioma español
    _flutterTts.setSpeechRate(0.5); // Velocidad de habla
    _flutterTts.setPitch(1.0); // Tono de voz
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Detener cualquier reproducción al salir
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (AppSingleton().useTTS) {
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título con ícono cooking
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.soup_kitchen,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mostrar botón de Play si el Stepper no está visible
            Expanded(
              child: Container(
                child:
                    !_showStepper
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 40,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showStepper = true; // Mostrar el Stepper
                                  });
                                  _speak(
                                    widget.steps[_currentStep],
                                  ); // Leer el primer paso
                                },
                                icon: const Icon(Icons.restaurant_menu),
                                label: const Text('Comenzar a cocinar'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: 16.0,
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${widget.steps.length} pasos para completar',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                        // Mostrar el Stepper si el usuario presionó el botón de Play
                        : NeumorphicCard(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          withInnerShadow: true,
                          child: Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme.copyWith(
                                primary: theme.colorScheme.secondary,
                              ),
                            ),
                            child: Stepper(
                              currentStep: _currentStep,
                              onStepTapped: (step) {
                                setState(() => _currentStep = step);
                                _speak(
                                  widget.steps[step],
                                ); // Leer el paso seleccionado
                              },
                              onStepContinue: () {
                                if (_currentStep < widget.steps.length - 1) {
                                  setState(() => _currentStep++);
                                  _speak(
                                    widget.steps[_currentStep],
                                  ); // Leer el siguiente paso
                                }
                              },
                              onStepCancel: () {
                                if (_currentStep > 0) {
                                  setState(() => _currentStep--);
                                  _speak(
                                    widget.steps[_currentStep],
                                  ); // Leer el paso anterior
                                }
                              },
                              steps:
                                  widget.steps.asMap().entries.map((entry) {
                                    return Step(
                                      title: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color:
                                                  _currentStep >= entry.key
                                                      ? theme
                                                          .colorScheme
                                                          .secondary
                                                      : theme
                                                          .colorScheme
                                                          .outline
                                                          .withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.restaurant,
                                              size: 16,
                                              color:
                                                  _currentStep >= entry.key
                                                      ? theme
                                                          .colorScheme
                                                          .onSecondary
                                                      : theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.6),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Paso ${entry.key + 1}',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      _currentStep >= entry.key
                                                          ? theme
                                                              .colorScheme
                                                              .primary
                                                          : theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.6),
                                                ),
                                          ),
                                        ],
                                      ),
                                      content: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color:
                                              _currentStep == entry.key
                                                  ? theme.colorScheme.primary
                                                      .withOpacity(0.05)
                                                  : theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                _currentStep == entry.key
                                                    ? theme.colorScheme.primary
                                                        .withOpacity(0.3)
                                                    : theme.colorScheme.outline
                                                        .withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          entry.value,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    _currentStep == entry.key
                                                        ? theme
                                                            .colorScheme
                                                            .onSurface
                                                        : theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                              ),
                                        ),
                                      ),
                                      isActive: _currentStep >= entry.key,
                                    );
                                  }).toList(),
                              controlsBuilder: (context, details) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (_currentStep > 0)
                                        ElevatedButton.icon(
                                          onPressed: details.onStepCancel,
                                          icon: const Icon(Icons.arrow_back),
                                          label: const Text('Anterior'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.surface,
                                            foregroundColor:
                                                theme.colorScheme.onSurface,
                                            side: BorderSide(
                                              color: theme.colorScheme.outline
                                                  .withOpacity(0.3),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox.shrink(),
                                      ElevatedButton.icon(
                                        onPressed:
                                            _currentStep ==
                                                    widget.steps.length - 1
                                                ? () {
                                                  // Show completion message
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          title: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .celebration,
                                                                color:
                                                                    theme
                                                                        .colorScheme
                                                                        .primary,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              const Text(
                                                                '¡Receta completada!',
                                                              ),
                                                            ],
                                                          ),
                                                          content: const Text(
                                                            '¡Felicidades! Has completado todos los pasos de la receta. ¡Disfruta de tu comida!',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
                                                              },
                                                              child: const Text(
                                                                'Finalizar',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                }
                                                : details.onStepContinue,
                                        icon: Icon(
                                          _currentStep ==
                                                  widget.steps.length - 1
                                              ? Icons.celebration
                                              : Icons.arrow_forward,
                                        ),
                                        label: Text(
                                          _currentStep ==
                                                  widget.steps.length - 1
                                              ? 'Finalizar'
                                              : 'Siguiente',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _currentStep ==
                                                      widget.steps.length - 1
                                                  ? theme.colorScheme.tertiary
                                                  : theme.colorScheme.primary,
                                          foregroundColor:
                                              _currentStep ==
                                                      widget.steps.length - 1
                                                  ? theme.colorScheme.onTertiary
                                                  : theme.colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
