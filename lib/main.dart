import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'repositorio_catalogo.dart';
import 'servicios.dart';
import 'sesion.dart';
import 'tmdb.dart';

/// Con `--dart-define=EMULADORES=true`, la app usa los emuladores locales de
/// Firebase (Authentication y Firestore) en lugar del proyecto real: sirve
/// para probar sin tocar las cuentas ni el catálogo de verdad.
const bool usarEmuladores = bool.fromEnvironment('EMULADORES');

/// Inicializa Firebase con las opciones de `flutterfire configure` y arranca
/// la app con la sesión, el catálogo y TMDB. El token de TMDB llega al
/// compilar: `flutter run --dart-define-from-file=tmdb.json`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (usarEmuladores) {
    // 10.0.2.2 es la computadora vista desde el emulador de Android.
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
  }
  final firestore = FirebaseFirestore.instance;
  runApp(
    CatalogoApp(
      servicios: Servicios(
        sesion: Sesion(auth: FirebaseAuth.instance, firestore: firestore),
        catalogo: RepositorioCatalogo(firestore),
        tmdb: Tmdb(token: const String.fromEnvironment('TMDB_TOKEN')),
      ),
    ),
  );
}
