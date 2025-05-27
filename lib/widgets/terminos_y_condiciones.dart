import 'package:flutter/material.dart';

class TerminosYCondicionesModal extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const TerminosYCondicionesModal({
    Key? key,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Términos y Condiciones'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Por favor, lea atentamente los siguientes términos y condiciones:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Al usar esta aplicación, usted acepta y reconoce que:\n\n'
                '1. La aplicación proporciona recetas y sugerencias culinarias destinadas exclusivamente para la cocina casera.\n\n'
                '2. El desarrollador no se hace responsable por el uso indebido de las recetas o por contenido que pueda herir sensibilidades.\n\n'
                '3. Queda estrictamente prohibido utilizar la aplicación para buscar o generar recetas relacionadas con la elaboración de sustancias ilegales, estupefacientes, armas o cualquier otro propósito ilícito.\n\n'
                '4. El usuario es el único responsable del uso que haga de las recetas y la información proporcionada.\n\n'
                '5. La aplicación está diseñada exclusivamente para fines culinarios legítimos y uso doméstico.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onReject();
          },
          child: const Text('Rechazar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAccept();
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

// Ejemplo de uso:
// showDialog(
//   context: context,
//   barrierDismissible: false,
//   builder: (context) => TerminosYCondicionesModal(
//     onAccept: () {
//       // Lógica cuando el usuario acepta
//     },
//     onReject: () {
//       // Lógica cuando el usuario rechaza
//     },
//   ),
// );
