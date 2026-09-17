import 'package:flutter/material.dart';

/// Aviso de términos y condiciones.
///
/// No cierra ninguna ruta por su cuenta: solo avisa por las retrollamadas y
/// deja que quien lo muestra decida qué hacer. Cuando sí cerraba, y se pintaba
/// como pantalla raíz, cerraba la única ruta que había y dejaba la aplicación
/// en negro.
class TerminosYCondicionesModal extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const TerminosYCondicionesModal({
    super.key,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Términos y Condiciones'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Por favor, lea atentamente los siguientes términos y condiciones:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Al usar esta aplicación, usted acepta y reconoce que:\n\n'
                '1. La aplicación proporciona recetas y sugerencias culinarias destinadas exclusivamente para la cocina casera.\n\n'
                '2. El desarrollador no se hace responsable por el uso indebido de las recetas o por contenido que pueda herir sensibilidades.\n\n'
                '3. Queda estrictamente prohibido utilizar la aplicación para buscar o generar recetas relacionadas con la elaboración de sustancias ilegales, estupefacientes, armas o cualquier otro propósito ilícito.\n\n'
                '4. El usuario es el único responsable del uso que haga de las recetas y la información proporcionada.\n\n'
                '5. La aplicación está diseñada exclusivamente para fines culinarios legítimos y uso doméstico.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: onReject, child: const Text('Rechazar')),
        FilledButton(onPressed: onAccept, child: const Text('Aceptar')),
      ],
    );
  }
}
