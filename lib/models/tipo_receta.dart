/// Dietas y restricciones de cocina. Se guardan juntas en una sola preferencia,
/// separadas por comas ("vegetariana,sin_gluten,sin_lactosa"). Las versiones
/// anteriores guardaban un único valor, que se lee igual.
enum TipoReceta {
  // ignore: constant_identifier_names
  vegana, vegetariana, carnivora, pescetariana, sin_gluten, sin_lactosa, omnivora, sin_azucar, sin_huevo, sin_frutosSecos, sin_cereales, sin_legumbres;

  /// Nombre derivado del identificador. Se conserva por compatibilidad con
  /// los valores guardados; para mostrar, mejor [label].
  String get displayName => _humanize(name);

  /// Nombre para mostrar, con tildes.
  String get label => switch (this) {
    TipoReceta.vegana => 'Vegana',
    TipoReceta.vegetariana => 'Vegetariana',
    TipoReceta.carnivora => 'Carnívora',
    TipoReceta.pescetariana => 'Pescetariana',
    TipoReceta.omnivora => 'Omnívora',
    TipoReceta.sin_gluten => 'Sin gluten',
    TipoReceta.sin_lactosa => 'Sin lactosa',
    TipoReceta.sin_azucar => 'Sin azúcar',
    TipoReceta.sin_huevo => 'Sin huevo',
    TipoReceta.sin_frutosSecos => 'Sin frutos secos',
    TipoReceta.sin_cereales => 'Sin cereales',
    TipoReceta.sin_legumbres => 'Sin legumbres',
  };

  /// Tipo de dieta, de los que se elige uno. El resto son restricciones
  /// (alergias, intolerancias o cosas que se quieren evitar) y se combinan.
  bool get isDiet => dietas.contains(this);

  static const List<TipoReceta> dietas = [
    TipoReceta.omnivora,
    TipoReceta.vegetariana,
    TipoReceta.vegana,
    TipoReceta.pescetariana,
    TipoReceta.carnivora,
  ];

  static List<TipoReceta> get restricciones =>
      values.where((t) => !t.isDiet).toList();

  static List<String> get displayNames =>
      values.map((e) => e.displayName).toList();

  static TipoReceta fromDisplayName(String displayName) {
    return values.firstWhere(
      (e) => e.displayName.toLowerCase() == displayName.toLowerCase(),
      orElse: () => TipoReceta.omnivora,
    );
  }

  static TipoReceta fromStoredName(String stored) {
    final normalized = stored.trim().toLowerCase();
    return values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => TipoReceta.omnivora,
    );
  }

  /// Lee la preferencia guardada: una dieta y cero o más restricciones. Los
  /// valores desconocidos se ignoran; sin dieta explícita se asume omnívora.
  static List<TipoReceta> parseList(String stored) {
    final found = <TipoReceta>{};
    for (final part in stored.split(',')) {
      final normalized = part.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      final match = values.where((e) => e.name.toLowerCase() == normalized);
      if (match.isNotEmpty) found.add(match.first);
    }
    final diets = found.where((t) => t.isDiet).toList();
    final diet = diets.isEmpty ? TipoReceta.omnivora : diets.first;
    return [
      diet,
      for (final t in values)
        if (!t.isDiet && found.contains(t)) t,
    ];
  }

  static String toStored(List<TipoReceta> tipos) =>
      tipos.map((t) => t.name).join(',');

  /// Texto para los prompts: "Vegetariana, Sin gluten, Sin lactosa".
  static String promptText(String stored) =>
      parseList(stored).map((t) => t.label).join(', ');

  /// Si la preferencia guardada es distinta de la de por defecto (omnívora sin
  /// restricciones), que es cuando merece la pena recordársela al usuario.
  static bool isCustomized(String stored) {
    final tipos = parseList(stored);
    return tipos.length > 1 || tipos.first != TipoReceta.omnivora;
  }
}

String _humanize(String rawName) {
  final spaced = rawName
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .toLowerCase()
      .trim();
  if (spaced.isEmpty) return spaced;
  return spaced[0].toUpperCase() + spaced.substring(1);
}
