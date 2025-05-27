import 'dart:async';
import 'dart:io';

import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/screens/preview_shared_recipe.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/terminos_y_condiciones.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'home/home.dart';
import 'screens/settings.dart';
import 'singleton/app_singleton.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSingleton().initializeWithStoredKey();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];

  @override
  void initState() {
    super.initState();

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        setState(() {
          _sharedFiles.clear();
          _sharedFiles.addAll(value);

          print(_sharedFiles.map((f) => f.toMap()));
        });
      },
      onError: (err) {
        print("getIntentDataStream error: $err");
      },
    );

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        print(_sharedFiles.map((f) => f.toMap()));

        // Tell the library that we are done processing the intent.
        ReceiveSharingIntent.instance.reset();
      });
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

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
          home: FutureBuilder<bool?>(
            future: SharedPreferencesService.getBoolValue(
              SharedPreferencesKeys.termsAccepted,
            ),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return _sharedFiles.isNotEmpty
                    ? PreviewSharedFiles(recipeUri: _sharedFiles.first.path)
                    : Home();
              }
              return TerminosYCondicionesModal(
                onAccept: () {
                  setState(() {
                    SharedPreferencesService.setBoolValue(
                      SharedPreferencesKeys.termsAccepted,
                      true,
                    );
                  });

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              _sharedFiles.isNotEmpty
                                  ? PreviewSharedFiles(
                                    recipeUri: _sharedFiles.first.path,
                                  )
                                  : Home(),
                    ),
                  );
                },
                onReject: () {
                  setState(() {
                    SharedPreferencesService.setBoolValue(
                      SharedPreferencesKeys.termsAccepted,
                      false,
                    );
                  });
                  exit(0);
                },
              );
            },
          ),
          routes: {
            '/home': (context) => const Home(),
            '/api_key': (context) => Settings(),
            '/recipe': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as RecipeScreenArguments;
              return RecipeScreen(recipe: args.recipe);
            },
            '/edit_recipe': (context) {
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
