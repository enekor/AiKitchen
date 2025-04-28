import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyGenerator extends StatefulWidget {
  ApiKeyGenerator({super.key, this.onChange});
  Function(String)? onChange;

  @override
  State<ApiKeyGenerator> createState() => _ApiKeyGeneratorState();
}

bool _isGeminiCardExpanded = false;

class _ApiKeyGeneratorState extends State<ApiKeyGenerator> {
  @override
  Widget build(BuildContext context) {
    Future<void> _launchUrl(String url) async {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace')),
          );
        }
      }
    }

    Widget _buildCarouselItem(String imagePath, String caption) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 5.0),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
            SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return AnimatedCard(
      isExpanded: _isGeminiCardExpanded,
      text:
          'Gemini api key ${AppSingleton().apiKey != null ? 'aplicada' : 'no aplicada'}',
      icon:
          AppSingleton().apiKey == null
              ? const Icon(Icons.api_rounded)
              : const Icon(Icons.check_circle_rounded, color: Colors.green),
      onTap: () {
        setState(() {
          _isGeminiCardExpanded = !_isGeminiCardExpanded;
        });
      },
      children: [
        const Text(
          'Para usar la aplicación, necesitas una API Key de Google AI Studio. Sigue estos pasos:',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Carrusel de imágenes integrado
        Container(
          height: 300, // Ajusta según necesites
          child: CarouselSlider(
            options: CarouselOptions(
              height: 280,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              autoPlay: false,
              pageSnapping: true,
              padEnds: true,
            ),
            items: [
              _buildCarouselItem(
                'assets/guide/step1.png',
                '1. Ve a Google AI Studio e inicia sesión',
              ),
              _buildCarouselItem(
                'assets/guide/step2.png',
                '2. Haz clic en "Get API Key" en el menú',
              ),
              _buildCarouselItem(
                'assets/guide/step3.png',
                '3. Crea una nueva API Key',
              ),
              _buildCarouselItem(
                'assets/guide/step4.png',
                '4. Copia la API Key y pégala en la app',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed:
                () => _launchUrl('https://makersuite.google.com/app/apikey'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Obtener API Key'),
          ),
        ),
        const SizedBox(height: 48),
        BasicTextInput(
          onSearch: (apiKey) {
            setState(() {
              AppSingleton().setApiKey(apiKey);
            });
            Toaster.showToast('API Key guardada');
            Navigator.pop(context);
          },
          hint: 'Pega aquí tu API Key',
          initialValue: AppSingleton().apiKey ?? '',
          checkIcon: Icons.save_rounded,
          padding: const EdgeInsets.all(2),
          isInnerShadow: true,
          onChanged: widget.onChange,
        ),
      ],
    );
  }
}
