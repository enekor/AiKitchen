import 'dart:io';

import 'package:flutter/services.dart';

/// Certificado raíz ISRG Root X1 (Let's Encrypt), tal como lo publica
/// https://letsencrypt.org/certs/isrgrootx1.pem
/// SHA-256: 96:BC:EC:06:26:49:76:F3:74:60:77:9A:CF:28:C5:A7:
///          CF:E8:A3:C0:AA:E1:1A:8F:FC:EE:05:C0:BD:DF:08:C6
/// Caduca el 4 de junio de 2035.
const String extraTrustedRootsAsset = 'assets/certs/isrg_root_x1.pem';

/// Añade ISRG Root X1 a los certificados raíz del sistema en Android.
///
/// Android 7.0 y anteriores no lo traen, y raw.githubusercontent.com (de donde
/// sale el recetario) presenta una cadena de Let's Encrypt que termina en él,
/// así que la conexión fallaba con un error de handshake.
///
/// La verificación TLS sigue intacta: no se acepta ningún certificado inválido,
/// solo se reconoce una autoridad más. En Android modernos ya lo tienen y no
/// cambia nada.
Future<void> installExtraTrustedRoots() async {
  if (!Platform.isAndroid) return;
  final data = await rootBundle.load(extraTrustedRootsAsset);
  final pem = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  HttpOverrides.global = ExtraRootsHttpOverrides(buildTrustedContext(pem));
}

/// Contexto con los raíces del sistema más los certificados de [pem].
SecurityContext buildTrustedContext(List<int> pem) =>
    SecurityContext(withTrustedRoots: true)..setTrustedCertificatesBytes(pem);

/// Hace que todo `HttpClient` (y por tanto el paquete `http`) use [context]
/// salvo que quien lo crea pase uno propio.
class ExtraRootsHttpOverrides extends HttpOverrides {
  ExtraRootsHttpOverrides(this.context);

  final SecurityContext context;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context ?? this.context);
}
