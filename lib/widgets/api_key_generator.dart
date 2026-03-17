import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyGenerator extends StatefulWidget {
  const ApiKeyGenerator({super.key, this.onChange, this.isPopup = false});
  final Function(String)? onChange;
  final bool isPopup;

  @override
  State<ApiKeyGenerator> createState() => _ApiKeyGeneratorState();
}

class _ApiKeyGeneratorState extends State<ApiKeyGenerator>
    with WidgetsBindingObserver {
  bool _isExpanded = false;
  final _controller = TextEditingController();
  String? _detectedKey;
  bool _keyValid = false;

  static const _studioUrl = 'https://aistudio.google.com/app/apikey';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.text = AppSingleton().apiKey ?? '';
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForKey();
    }
  }

  bool _isValidKey(String key) {
    final k = key.trim();
    return k.startsWith('AIza') && k.length >= 35;
  }

  void _onTextChanged() {
    final valid = _isValidKey(_controller.text);
    if (valid != _keyValid) {
      setState(() => _keyValid = valid);
    }
    widget.onChange?.call(_controller.text);
  }

  Future<void> _checkClipboardForKey() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (_isValidKey(text) && text != AppSingleton().apiKey) {
      setState(() => _detectedKey = text);
    }
  }

  Future<void> _applyKey(String key) async {
    final k = key.trim();
    await AppSingleton().setApiKey(k);
    setState(() {
      _controller.text = k;
      _keyValid = true;
      _detectedKey = null;
    });
    Toaster.showSuccess('¡Clave aplicada correctamente!');
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      Toaster.showError('El portapapeles está vacío');
      return;
    }
    setState(() => _controller.text = text);
  }

  Future<void> _openStudio() async {
    if (!await launchUrl(Uri.parse(_studioUrl),
        mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKey = AppSingleton().apiKey != null;

    return AnimatedCard(
      isExpanded: widget.isPopup ? true : _isExpanded,
      text: hasKey ? 'Acceso a IA activado' : 'Activa el acceso a la IA',
      icon: hasKey
          ? const Icon(Icons.check_circle_rounded, color: Colors.green)
          : const Icon(Icons.lock_open_rounded),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      children: [
        // Banner de clave detectada
        if (_detectedKey != null) _DetectedKeyBanner(
          onApply: () => _applyKey(_detectedKey!),
          onDismiss: () => setState(() => _detectedKey = null),
        ),

        if (_detectedKey != null) const SizedBox(height: 16),

        // Pasos
        _StepTile(
          number: '1',
          text: 'Pulsa el botón de abajo para abrir Google AI Studio. '
              'Es completamente gratis, solo necesitas una cuenta de Google.',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 10),
        _StepTile(
          number: '2',
          text: 'Inicia sesión y crea una clave nueva. '
              'Dale al botón azul que dice "Crear clave de API".',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 10),
        _StepTile(
          number: '3',
          text: 'Copia la clave y vuelve aquí. '
              'La detectaremos automáticamente.',
          color: theme.colorScheme.primary,
        ),

        const SizedBox(height: 20),

        // Botón principal
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openStudio,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Ir a obtener mi clave gratuita'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 16),

        // Entrada manual
        Text(
          'O pégala aquí si ya la tienes:',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _controller.text.isEmpty
                        ? theme.colorScheme.outline.withOpacity(0.3)
                        : _keyValid
                            ? Colors.green
                            : Colors.red.shade300,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'AIza...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    suffixIcon: _controller.text.isNotEmpty
                        ? Icon(
                            _keyValid
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            color: _keyValid ? Colors.green : Colors.red,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste_rounded),
              tooltip: 'Pegar desde portapapeles',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: _keyValid ? () => _applyKey(_controller.text) : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Guardar clave'),
          ),
        ),
      ],
    );
  }
}

class _DetectedKeyBanner extends StatelessWidget {
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const _DetectedKeyBanner({required this.onApply, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Clave detectada!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Hemos encontrado una clave en tu portapapeles.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onApply,
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Aplicar'),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: Colors.green,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final String text;
  final Color color;

  const _StepTile({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
