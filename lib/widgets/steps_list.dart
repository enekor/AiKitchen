import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;

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
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                if (_currentStep < widget.steps.length - 1) {
                  setState(() => _currentStep++);
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
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
