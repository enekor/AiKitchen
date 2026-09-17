import 'package:aikitchen/screens/logs_screen.dart';
import 'package:aikitchen/services/cors_proxy.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/theme/theme_controller.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/setting_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import '../singleton/app_singleton.dart';

class Settings extends StatefulWidget {
  static const String routeName = '/ajustes';

  final bool isNotApiKeySetted;
  const Settings({super.key, this.isNotApiKeySetted = false});

  @override
  State<Settings> createState() => _SettingsState();
}

/// Convierte el nombre interno de una opción en la etiqueta que ve el usuario.
///
/// Separa por guion bajo y también por mayúscula intermedia, de forma que
/// `sin_frutosSecos` se lee «Sin frutos secos» y no «Sin frutossecos».
String _humanize(String rawName) {
  final spaced = rawName
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .toLowerCase()
      .trim();
  if (spaced.isEmpty) return spaced;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Los nombres de estas constantes son el valor que se guarda en las
/// preferencias del usuario. Renombrarlos haría que quien ya tuviera una
/// opción guardada la perdiera, así que no siguen el estilo camelCase a
/// propósito. La conversión a etiqueta legible se hace en [_humanize].
enum Personality {
  amistoso, profesional, casual, divertido, educativo, hiriente, bromista, sarcastico, entusiasta, neutral;

  String get displayName => _humanize(name);

  static List<String> get displayNames =>
      values.map((e) => e.displayName).toList();

  static Personality fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => Personality.neutral,
    );
  }

  /// Traduce el valor guardado en preferencias. Nunca lanza: un valor
  /// desconocido, heredado de una versión anterior, cae en el predeterminado.
  static Personality fromStoredName(String stored) {
    final normalized = stored.trim().toLowerCase();
    return values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => Personality.neutral,
    );
  }

  /// La personalidad se guarda como varios nombres separados por coma.
  static List<String> displayNamesFromStored(String stored) {
    final labels = stored
        .split(',')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => fromStoredName(e).displayName)
        .toSet()
        .toList();
    return labels.isEmpty ? [Personality.neutral.displayName] : labels;
  }
}

enum Idioma {
  espanhol, gallego, andaluz, ingles, frances, aleman, italiano;

  // 'nh' representa la eñe, que no se puede usar en un nombre de constante.
  String get displayName => _humanize(name.replaceAll('nh', 'ñ'));

  static List<String> get displayNames =>
      values.map((e) => e.displayName).toList();

  static Idioma fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => Idioma.espanhol,
    );
  }

  static Idioma fromStoredName(String stored) {
    final normalized = stored.trim().toLowerCase();
    return values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => Idioma.espanhol,
    );
  }
}

enum TipoReceta {
  // ignore: constant_identifier_names
  vegana, vegetariana, carnivora, pescetariana, sin_gluten, sin_lactosa, omnivora, sin_azucar, sin_huevo, sin_frutosSecos, sin_cereales, sin_legumbres;

  String get displayName => _humanize(name);

  static List<String> get displayNames =>
      values.map((e) => e.displayName).toList();

  static TipoReceta fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => TipoReceta.omnivora,
    );
  }

  static TipoReceta fromStoredName(String stored) {
    final normalized = stored.trim().toLowerCase();
    return values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
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

  String _getModelDisplayName(String modelId) {
    switch (modelId) {

      case 'openai/gpt-oss-120b':
        return 'GPT-OSS 120B (Potente)';
      case 'openai/gpt-oss-20b':
        return 'GPT-OSS 20B (Rápido)';
      default:
        return 'openai/gpt-oss-20b';
    }
  }

  String _getModelId(String displayName) {
    switch (displayName) {
      case 'GPT-OSS 120B (Potente)':
        return 'openai/gpt-oss-120b';
      case 'GPT-OSS 20B (Rápido)':
        return 'openai/gpt-oss-20b';
      default:
        return 'openai/gpt-oss-20b';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: ContentShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(theme, 'Clave de API'),
            const SizedBox(height: Spacing.lg),
            TextFieldSetting(
              initialValue: AppSingleton().apiKey ?? '',
              text: 'Clave de Groq',
              hint: 'gsk_...',
              helper:
                  'Sin clave no funcionan las recetas generadas por IA. '
                  'Se guarda solo en este dispositivo.',
              obscure: true,
              onSave: (value) async {
                await AppSingleton().setApiKey(value);
                Toaster.showSuccess('Clave guardada');
              },
            ),

            const SizedBox(height: Spacing.xxl),
            _sectionHeader(theme, 'Apariencia'),
            const SizedBox(height: Spacing.lg),
            SingleListSetting(
              initialValue: themeController.label,
              text: 'Tema',
              options: const ['Según el sistema', 'Claro', 'Oscuro'],
              onChange: (String value) {
                final mode = switch (value) {
                  'Claro' => ThemeMode.light,
                  'Oscuro' => ThemeMode.dark,
                  _ => ThemeMode.system,
                };
                themeController.setMode(mode);
              },
            ),

            if (CorsProxy.isRequired) ...[
              const SizedBox(height: Spacing.xxl),
              _sectionHeader(theme, 'Acceso a webs de recetas'),
              const SizedBox(height: Spacing.lg),
              TextFieldSetting(
                initialValue: CorsProxy.enabled ? CorsProxy.template : '',
                text: 'Proxy',
                hint: CorsProxy.defaultTemplate,
                helper:
                    'El navegador impide leer otras webs directamente. Las '
                    'peticiones se reenvían por esta dirección, donde {url} se '
                    'sustituye por la web a leer. Déjalo vacío para no usar '
                    'ninguno.',
                onSave: (value) async {
                  await CorsProxy.save(value);
                  Toaster.showSuccess(
                    value.isEmpty ? 'Proxy desactivado' : 'Proxy guardado',
                  );
                },
              ),
            ],

            const SizedBox(height: Spacing.xxl),
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
              initialValues: [
                TipoReceta.fromStoredName(AppSingleton().tipoReceta).displayName,
              ],
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
              initialValues: [
                Idioma.fromStoredName(AppSingleton().idioma).displayName,
              ],
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
              initialValues: Personality.displayNamesFromStored(
                AppSingleton().personality,
              ),
              text: 'Personalidad de la IA',
              options: Personality.displayNames,
              onChange: (List<String> values) {
                final personalities = values.map((v) => Personality.fromDisplayName(v)).toList();
                setState(() => AppSingleton().setPersonality = personalities.map((p) => p.name).join(","));
                Toaster.showToast('Tono: ${personalities.map((p) => p.displayName).join(", ")}');
              },
            ),

            const SizedBox(height: 40),
            _sectionHeader(theme, 'Inteligencia Artificial'),
            const SizedBox(height: 16),
            SingleListSetting(
              initialValue: _getModelDisplayName(AppSingleton().selectedModel),
              text: 'Modelo de Lenguaje',
              options: const [
                'GPT-OSS 120B (Potente)',
                'GPT-OSS 20B (Rápido)',
              ],
              onChange: (String value) {
                final modelId = _getModelId(value);
                setState(() => AppSingleton().setSelectedModel = modelId);
                Toaster.showToast('Modelo cambiado a: $value');
              },
            ),

            const SizedBox(height: 40),
            _sectionHeader(theme, 'Sistema'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/registros'),
                    builder: (context) => const LogsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.terminal_rounded),
              label: const Text('Registros del sistema'),
            ),
            const SizedBox(height: Spacing.xxl),
          ],
        ),
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
