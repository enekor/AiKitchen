import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'home/home.dart';
import 'screens/settings.dart';
import 'singleton/app_singleton.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSingleton().initializeWithStoredKey();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme:
                lightDynamic ??
                ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme:
                darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.dark,
                ),
            useMaterial3: true,
          ),
          home: Home(),
          routes: {
            '/home': (context) => const Home(),
            '/api_key': (context) => Settings(),
            '/recipe': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as RecipeScreenArguments;
              return RecipeScreen(recipe: args.recipe);
            },
          },
        );
      },
    );
  }
}
