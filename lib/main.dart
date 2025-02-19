import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'home/home.dart';
import 'screens/api_key_screen.dart';
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
            colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: FutureBuilder<String?>(
            future: AppSingleton().getStoredApiKey(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasData && snapshot.data != null) {
                return const Home();
              }
              
              return const ApiKeyScreen();
            },
          ),
          routes: {
            '/home': (context) => const Home(),
            '/api_key': (context) => const ApiKeyScreen(),
          },
        );
      },
    );
  }
}

