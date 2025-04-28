import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/api_key_generator.dart';
import 'package:aikitchen/widgets/setting_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../singleton/app_singleton.dart';

class Settings extends StatefulWidget {
  Settings({super.key, this.isNotApiKeySetted = false});
  bool isNotApiKeySetted;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isGeminiCardExpanded = false;
  bool _isSettingsCardExpanded = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 15,
                  children: [
                    ApiKeyGenerator(),
                    if (!widget.isNotApiKeySetted)
                      AnimatedCard(
                        isExpanded: _isSettingsCardExpanded,
                        text: 'Ajustes de la app',
                        icon: const Icon(Icons.settings_rounded),
                        onTap: () {
                          setState(() {
                            _isSettingsCardExpanded = !_isSettingsCardExpanded;
                          });
                        },
                        children: [
                          ScrollbarSetting(
                            initialValue: AppSingleton().numRecetas,
                            maxValue: 5,
                            divisions: 4,
                            text: '¿Cantas recetas quieres ver?',
                            onChange: (int value) {
                              setState(() {
                                AppSingleton().setNumRecetas = value;
                              });
                              SharedPreferencesService.setStringValue(
                                SharedPreferencesKeys.numRecetas,
                                value.toString(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          TextSetting(
                            initialValue: AppSingleton().personality,
                            text: '¿Qué tono de texto prefieres?',
                            onSave: (String value) {
                              setState(() {
                                AppSingleton().setPersonality = value;
                              });
                              SharedPreferencesService.setStringValue(
                                SharedPreferencesKeys.tonoTextos,
                                value,
                              );

                              Toaster.showToast(
                                'El tono de texto se ha cambiado a $value',
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          TextSetting(
                            initialValue: AppSingleton().idioma,
                            text: '¿En qué idioma quieres las recetas?',
                            onSave: (String value) {
                              setState(() {
                                AppSingleton().setIdioma = value;
                              });
                              SharedPreferencesService.setStringValue(
                                SharedPreferencesKeys.idioma,
                                value,
                              );

                              Toaster.showToast(
                                'El idioma se ha cambiado a $value',
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          TextSetting(
                            initialValue: AppSingleton().tipoReceta,
                            text: '¿Que tipos de recetas haras?',
                            onSave: (String value) {
                              setState(() {
                                AppSingleton().setPersonality = value;
                              });
                              SharedPreferencesService.setStringValue(
                                SharedPreferencesKeys.tipoReceta,
                                value,
                              );

                              Toaster.showToast(
                                'El tipo de receta se ha cambiado a $value',
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
