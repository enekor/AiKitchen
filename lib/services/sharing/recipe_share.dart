/// Compartición de recetas dependiente de plataforma.
///
/// Debe exponer `shareRecipeFile(String fileName, String contents, String text)`.
library;

export 'recipe_share_web.dart' if (dart.library.io) 'recipe_share_io.dart';
