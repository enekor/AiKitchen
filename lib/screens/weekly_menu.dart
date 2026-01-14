import 'dart:convert';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/screens/weekly_menu_widgets.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/log_file_service.dart';

class WeeklyMenu extends StatefulWidget {
  const WeeklyMenu({super.key});

  @override
  State<WeeklyMenu> createState() => _WeeklyMenuState();
}

class _WeeklyMenuState extends State<WeeklyMenu> {
  bool _isLoading = false;
  Map<String, List<Recipe>> _weeklyMenu = {};
  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedMenu();
  }

  Future<void> _loadSavedMenu() async {
    setState(() => _isLoading = true);
    try {
      final savedMenu = await JsonDocumentsService().loadWeeklyMenu();
      setState(() {
        _weeklyMenu = savedMenu;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Toaster.showError('Error al cargar el menú: ${e.toString()}');
    }
  }

  Future<void> _generateWeeklyMenu() async {
    setState(() => _isLoading = true);
    final logService = LogFileService();

    try {
      String finalPrompt;
      try {
        await logService.appendLog('INFO WeeklyMenu: Descargando prompt externo...');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final url = Uri.parse(
          'https://raw.githubusercontent.com/enekor/AiKitchen/main/prompt?t=$timestamp'
        );

        final responseExternal = await http.get(
          url,
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ).timeout(const Duration(seconds: 10));

        if (responseExternal.statusCode == 200) {
          finalPrompt = Prompt.formatExternalWeeklyMenuPrompt(
            responseExternal.body,
            AppSingleton().tipoReceta,
            AppSingleton().personality,
            AppSingleton().idioma,
          );
          await logService.appendLog('INFO WeeklyMenu: Prompt externo cargado con éxito.');
        } else {
          throw Exception('Status ${responseExternal.statusCode}');
        }
      } catch (e) {
        await logService.appendLog('WARNING WeeklyMenu: No se pudo cargar el prompt externo ($e). Usando prompt local.');
        finalPrompt = Prompt.weeklyMenuPrompt(
          AppSingleton().tipoReceta,
          AppSingleton().personality,
          AppSingleton().idioma,
        );
      }

      final response = await AppSingleton().generateContent(
        finalPrompt,
        context,
      );

      if (response.isNotEmpty && !response.contains('error')) {
        final cleanedResponse = _cleanJsonResponse(response);
        final Map<String, List<Recipe>> newMenu = {};

        final menuData = Recipe.fromJsonList(cleanedResponse);

        // Distribuir las recetas por día (2 por día: Comida y Cena)
        for (var i = 0; i < _diasSemana.length; i++) {
          final dayStartIndex = i * 2;
          final dayEndIndex = dayStartIndex + 2;
          
          if (dayStartIndex < menuData.length) {
            newMenu[_diasSemana[i]] = menuData.sublist(
              dayStartIndex,
              dayEndIndex.clamp(0, menuData.length),
            );
          }
        }

        setState(() {
          _weeklyMenu = newMenu;
          _isLoading = false;
        });

        await JsonDocumentsService().saveWeeklyMenu(_weeklyMenu);
        Toaster.showSuccess('¡Menú semanal generado con éxito!');
      } else {
        _handleError(response);
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response;
    cleaned = cleaned.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*```$', multiLine: true), '');
    cleaned = cleaned.replaceAll('```', '');
    return cleaned.trim();
  }

  void _handleError(String error) {
    setState(() => _isLoading = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error al generar el menú'),
        content: Text('Ha ocurrido un error: ${error.split(":").last}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: LottieAnimationWidget(type: LottieAnimationType.loading),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _weeklyMenu.isEmpty
            ? EmptyWeeklyMenu(onGenerate: _generateWeeklyMenu)
            : WeeklyMenuList(
                diasSemana: _diasSemana,
                weeklyMenu: _weeklyMenu,
                onRegenerate: _generateWeeklyMenu,
              ),
      ),
    );
  }
}
