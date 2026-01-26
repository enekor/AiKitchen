import 'package:aikitchen/web/search/search_screen.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WebFeaturesScreen extends StatefulWidget {
  const WebFeaturesScreen({super.key});

  @override
  State<WebFeaturesScreen> createState() => _WebFeaturesScreenState();
}

class _WebFeaturesScreenState extends State<WebFeaturesScreen> {
  @override
  void initState() {
    super.initState();
    // Mostramos el aviso justo después de que se renderice la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLidlNotice();
    });
  }

  Future<void> _launchLidlWeb() async {
    final url = Uri.parse('https://recetas.lidl.es/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Toaster.showError('No se pudo abrir la web de Lidl');
    }
  }

  void _showLidlNotice() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.info_outline_rounded, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Aviso de contenido',
              style: GoogleFonts.robotoFlex(
                textStyle: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Las recetas mostradas en esta sección se obtienen directamente de la web oficial de Lidl. La aplicación facilita la lectura, pero el contenido pertenece a su fuente original.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _launchLidlWeb();
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('IR A LA WEB', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60), // Margen para el botón de atrás del wrapper
            Text(
              'Internet',
              style: GoogleFonts.robotoFlex(
                textStyle: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fuentes externas de inspiración culinaria',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 40),
            
            // Botón Buscador General
            _buildFeatureTile(
              context,
              title: 'Lidl Recetas',
              subtitle: 'Buscar cualquier receta en Lidl',
              icon: Icons.search_rounded,
              color: theme.colorScheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              ),
            ),

            // Botón Especializado Air Fryer
            _buildFeatureTile(
              context,
              title: 'Air Fryer',
              subtitle: 'Recetas directas para freidora de aire',
              icon: Icons.abc_rounded, // Icono temporal solicitado
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(
                    initialUrl: 'https://recetas.lidl.es/todasrecetas?page=1&smartTools=e5b19ae4-45a5-400c-b2fe-742cba502e9a',
                    title: 'Air Fryer',
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.robotoFlex(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
