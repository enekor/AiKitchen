/// Registros en memoria, para navegador.
///
/// No se persisten entre recargas a propósito: los registros solo sirven para
/// diagnosticar la sesión actual y no merecen ocupar cuota de localStorage.
class LogStore {
  static const int _maxEntries = 500;
  final List<String> _entries = [];

  Future<void> initialize() async {}

  Future<void> append(String entry) async {
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }

  Future<String> read() async => _entries.join();

  Future<void> clear() async => _entries.clear();
}
