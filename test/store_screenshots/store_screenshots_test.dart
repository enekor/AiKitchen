// Generates the Play Store screenshots without an emulator, in portrait
// (phone) and landscape (tablet) layouts.
//
// Skipped in a normal `flutter test` run. Generate them with:
//   tool/store_screenshots.sh
// or for a single orientation:
//   flutter test test/store_screenshots \
//     --dart-define=STORE_SCREENSHOTS=true \
//     --dart-define=SCREENSHOT_ORIENTATION=vertical   # or horizontal
//
// Output: screenshots/<vertical|horizontal>/{raw,framed}/*.png and
//         screenshots/feature_graphic.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:aikitchen/navigation/app_shell.dart';
import 'package:aikitchen/navigation/app_shell_controller.dart';
import 'package:aikitchen/screens/cooking_mode_screen.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:aikitchen/services/pantry_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'demo_data.dart';

const _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');
const _orientation = String.fromEnvironment(
  'SCREENSHOT_ORIENTATION',
  defaultValue: 'vertical',
);
const _landscape = _orientation == 'horizontal';

// Portrait: phone, 9:16. Landscape: tablet, 16:9 (1280x720 logical, where the
// app switches to the side navigation rail).
const _shotSize = _landscape ? Size(1920, 1080) : Size(1080, 1920);
const _devicePixelRatio = _landscape ? 1.5 : 2.625;
const _statusBarHeight = 24.0;

class _Shot {
  final String file;
  final String title;
  final String subtitle;
  const _Shot(this.file, this.title, this.subtitle);
}

const _shots = {
  'home': _Shot(
    '01_inicio',
    'Tu cocina, organizada',
    'Menú del día, favoritas y lista de la compra de un vistazo',
  ),
  'recipe': _Shot(
    '02_receta',
    'Recetas claras, paso a paso',
    'Ingredientes, tiempos y raciones a tu medida',
  ),
  'cooking': _Shot(
    '03_modo_cocina',
    'Cocina sin mancharte el móvil',
    'Paso a paso, con lectura en voz alta y temporizadores',
  ),
  'menu': _Shot(
    '04_menu_semanal',
    'Tu menú semanal en un toque',
    'Comidas y cenas de toda la semana, planificadas con IA',
  ),
  'cart': _Shot(
    '05_lista_compra',
    'La compra, ordenada por pasillos',
    'Marca lo que ya tienes y no te olvides de nada',
  ),
  'favourites': _Shot(
    '06_favoritas',
    'Guarda tus recetas favoritas',
    'Con etiquetas para encontrarlas al momento',
  ),
  'search': _Shot(
    '07_buscar',
    'Cocina con lo que tienes',
    'Busca recetas por ingredientes o por nombre',
  ),
};

const _tagline = _Shot('', 'AI Kitchen', 'Tu asistente de cocina con IA');

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final outDir = Directory('screenshots/$_orientation');
  late Directory tmp;

  setUpAll(() async {
    if (!_enabled) return;
    tmp = Directory.systemTemp.createTempSync('aikitchen_shots');
    _mockPlatformChannels(binding, tmp.path);
    SharedPreferences.setMockInitialValues({
      'SharedPreferencesKeys.termsAccepted': true,
      'SharedPreferencesKeys.firstStart': false,
    });
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactoryFfi.setDatabasesPath(tmp.path);
    await _loadFonts();
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
    Directory('${outDir.path}/raw').createSync(recursive: true);
    Directory('${outDir.path}/framed').createSync(recursive: true);
  });

  tearDownAll(() {
    if (_enabled) tmp.deleteSync(recursive: true);
  });

  testWidgets(
    'Play Store screenshots ($_orientation)',
    (tester) async {
      final theme = CookingTheme.lightTheme();

      await tester.runAsync(() async {
        await seedDemoData();
        await AppSingleton().initializeWithStoredKey();
        await PantryService.instance.load();
      });

      _setView(
        tester,
        _shotSize,
        _devicePixelRatio,
        topInset: _statusBarHeight,
      );
      final appKey = GlobalKey();
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        RepaintBoundary(
          key: appKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navKey,
            theme: theme,
            builder: (context, child) => Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                child!,
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _FakeStatusBar(height: _statusBarHeight),
                ),
              ],
            ),
            home: const AppShell(),
          ),
        ),
      );
      await _settle(tester, rounds: 60);

      final raw = <String, Uint8List>{};
      Future<void> shoot(String id) async {
        await _settle(tester);
        final bytes = await _capture(tester, appKey, _devicePixelRatio);
        raw[id] = bytes;
        File(
          '${outDir.path}/raw/${_shots[id]!.file}.png',
        ).writeAsBytesSync(bytes);
      }

      Future<void> openTab(int index, {SearchMode? searchMode}) async {
        AppShellController.instance.goTo(index, searchMode: searchMode);
        await _settle(tester, rounds: 30);
      }

      Future<void> openPage(Widget page) async {
        navKey.currentState!.push(MaterialPageRoute(builder: (_) => page));
        await _settle(tester, rounds: 40);
      }

      Future<void> closePage() async {
        navKey.currentState!.pop();
        await _settle(tester, rounds: 20);
      }

      await shoot('home');
      await openPage(RecipeScreen(recipe: featuredRecipe));
      await shoot('recipe');
      await closePage();
      await openPage(CookingModeScreen(recipe: featuredRecipe));
      await shoot('cooking');
      await closePage();
      await openTab(4);
      await shoot('menu');
      await openTab(2);
      await shoot('cart');
      await openTab(3);
      await shoot('favourites');
      await openTab(1, searchMode: SearchMode.byIngredients);
      await shoot('search');
      await openTab(0);

      // ---- Framed versions (headline + device mockup) @1x ----
      _setView(tester, _shotSize, 1);
      for (final id in _shots.keys) {
        final image = await _decode(tester, raw[id]!);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: _FramedShot(theme: theme, shot: _shots[id]!, screen: image),
          ),
        );
        await _settle(tester, rounds: 4);
        File(
          '${outDir.path}/framed/${_shots[id]!.file}.png',
        ).writeAsBytesSync(await _capture(tester, key, 1));
      }

      // ---- Feature graphic, 1024x500 @1x (once, from the portrait run) ----
      if (!_landscape) {
        _setView(tester, const Size(1024, 500), 1);
        final homeImage = await _decode(tester, raw['home']!);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: _FeatureGraphic(theme: theme, screen: homeImage),
          ),
        );
        await _settle(tester, rounds: 4);
        File(
          'screenshots/feature_graphic.png',
        ).writeAsBytesSync(await _capture(tester, key, 1));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester, rounds: 5);
    },
    skip: !_enabled,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

// ---------------------------------------------------------------------------
// Harness helpers
// ---------------------------------------------------------------------------

void _setView(
  WidgetTester tester,
  Size physical,
  double dpr, {
  double topInset = 0,
}) {
  tester.view.physicalSize = physical;
  tester.view.devicePixelRatio = dpr;
  tester.view.padding = FakeViewPadding(top: topInset * dpr);
  tester.view.viewPadding = FakeViewPadding(top: topInset * dpr);
}

/// Lets real I/O (sqlite runs on another isolate) progress between frames.
Future<void> _settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<Uint8List> _capture(
  WidgetTester tester,
  GlobalKey key,
  double pixelRatio,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Uint8List bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = data!.buffer.asUint8List();
    image.dispose();
  });
  return bytes;
}

Future<ui.Image> _decode(WidgetTester tester, Uint8List bytes) async {
  late ui.Image image;
  await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    image = (await codec.getNextFrame()).image;
  });
  return image;
}

/// The test environment renders text with a placeholder font; load the real
/// ones so the screenshots look like the app.
Future<void> _loadFonts() async {
  Future<void> family(String name, List<Future<ByteData>> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(f);
    }
    await loader.load();
  }

  Future<ByteData> file(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());

  final sdkFonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';

  await family('Inter', [
    rootBundle.load('assets/fonts/Inter-Regular.ttf'),
    rootBundle.load('assets/fonts/Inter-Medium.ttf'),
    rootBundle.load('assets/fonts/Inter-SemiBold.ttf'),
    rootBundle.load('assets/fonts/Inter-Bold.ttf'),
  ]);
  await family('Roboto', [
    file('$sdkFonts/Roboto-Regular.ttf'),
    file('$sdkFonts/Roboto-Medium.ttf'),
    file('$sdkFonts/Roboto-Bold.ttf'),
  ]);
  await family('MaterialIcons', [file('$sdkFonts/MaterialIcons-Regular.otf')]);
}

/// Native plugins are not available in tests: answer their channels with
/// neutral values.
void _mockPlatformChannels(TestWidgetsFlutterBinding binding, String tmp) {
  final messenger = binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tmp,
  );
  for (final name in [
    'flutter_tts',
    'home_widget',
    'dev.fluttercommunity.plus/share',
    'dev.fluttercommunity.plus/device_info',
    'flutter.baseflow.com/permissions/methods',
    'receive_sharing_intent/messages',
    'PonnamKarthik/fluttertoast',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => null,
    );
  }
}

// ---------------------------------------------------------------------------
// Visual pieces
// ---------------------------------------------------------------------------

class _FakeStatusBar extends StatelessWidget {
  final double height;
  const _FakeStatusBar({required this.height});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final style = TextStyle(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      fontFamily: 'Roboto',
    );
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: height,
        child: Padding(
          // Wide margins: the device frame has rounded corners.
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Row(
            children: [
              Text('9:41', style: style),
              const Spacer(),
              Icon(Icons.signal_cellular_alt, size: 15, color: color),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 15, color: color),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _brandBackground(ThemeData theme) {
  final scheme = theme.colorScheme;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(scheme.primary, Colors.black, 0.15)!,
        Color.lerp(scheme.primary, Colors.black, 0.55)!,
      ],
    ),
  );
}

const _headlineStyle = TextStyle(
  fontFamily: 'Inter',
  fontWeight: FontWeight.w700,
  height: 1.1,
  color: Colors.white,
);

/// Device mockup. [width] is the outer width; the screen keeps the capture's
/// aspect ratio.
class _Device extends StatelessWidget {
  final ui.Image screen;
  final double width;
  const _Device({required this.screen, required this.width});

  @override
  Widget build(BuildContext context) {
    final bezel = width * (_landscape ? 0.018 : 0.022);
    final radius = width * (_landscape ? 0.045 : 0.085);
    final inner = width - 2 * bezel;
    return Container(
      width: width,
      height: inner * screen.height / screen.width + 2 * bezel,
      padding: EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0F),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF2A2A33), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - bezel),
        child: RawImage(image: screen, fit: BoxFit.cover),
      ),
    );
  }
}

class _FramedShot extends StatelessWidget {
  final ThemeData theme;
  final _Shot shot;
  final ui.Image screen;
  const _FramedShot({
    required this.theme,
    required this.shot,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = TextStyle(
      fontFamily: 'Inter',
      height: 1.25,
      color: Colors.white.withValues(alpha: 0.85),
    );
    final Widget content;
    if (_landscape) {
      // 1920x1080: headline on the left, tablet on the right.
      content = Padding(
        padding: const EdgeInsets.fromLTRB(110, 0, 90, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shot.title,
                    style: _headlineStyle.copyWith(fontSize: 68),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    shot.subtitle,
                    style: subtitleStyle.copyWith(fontSize: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 70),
            _Device(screen: screen, width: 1120),
          ],
        ),
      );
    } else {
      // 1080x1920: headline on top, phone below.
      content = Padding(
        padding: const EdgeInsets.fromLTRB(70, 110, 70, 0),
        child: Column(
          children: [
            Text(
              shot.title,
              textAlign: TextAlign.center,
              style: _headlineStyle.copyWith(fontSize: 70),
            ),
            const SizedBox(height: 22),
            Text(
              shot.subtitle,
              textAlign: TextAlign.center,
              style: subtitleStyle.copyWith(fontSize: 38),
            ),
            const SizedBox(height: 70),
            Expanded(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                // Keep the phone at its own 9:16 size (Expanded would stretch it).
                minHeight: 0,
                maxHeight: double.infinity,
                child: _Device(screen: screen, width: 840),
              ),
            ),
          ],
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(decoration: _brandBackground(theme), child: content),
    );
  }
}

class _FeatureGraphic extends StatelessWidget {
  final ThemeData theme;
  final ui.Image screen;
  const _FeatureGraphic({required this.theme, required this.screen});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: _brandBackground(theme),
        child: Stack(
          children: [
            Positioned(
              left: 70,
              top: 0,
              bottom: 0,
              width: 560,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.soup_kitchen_rounded,
                    size: 88,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _tagline.title,
                    style: _headlineStyle.copyWith(fontSize: 64),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tagline.subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 30,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 80,
              top: 40,
              child: _Device(screen: screen, width: 300),
            ),
          ],
        ),
      ),
    );
  }
}
