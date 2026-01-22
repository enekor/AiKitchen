import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

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
    _flutterTts.setLanguage("es-ES");
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restaurant_menu_rounded, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                setState(() => _currentStep = 0);
                _speak(widget.steps[0]);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text('COMENZAR A COCINAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.steps.length,
      itemBuilder: (context, index) {
        final text = widget.steps[index];
        final isCurrent = _currentStep == index;
        final isDone = _currentStep > index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isCurrent 
              ? theme.colorScheme.primaryContainer 
              : (isDone ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : theme.colorScheme.surface),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(42),
              bottomLeft: Radius.circular(42),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(
              color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.1),
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${index + 1}',
                    style: GoogleFonts.robotoFlex(
                      textStyle: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isDone) Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? theme.colorScheme.onSurface.withOpacity(0.4) : theme.colorScheme.onSurface,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _currentStep--);
                          _speak(widget.steps[_currentStep]);
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('ANTERIOR'),
                      )
                    else
                      const SizedBox.shrink(),
                    
                    if (_currentStep < widget.steps.length - 1)
                      FilledButton(
                        onPressed: () {
                          setState(() => _currentStep++);
                          _speak(widget.steps[_currentStep]);
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('SIGUIENTE'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.celebration_rounded),
                        label: const Text('TERMINAR'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.tertiary,
                          foregroundColor: theme.colorScheme.onTertiary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
