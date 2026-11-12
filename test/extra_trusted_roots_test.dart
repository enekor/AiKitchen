import 'dart:io';

import 'package:aikitchen/services/tls/extra_trusted_roots_io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Android 7 no trae el certificado raíz de Let's Encrypt y no podía descargar
/// el recetario de GitHub. La app lo lleva incluido: esto vigila que el fichero
/// siga en el bundle y que sea un certificado válido.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el certificado raíz viaja en los assets y es un PEM válido', () async {
    final data = await rootBundle.load(extraTrustedRootsAsset);
    final pem = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    expect(String.fromCharCodes(pem), contains('BEGIN CERTIFICATE'));
    // Si el fichero no fuese un certificado, SecurityContext lanzaría.
    expect(
      () =>
          SecurityContext(withTrustedRoots: false)
            ..setTrustedCertificatesBytes(pem),
      returnsNormally,
    );
    expect(() => buildTrustedContext(pem), returnsNormally);
  });

  test('un fichero que no es un certificado se rechaza', () {
    expect(
      () => buildTrustedContext('esto no es un certificado'.codeUnits),
      throwsA(isA<TlsException>()),
    );
  });
}
