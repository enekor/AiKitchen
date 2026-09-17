import 'package:aikitchen/screens/settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las opciones de Ajustes se guardan por su nombre interno y se muestran con
/// una etiqueta legible. Antes se comparaba una cosa con la otra directamente,
/// así que cualquier opción con guion bajo no se reconocía al volver a abrir la
/// pantalla y el selector caía en la primera de la lista.
void main() {
  group('TipoReceta', () {
    test('reconoce un valor guardado con guion bajo', () {
      expect(
        TipoReceta.fromStoredName('sin_gluten'),
        TipoReceta.sin_gluten,
      );
      expect(
        TipoReceta.fromStoredName('sin_gluten').displayName,
        'Sin gluten',
      );
    });

    test('separa también las mayúsculas intermedias', () {
      expect(TipoReceta.sin_frutosSecos.displayName, 'Sin frutos secos');
    });

    test('todo valor guardado vuelve a su misma opción', () {
      for (final tipo in TipoReceta.values) {
        expect(TipoReceta.fromStoredName(tipo.name), tipo);
      }
    });

    test('toda etiqueta vuelve a su misma opción', () {
      for (final tipo in TipoReceta.values) {
        expect(TipoReceta.fromDisplayName(tipo.displayName), tipo);
      }
    });

    test('un valor desconocido cae en el predeterminado', () {
      expect(TipoReceta.fromStoredName('omnívora'), TipoReceta.omnivora);
      expect(TipoReceta.fromStoredName(''), TipoReceta.omnivora);
    });

    test('las etiquetas no se repiten entre sí', () {
      final labels = TipoReceta.displayNames;
      expect(labels.toSet(), hasLength(labels.length));
    });
  });

  group('Idioma', () {
    test('la eñe aparece en la etiqueta pero no en el valor guardado', () {
      expect(Idioma.espanhol.name, 'espanhol');
      expect(Idioma.espanhol.displayName, 'Español');
      expect(Idioma.fromStoredName('espanhol'), Idioma.espanhol);
    });

    test('todo valor guardado vuelve a su misma opción', () {
      for (final idioma in Idioma.values) {
        expect(Idioma.fromStoredName(idioma.name), idioma);
        expect(Idioma.fromDisplayName(idioma.displayName), idioma);
      }
    });
  });

  group('Personality', () {
    test('lee la lista separada por comas', () {
      expect(
        Personality.displayNamesFromStored('neutral,amistoso'),
        ['Neutral', 'Amistoso'],
      );
    });

    test('un valor desconocido no revienta la pantalla', () {
      // Antes se usaba firstWhere sin alternativa, así que un valor heredado
      // de otra versión lanzaba una excepción al abrir Ajustes.
      expect(
        Personality.displayNamesFromStored('valor_que_ya_no_existe'),
        ['Neutral'],
      );
    });

    test('una preferencia vacía devuelve el predeterminado', () {
      expect(Personality.displayNamesFromStored(''), ['Neutral']);
      expect(Personality.displayNamesFromStored(','), ['Neutral']);
    });

    test('no devuelve etiquetas repetidas', () {
      expect(
        Personality.displayNamesFromStored('neutral,neutral'),
        ['Neutral'],
      );
    });
  });
}
