import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyGenerator extends StatefulWidget {
  ApiKeyGenerator({super.key, this.onChange, this.isPopup = false});
  Function(String)? onChange;
  bool isPopup = false;

  @override
  State<ApiKeyGenerator> createState() => _ApiKeyGeneratorState();
}

bool _isGeminiCardExpanded = false;
int _currentIndex = 0;

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
      isExpanded: widget.isPopup ? true : _isGeminiCardExpanded,
      text:
          'Gemini api key ${AppSingleton().apiKey != null ? 'aplicada' : 'no aplicada'}',
      icon: AppSingleton().apiKey == null
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
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            items: [
              _buildCarouselItem(
                'assets/guide/step1.jpg',
                '1. Ve a Google AI Studio inicia sesión y seleciona "Crear clave de API',
              ),
              _buildCarouselItem(
                'assets/guide/step2.jpg',
                '2. Selecciona "Crear proyecto" si no tienes uno ya existente',
              ),
              _buildCarouselItem(
                'assets/guide/step3.jpg',
                '3. Ponle un nombre a tu proyecto y dale a crear proyecto',
              ),
              _buildCarouselItem(
                'assets/guide/step4.jpg',
                '4. Una vez creado el proyecto, ponle un nombre cualquiera a la clave, y selecciona "Crear clave"',
              ),
              _buildCarouselItem(
                'assets/guide/step5.jpg',
                '5. Selecciona la clave que acabas de crear clicando en el texto marcado en la imagen',
              ),
              _buildCarouselItem(
                'assets/guide/step6.jpg',
                '6. Copia la API Key usando el botón remarcado en la imagen y pégala en el campo de abajo',
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [0, 1, 2, 3, 4, 5, 6].map((index) {
            return Container(
              width: 10.0,
              height: 10.0,
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index
                    ? Theme.of(context).colorScheme.primary.withAlpha(45)
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () =>
                _launchUrl('https://makersuite.google.com/app/apikey'),
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
            Toaster.showSuccess('API Key guardada');
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
