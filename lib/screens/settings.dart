import 'package:aikitchen/screens/logs_screen.dart';
import 'package:aikitchen/widgets/setting_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import '../singleton/app_singleton.dart';

class Settings extends StatefulWidget {
  Settings({super.key, this.isNotApiKeySetted = false});
  bool isNotApiKeySetted;

  @override
  State<Settings> createState() => _SettingsState();
}

enum Personality {
  amistoso, profesional, casual, divertido, educativo, hiriente, bromista, sarcastico, entusiasta, neutral;

  String get displayName {
    String text = name.replaceAll('_', ' ').toLowerCase();
    return text[0].toUpperCase() + text.substring(1);
  }

  static List<String> get displayNames => values.map((e) => e.displayName).toList();

  static Personality fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => Personality.neutral,
    );
  }
}

enum Idioma {
  espanhol, gallego, andaluz, ingles, frances, aleman, italiano;

  String get displayName {
    String text = name.replaceAll('nh', 'ñ').toLowerCase();
    return text[0].toUpperCase() + text.substring(1);
  }

  static List<String> get displayNames => values.map((e) => e.displayName).toList();

  static Idioma fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => Idioma.espanhol,
    );
  }
}

enum TipoReceta {
  vegana, vegetariana, carnivora, pescetariana, sin_gluten, sin_lactosa, omnivora, sin_azucar, sin_huevo, sin_frutosSecos, sin_cereales, sin_legumbres;

  String get displayName {
    String text = name.replaceAll('_', ' ').toLowerCase();
    return text[0].toUpperCase() + text.substring(1);
  }

  static List<String> get displayNames => values.map((e) => e.displayName).toList();

  static TipoReceta fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => TipoReceta.omnivora,
    );
  }
}

class _SettingsState extends State<Settings> {
  void _useTTS(bool value) {
    setState(() {
      AppSingleton().setUseTTS = value;
    });
  }

  String compareEnumValues(String value, List<String> options) {
    for (String option in options) {
      if (option.toLowerCase() == value.toLowerCase()) return option;
    }
    return options.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let the wrapper handle background if needed
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(theme, 'Preferencias de recetas'),
            const SizedBox(height: 16),
            ScrollbarSetting(
              initialValue: AppSingleton().numRecetas,
              maxValue: 5,
              divisions: 4,
              text: 'Número de recetas',
              onChange: (int value) => setState(() => AppSingleton().setNumRecetas = value),
            ),
            const SizedBox(height: 16),
            MultiListSetting(
              initialValues: compareEnumValues(AppSingleton().tipoReceta, TipoReceta.displayNames).split(","),
              text: 'Tipo de cocina',
              options: TipoReceta.displayNames,
              onChange: (List<String> values) {
                final tipo = TipoReceta.fromDisplayName(values.first);
                setState(() => AppSingleton().setTipoReceta = tipo.name);
                Toaster.showToast('Tipo de cocina: ${tipo.displayName}');
              },
            ),
            const SizedBox(height: 16),
            MultiListSetting(
              initialValues: compareEnumValues(AppSingleton().idioma, Idioma.displayNames).split(","),
              text: 'Idioma de las recetas',
              options: Idioma.displayNames,
              onChange: (List<String> values) {
                final idio = Idioma.fromDisplayName(values.first);
                setState(() => AppSingleton().setIdioma = idio.name);
                Toaster.showToast('Idioma: ${idio.displayName}');
              },
            ),

            const SizedBox(height: 32),
            _sectionHeader(theme, 'Voz y Tono'),
            const SizedBox(height: 16),
            SwitchSetting(
              initialValue: AppSingleton().useTTS,
              text: 'Lectura por voz (TTS)',
              onChange: _useTTS,
            ),
            const SizedBox(height: 16),
            MultiListSetting(
              initialValues: AppSingleton().personality.split(",").map((p) => Personality.values.firstWhere((e) => e.name == p).displayName).toList(),
              text: 'Personalidad de la IA',
              options: Personality.displayNames,
              onChange: (List<String> values) {
                final personalities = values.map((v) => Personality.fromDisplayName(v)).toList();
                setState(() => AppSingleton().setPersonality = personalities.map((p) => p.name).join(","));
                Toaster.showToast('Tono: ${personalities.map((p) => p.displayName).join(", ")}');
              },
            ),

            const SizedBox(height: 40),
            _sectionHeader(theme, 'Sistema'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LogsScreen()));
              },
              icon: const Icon(Icons.terminal_rounded),
              label: const Text('REGISTROS DEL SISTEMA (LOGS)', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 64),
                backgroundColor: theme.colorScheme.surfaceVariant,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}
