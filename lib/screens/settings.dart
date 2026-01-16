import 'package:aikitchen/screens/logs_screen.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/animated_card.dart';
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

enum Personality {
  amistoso,
  profesional,
  casual,
  divertido,
  educativo,
  hiriente,
  bromista,
  sarcastico,
  entusiasta,
  neutral;

  String get displayName {
    String text = name.replaceAll('_', ' ').toLowerCase();
    return text[0].toUpperCase() + text.substring(1);
  }

  static List<String> get displayNames {
    return values.map((e) => e.displayName).toList();
  }

  static Personality fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => Personality.neutral,
    );
  }
}

enum Idioma {
  espanhol,
  gallego,
  andaluz,
  ingles,
  frances,
  aleman,
  italiano;

  String get displayName {
    String text = name.replaceAll('nh', 'ñ').toLowerCase();
    return text[0].toUpperCase() + text.substring(1);
  }

  static List<String> get displayNames {
    return values.map((e) => e.displayName).toList();
  }

  static Idioma fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => Idioma.espanhol,
    );
  }
}

enum TipoReceta {
  vegana,
  vegetariana,
  carnivora,
  pescetariana,
  sin_gluten,
  sin_lactosa,
  omnivora,
  sin_azucar,
  sin_huevo,
  sin_frutosSecos,
  sin_cereales,
  sin_legumbres;

  String get displayName {
    String text = name.replaceAll('_', ' ').toLowerCase();
    return text[0].toUpperCase() + text.substring(1);
  }

  static List<String> get displayNames {
    return values.map((e) => e.displayName).toList();
  }

  static TipoReceta fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => TipoReceta.omnivora,
    );
  }
}

class _SettingsState extends State<Settings> {
  bool _isSettingsCardExpanded = false;

  void _useTTS(bool value) {
    setState(() {
      AppSingleton().setUseTTS = value;
    });
  }

  String compareEnumValues(String value, List<String> options) {
    for (String option in options) {
      if (option.toLowerCase() == value.toLowerCase()) {
        return option;
      }
    }
    return options.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Configuración',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
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
                            },
                          ),
                          const SizedBox(height: 24),
                          SwitchSetting(
                            initialValue: AppSingleton().useTTS,
                            text: 'Leer las recetas en alto',
                            onChange: _useTTS,
                          ),
                          const SizedBox(height: 24),
                          MultiListSetting(
                            initialValues:
                                compareEnumValues(
                                  AppSingleton().personality,
                                  Personality.displayNames,
                                ).split(",").toSet().toList(),
                            text: '¿Qué tono de texto prefieres?',
                            options: Personality.displayNames,
                            onChange: (List<String> values) {
                              final personalities =
                                  values
                                      .map(
                                        (value) =>
                                            Personality.fromDisplayName(value),
                                      )
                                      .toList();
                              setState(() {
                                AppSingleton().setPersonality = personalities
                                    .map((p) => p.name)
                                    .toList()
                                    .join(",");
                              });
                              Toaster.showToast(
                                'El tono de texto se ha cambiado a ${personalities.map((p) => p.displayName).join(", ")}',
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          MultiListSetting(
                            initialValues:
                                compareEnumValues(
                                  AppSingleton().idioma,
                                  Idioma.displayNames,
                                ).split(",").toSet().toList(),
                            text: '¿En qué idioma quieres las recetas?',
                            options: Idioma.displayNames,
                            onChange: (List<String> values) {
                              final idioma = Idioma.fromDisplayName(
                                values.first,
                              );
                              setState(() {
                                AppSingleton().setIdioma = idioma.name;
                              });
                              Toaster.showToast(
                                'El idioma se ha cambiado a ${idioma.displayName}',
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          MultiListSetting(
                            initialValues:
                                compareEnumValues(
                                  AppSingleton().tipoReceta,
                                  TipoReceta.displayNames,
                                ).split(",").toSet().toList(),
                            text: '¿Qué tipos de recetas harás?',
                            options: TipoReceta.displayNames,
                            onChange: (List<String> value) {
                              final tipoReceta = TipoReceta.fromDisplayName(
                                value.first,
                              );
                              setState(() {
                                AppSingleton().setTipoReceta = tipoReceta.name;
                              });
                              Toaster.showToast(
                                'El tipo de receta se ha cambiado a ${tipoReceta.displayName}',
                              );
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LogsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.terminal_rounded),
                      label: const Text('Ver Logs del sistema'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
