import 'package:aikitchen/screens/feature_selector.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/api_key_generator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _hasKey = AppSingleton().apiKey != null;
  }

  Future<void> _finish() async {
    await SharedPreferencesService.setBoolValue(
      SharedPreferencesKeys.onboardingComplete,
      true,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FeatureSelector()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Cabecera
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '¡Bienvenido a AI Kitchen!',
                      style: GoogleFonts.robotoFlex(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Solo falta un pequeño paso para\nempezar a cocinar con inteligencia artificial.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Widget de API key en modo popup (ya expandido)
              ApiKeyGenerator(
                isPopup: true,
                onChange: (value) {
                  final hasKey = value.trim().startsWith('AIza') &&
                      value.trim().length >= 35;
                  if (hasKey != _hasKey) {
                    setState(() => _hasKey = hasKey);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Botón principal
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _finish,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _hasKey ? '¡Empezar a cocinar!' : 'Configurar más tarde',
                    style: GoogleFonts.robotoFlex(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              if (!_hasKey) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Puedes configurarlo en cualquier momento desde Ajustes.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
