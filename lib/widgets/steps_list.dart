import 'package:flutter/material.dart';

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
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Stepper(
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
                        title: Text('Paso ${entry.key + 1}'),
                        content: Text(entry.value),
                        isActive: _currentStep >= entry.key,
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
