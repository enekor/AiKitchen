import 'package:aikitchen/screens/logs_screen.dart';
import 'package:aikitchen/services/ai_service.dart';
import 'package:aikitchen/services/cors_proxy.dart';
import 'package:aikitchen/services/external_link_service.dart';
import 'package:aikitchen/services/quick_settings_service.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/theme/theme_controller.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/setting_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/app_card.dart';
import 'package:flutter/material.dart';
import '../singleton/app_singleton.dart';

class Settings extends StatefulWidget {
  static const String routeName = '/ajustes';

  final bool isNotApiKeySetted;
  const Settings({super.key, this.isNotApiKeySetted = false});

  @override
  State<Settings> createState() => _SettingsState();
}

String _humanize(String rawName) {
  final spaced = rawName
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .toLowerCase()
      .trim();
  if (spaced.isEmpty) return spaced;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

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

  static Personality fromStoredName(String stored) {
    final normalized = stored.trim().toLowerCase();
    return values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => Personality.neutral,
    );
  }

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
  String _configProviderKey = 'groq';

  @override
  void initState() {
    super.initState();
    _configProviderKey = AppSingleton().activeProvider ?? 'groq';
  }

  void _useTTS(bool value) {
    setState(() {
      AppSingleton().setUseTTS = value;
    });
  }

  List<String> get _availableModelsForActiveProvider {
    final active = AppSingleton().activeProvider ?? 'groq';
    return AiService.providerModels[active] ?? ['llama-3.3-70b-versatile'];
  }

  String _getModelDisplayName(String modelId) {
    return modelId;
  }

  void _showTutorialModal(String providerKey) {
    final title = AiService.providerDisplayNames[providerKey] ?? providerKey;
    final url = AiService.providerTutorialUrls[providerKey] ?? '';
    final steps = AiService.providerTutorialSteps[providerKey] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cómo obtener clave de $title', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Spacing.lg),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
                itemBuilder: (context, index) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Text(
                          steps[index],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await openExternalUrl(url);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Abrir web'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getKeyForProvider(String providerKey, AppSingleton singleton) {
    switch (providerKey) {
      case 'openai': return singleton.openaiApiKey ?? '';
      case 'gemini': return singleton.geminiApiKey ?? '';
      case 'anthropic': return singleton.anthropicApiKey ?? '';
      case 'groq':
      default: return singleton.groqApiKey ?? '';
    }
  }

  Future<void> _saveKeyForProvider(String providerKey, String val, AppSingleton singleton) async {
    switch (providerKey) {
      case 'openai': await singleton.setOpenAiApiKey(val); break;
      case 'gemini': await singleton.setGeminiApiKey(val); break;
      case 'anthropic': await singleton.setAnthropicApiKey(val); break;
      case 'groq':
      default: await singleton.setGroqApiKey(val); break;
    }
    Toaster.showSuccess('Clave de ${AiService.providerDisplayNames[providerKey]} guardada');
    setState(() {});
  }

  String _getHintForProvider(String providerKey) {
    switch (providerKey) {
      case 'openai': return 'sk-...';
      case 'gemini': return 'AIza...';
      case 'anthropic': return 'sk-ant-...';
      case 'groq':
      default: return 'gsk_...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final singleton = AppSingleton();
    final configuredKeys = singleton.configuredApiKeys;
    final activeProvider = singleton.activeProvider ?? 'groq';

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: ContentShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(theme, 'Inteligencia Artificial'),
              const SizedBox(height: Spacing.lg),
              Text(
                'Selecciona el proveedor de IA que deseas configurar e introduce su clave de API. Si tienes varias claves, podrás elegir cuál usar.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: Spacing.md),

              // Selector de proveedor para configurar
              SingleListSetting(
                initialValue: AiService.providerDisplayNames[_configProviderKey] ?? 'Groq',
                text: 'Proveedor a configurar',
                options: AiService.providerDisplayNames.values.toList(),
                onChange: (String value) {
                  final entry = AiService.providerDisplayNames.entries.firstWhere(
                    (e) => e.value.toLowerCase() == value.toLowerCase(),
                    orElse: () => const MapEntry('groq', 'Groq'),
                  );
                  setState(() {
                    _configProviderKey = entry.key;
                  });
                },
              ),
              const SizedBox(height: Spacing.md),

              // Widget dinámico para la clave del proveedor seleccionado
              TextFieldSetting(
                key: ValueKey(_configProviderKey),
                initialValue: _getKeyForProvider(_configProviderKey, singleton),
                text: 'Clave de API de ${AiService.providerDisplayNames[_configProviderKey]}',
                hint: _getHintForProvider(_configProviderKey),
                helper: 'Se guarda de forma segura solo en este dispositivo.',
                obscure: true,
                onSave: (val) => _saveKeyForProvider(_configProviderKey, val, singleton),
              ),
              const SizedBox(height: Spacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showTutorialModal(_configProviderKey),
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: Text('¿Cómo obtener la clave de ${AiService.providerDisplayNames[_configProviderKey]}?'),
                ),
              ),

              // Si hay más de una clave configurada, selector de IA activa
              if (configuredKeys.length > 1) ...[
                const SizedBox(height: Spacing.lg),
                SingleListSetting(
                  initialValue: AiService.providerDisplayNames[activeProvider] ?? 'Groq',
                  text: 'Proveedor de IA Activo',
                  options: configuredKeys.keys.map((k) => AiService.providerDisplayNames[k] ?? k).toList(),
                  onChange: (String value) {
                    final entry = AiService.providerDisplayNames.entries.firstWhere(
                      (e) => e.value.toLowerCase() == value.toLowerCase(),
                      orElse: () => const MapEntry('groq', 'Groq'),
                    );
                    setState(() {
                      singleton.setSelectedAiProvider = entry.key;
                      final models = AiService.providerModels[entry.key] ?? [];
                      if (models.isNotEmpty) {
                        singleton.setSelectedModel = models.first;
                      }
                    });
                    Toaster.showToast('Proveedor activo: $value');
                  },
                ),
              ],

              const SizedBox(height: Spacing.lg),
              SingleListSetting(
                initialValue: _getModelDisplayName(singleton.selectedModel),
                text: 'Modelo de Lenguaje (${AiService.providerDisplayNames[activeProvider]})',
                options: _availableModelsForActiveProvider,
                onChange: (String value) {
                  setState(() => singleton.setSelectedModel = value);
                  Toaster.showToast('Modelo cambiado a: $value');
                },
              ),
              const SizedBox(height: 16),
              DecimalSliderSetting(
                initialValue: singleton.creatividad,
                text: 'Creatividad',
                min: 0.0,
                max: 1.0,
                divisions: 10,
                labelBuilder: (v) => v < 0.3
                    ? 'Fiel (${v.toStringAsFixed(1)})'
                    : (v > 0.7
                          ? 'Imaginativa (${v.toStringAsFixed(1)})'
                          : 'Equilibrada (${v.toStringAsFixed(1)})'),
                onChange: (value) => singleton.setCreatividad = value,
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
              const SizedBox(height: Spacing.md),
              SwitchSetting(
                initialValue: singleton.densidadCompacta,
                text: 'Densidad compacta',
                subtitle: 'Reduce el espaciado para ver más contenido a la vez',
                onChange: (value) => setState(() => singleton.setDensidadCompacta = value),
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
                initialValue: singleton.numRecetas,
                maxValue: 5,
                divisions: 4,
                text: 'Número de recetas',
                onChange: (int value) => setState(() => singleton.setNumRecetas = value),
              ),
              const SizedBox(height: 16),
              MultiListSetting(
                initialValues: [
                  TipoReceta.fromStoredName(singleton.tipoReceta).displayName,
                ],
                text: 'Tipo de cocina',
                options: TipoReceta.displayNames,
                onChange: (List<String> values) {
                  final tipo = TipoReceta.fromDisplayName(values.first);
                  setState(() => singleton.setTipoReceta = tipo.name);
                  Toaster.showToast('Tipo de cocina: ${tipo.displayName}');
                },
              ),
              const SizedBox(height: 16),
              MultiListSetting(
                initialValues: [
                  Idioma.fromStoredName(singleton.idioma).displayName,
                ],
                text: 'Idioma de las recetas',
                options: Idioma.displayNames,
                onChange: (List<String> values) {
                  final idio = Idioma.fromDisplayName(values.first);
                  setState(() => singleton.setIdioma = idio.name);
                  Toaster.showToast('Idioma: ${idio.displayName}');
                },
              ),

              const SizedBox(height: 32),
              _sectionHeader(theme, 'Voz y Tono'),
              const SizedBox(height: 16),
              SwitchSetting(
                initialValue: singleton.useTTS,
                text: 'Lectura por voz (TTS)',
                onChange: _useTTS,
              ),
              const SizedBox(height: 16),
              DecimalSliderSetting(
                initialValue: singleton.velocidadVoz,
                text: 'Velocidad de reproducción',
                min: 0.75,
                max: 1.75,
                divisions: 20,
                labelBuilder: (v) => '${v.toStringAsFixed(2)}x',
                onChange: (value) => singleton.setVelocidadVoz = value,
              ),
              const SizedBox(height: 16),
              MultiListSetting(
                initialValues: Personality.displayNamesFromStored(
                  singleton.personality,
                ),
                text: 'Personalidad de la IA',
                options: Personality.displayNames,
                onChange: (List<String> values) {
                  final personalities = values.map((v) => Personality.fromDisplayName(v)).toList();
                  setState(() => singleton.setPersonality = personalities.map((p) => p.name).join(","));
                  Toaster.showToast('Tono: ${personalities.map((p) => p.displayName).join(", ")}');
                },
              ),

              if (QuickSettingsService.isAvailable) ...[
                const SizedBox(height: 40),
                _sectionHeader(theme, 'Accesos rápidos'),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lista de la compra en ajustes rápidos',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Coloca un botón junto al wifi y el bluetooth para abrir '
                        'la lista y ver cuántos artículos quedan pendientes.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _addQuickSettingsTile,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Añadir'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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

  Future<void> _addQuickSettingsTile() async {
    if (await QuickSettingsService.requestAddTile()) {
      Toaster.showSuccess('Botón añadido a los ajustes rápidos');
    }
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
