import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'constantes.dart';
import 'inicio.dart';
import 'repositorio_peliculas.dart';

/// La app: el tema, el nombre y la pantalla de inicio. Recibe la base de
/// películas, la real en `main.dart` y una simulada en las pruebas.
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repositorio});

  final RepositorioPeliculas repositorio;

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
      home: InicioPage(repositorio: repositorio),
    );
  }
}
