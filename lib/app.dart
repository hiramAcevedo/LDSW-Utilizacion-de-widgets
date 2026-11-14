import 'package:material_ui/material_ui.dart';

import 'constantes.dart';
import 'puerta.dart';
import 'servicios.dart';

/// La app: el tema, el nombre, el idioma y la puerta de la sesión.
class CatalogoApp extends StatelessWidget {
  const CatalogoApp({super.key, required this.servicios});

  final Servicios servicios;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nombreApp,
      debugShowCheckedModeBanner: false,
      // Los textos de Material (Pegar, Seleccionar todo, Atrás) en español.
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: PuertaDeSesion(servicios: servicios),
    );
  }
}
