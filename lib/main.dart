import 'package:flutter/material.dart';

import 'constantes.dart';
import 'inicio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nombreApp,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // La variante fidelity deja el color principal cerca del rojo base.
        colorScheme: ColorScheme.fromSeed(
          seedColor: rojoPokedex,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: rojoPokedex,
          foregroundColor: Colors.white,
        ),
      ),
      home: const InicioPage(),
    );
  }
}
