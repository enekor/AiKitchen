import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _promptController = TextEditingController();
  String? _response;
  bool _isLoading = false;

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/api_key');
  }

  Future<void> _generateResponse() async {
    setState(() {
      _isLoading = true;
      _response = null;
    });
    
    try {
      final response = await _geminiService.generateContent(
        _promptController.text,
      );
      setState(() {
        _response = response;
      });
    } on NoApiKeyException {
      setState(() {
        _response = 'Por favor, configura tu API Key de Gemini para poder usar la aplicación';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Kitchen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Escribe tu pregunta',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateResponse,
              child: const Text('Enviar'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_response != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _response!,
                    style: _response!.startsWith('Por favor, configura')
                        ? const TextStyle(color: Colors.red)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
} 