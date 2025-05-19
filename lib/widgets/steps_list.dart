import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
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
            // Título
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Mostrar botón de Play si el Stepper no está visible
            Expanded(
              child: Container(
                child:
                    !_showStepper
                        ? Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showStepper = true; // Mostrar el Stepper
                              });
                              _speak(
                                widget.steps[_currentStep],
                              ); // Leer el primer paso
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Comenzar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 12.0,
                              ),
                            ),
                          ),
                        )
                        // Mostrar el Stepper si el usuario presionó el botón de Play
                        : NeumorphicCard(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(5),
                          withInnerShadow: true,
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
                                    title: Text(
                                      'Paso ${entry.key + 1}',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    content: Text(
                                      entry.value,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    isActive: _currentStep >= entry.key,
                                  );
                                }).toList(),
                            controlsBuilder: (context, details) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: details.onStepCancel,
                                    child: const Text('Anterior'),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        _currentStep == widget.steps.length - 1
                                            ? Navigator.of(context).pop
                                            : details.onStepContinue,
                                    child: Text(
                                      _currentStep == widget.steps.length - 1
                                          ? 'Salir'
                                          : 'Siguiente',
                                    ),
                                  ),
                                ],
                              );
                            },
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
