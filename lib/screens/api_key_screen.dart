import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gemini_service.dart';
import '../singleton/app_singleton.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'AI Kitchen',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const Text(
                'Para usar la aplicación, necesitas una API Key de Google AI Studio. Sigue estos pasos:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text('1. Ve a Google AI Studio'),
              const SizedBox(height: 8),
              const Text('2. Inicia sesión con tu cuenta de Google'),
              const SizedBox(height: 8),
              const Text('3. Ve a "Get API Key"'),
              const SizedBox(height: 8),
              const Text('4. Crea una nueva API Key o usa una existente'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _launchUrl('https://makersuite.google.com/app/apikey'),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ir a Google AI Studio'),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key de Gemini',
                  hintText: 'Pega aquí tu API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_apiKeyController.text.isNotEmpty) {
                    await AppSingleton().setApiKey(_apiKeyController.text);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Continuar'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
} 