import 'dart:async';

import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/navigation/app_shell.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/screens/logs_screen.dart';
import 'package:aikitchen/screens/preview_shared_recipe.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:aikitchen/services/cors_proxy.dart';
import 'package:aikitchen/services/first_start_service.dart';
import 'package:aikitchen/services/log_file_service.dart';
import 'package:aikitchen/services/platform/platform_info.dart' as platform;
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/theme/theme_controller.dart';
import 'package:aikitchen/widgets/terminos_y_condiciones.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'screens/settings.dart';
import 'singleton/app_singleton.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ningún fallo de arranque debe dejar una pantalla en blanco. Si la
  // configuración no carga, la app abre igual y el usuario puede arreglarla
  // desde Ajustes.
  await _safely('inicializar la configuración', () async {
    await AppSingleton().initializeWithStoredKey();
  });
  await _safely('migrar datos antiguos', () => FirstStartService().firstStart());
  await _safely('cargar el proxy', () => CorsProxy.load());
  await _safely('cargar el tema', () => themeController.load());

  if (platform.supportsHomeWidgets) {
    await _safely('inicializar los widgets', () async {
      WidgetService.registerCallbacks();
      await WidgetService.initializeWidgets();
    });
  }
  await _safely('inicializar el registro', () => LogFileService().initialize());

  runApp(const MyApp());
}

Future<void> _safely(String what, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    debugPrint('AiKitchen: no se pudo $what: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _intentSub;
  final _sharedFiles = <SharedMediaFile>[];

  @override
  void initState() {
    super.initState();
    if (platform.supportsShareIntents) {
      _listenForSharedFiles();
    }
  }

  /// Recepción de ficheros compartidos desde otras apps. Solo existe en móvil:
  /// el plugin no tiene implementación en navegador.
  void _listenForSharedFiles() {
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        if (!mounted) return;
        setState(() {
          _sharedFiles
            ..clear()
            ..addAll(value);
        });
      },
      onError: (err) => debugPrint('Error recibiendo fichero: $err'),
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (!mounted) return;
      setState(() {
        _sharedFiles
          ..clear()
          ..addAll(value);
      });
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'AI Kitchen',
          debugShowCheckedModeBanner: false,
          theme: CookingTheme.lightTheme(),
          darkTheme: CookingTheme.darkTheme(),
          themeMode: themeController.mode,
          home: _Root(sharedFiles: _sharedFiles),
          routes: {
            AppRoutes.settings: (context) => Settings(),
            AppRoutes.createRecipe: (context) => const CreateRecipe(),
            AppRoutes.logs: (context) => const LogsScreen(),
            // Alias heredado, mantenido para no romper enlaces guardados.
            '/api_key': (context) => Settings(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.recipe) {
              final args = settings.arguments;
              // Al recargar la página en el navegador no hay argumentos:
              // se vuelve al inicio en lugar de reventar.
              if (args is! RecipeScreenArguments) {
                return MaterialPageRoute(builder: (_) => const AppShell());
              }
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => RecipeScreen(recipe: args.recipe),
              );
            }
            return null;
          },
          onUnknownRoute: (_) =>
              MaterialPageRoute(builder: (_) => const AppShell()),
        );
      },
    );
  }
}

/// Decide la primera pantalla: términos, receta compartida o inicio.
class _Root extends StatefulWidget {
  const _Root({required this.sharedFiles});

  final List<SharedMediaFile> sharedFiles;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late Future<bool> _termsAccepted;
  bool _rejected = false;

  @override
  void initState() {
    super.initState();
    _termsAccepted = SharedPreferencesService.getBoolValue(
      SharedPreferencesKeys.termsAccepted,
    );
  }

  Widget get _start => widget.sharedFiles.isNotEmpty
      ? PreviewSharedFiles(recipeUri: widget.sharedFiles.first.path)
      : const AppShell();

  @override
  Widget build(BuildContext context) {
    if (_rejected) return const _TermsRejectedScreen();

    return FutureBuilder<bool>(
      future: _termsAccepted,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) return _start;

        // El aviso es un AlertDialog, pero aquí se muestra como pantalla, así
        // que necesita un Scaffold que pinte el fondo. Sin él no había nada
        // detrás y se veía el fondo negro de la página.
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _buildTerms(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTerms() {
    return TerminosYCondicionesModal(
      onAccept: () async {
        await SharedPreferencesService.setBoolValue(
          SharedPreferencesKeys.termsAccepted,
          true,
        );
        if (!mounted) return;
        setState(() {
          _termsAccepted = Future.value(true);
        });
      },
      onReject: () async {
        await SharedPreferencesService.setBoolValue(
          SharedPreferencesKeys.termsAccepted,
          false,
        );
        if (!mounted) return;
        // En navegador no se puede cerrar la pestaña por código, así que se
        // muestra una pantalla final en lugar de terminar el proceso.
        setState(() => _rejected = true);
        platform.closeApp();
      },
    );
  }
}

class _TermsRejectedScreen extends StatelessWidget {
  const _TermsRejectedScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_meals_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No se puede usar AI Kitchen sin aceptar los términos',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Ya puedes cerrar esta pestaña.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
