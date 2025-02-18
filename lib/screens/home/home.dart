import 'package:aikitchen/services/auth_service.dart';
import 'package:aikitchen/services/gemini_service.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  String? _response;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _geminiService.getStoredApiKey();
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
      await _geminiService.setApiKey(apiKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Kitchen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key de Gemini',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    await _geminiService.setApiKey(_apiKeyController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API Key guardada')),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Escribe tu pregunta',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final response = await _geminiService.generateContent(
                  _promptController.text,
                );
                setState(() {
                  _response = response;
                });
              },
              child: const Text('Enviar'),
            ),
            const SizedBox(height: 16),
            if (_response != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_response!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    super.dispose();
  }
}