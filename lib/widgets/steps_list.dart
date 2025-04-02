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
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
          // Stepper
          NeumorphicCard(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(5),
            withInnerShadow: true,
            child: Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) {
                setState(() => _currentStep = step);
                _speak(widget.steps[step]); // Leer el paso seleccionado
              },
              onStepContinue: () {
                if (_currentStep < widget.steps.length - 1) {
                  setState(() => _currentStep++);
                  _speak(widget.steps[_currentStep]); // Leer el siguiente paso
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                  _speak(widget.steps[_currentStep]); // Leer el paso anterior
                }
              },
              steps:
                  widget.steps.asMap().entries.map((entry) {
                    return Step(
                      title: Text(
                        'Paso ${entry.key + 1}',
                        style: theme.textTheme.bodyLarge?.copyWith(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Atrás'),
                    ),
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Siguiente'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
