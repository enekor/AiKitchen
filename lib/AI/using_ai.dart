import 'package:aikitchen/AI/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/AI/by_name/find_by_name.dart';
import 'package:aikitchen/AI/favourites/favourites.dart';
import 'package:flutter/material.dart';

class UsingAi extends StatefulWidget {
  const UsingAi({super.key});

  @override
  _UsingAiState createState() => _UsingAiState();
}

class _UsingAiState extends State<UsingAi> with TickerProviderStateMixin {
  int _page = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;

  final List<TabInfo> _tabs = [
    TabInfo(
      icon: Icons.kitchen,
      activeIcon: Icons.kitchen,
      label: 'Ingredientes',
      color: Color(0xFF66BB6A), // Verde fresco
      description: 'Buscar recetas por ingredientes',
    ),
    TabInfo(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Recetas',
      color: Color(0xFFFFB74D), // Amarillo dorado
      description: 'Buscar recetas por nombre',
    ),
    // if (!kIsWeb)
    TabInfo(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: 'Favoritos',
      color: Color(0xFFE57373), // Rojo tomate
      description: 'Tus recetas favoritas',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pageController = PageController();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _changePage(int index) {
    if (_page != index) {
      setState(() => _page = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header con navegación moderna
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _tabs[_page].color.withOpacity(0.1),
                  _tabs[_page].color.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                // Título principal
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _tabs[_page].color,
                              _tabs[_page].color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _tabs[_page].color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _tabs[_page].activeIcon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Kitchen',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _tabs[_page].description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Navegación por pestañas moderna
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children:
                        _tabs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tab = entry.value;
                          final isActive = _page == index;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _changePage(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient:
                                      isActive
                                          ? LinearGradient(
                                            colors: [
                                              tab.color,
                                              tab.color.withOpacity(0.8),
                                            ],
                                          )
                                          : null,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow:
                                      isActive
                                          ? [
                                            BoxShadow(
                                              color: tab.color.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isActive ? tab.activeIcon : tab.icon,
                                        color:
                                            isActive
                                                ? Colors.white
                                                : theme.colorScheme.onSurface
                                                    .withOpacity(0.6),
                                        size: 20,
                                      ),
                                      if (isActive) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          tab.label,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _page = index),
              children: [
                const FindByIngredients(),
                const FindByName(),
                const Favourites(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabInfo {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  final String description;

  TabInfo({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    required this.description,
  });
}
