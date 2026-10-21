import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'catalogo.dart';
import 'constantes.dart';

/// La pantalla de inicio: la imagen de fondo debajo y, encima, el icono, el
/// nombre de la aplicación, el mensaje de bienvenida y el botón que abre el
/// catálogo.
///
/// Sigue los pasos de "Lay out a widget" (docs.flutter.dev/ui/layout): el
/// widget de layout es un Stack (con un Center y una Column adentro), los
/// widgets visibles son la Image, el Icon y los Text, y el Stack es el cuerpo
/// del Scaffold que devuelve build.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  /// Ruta de la imagen de fondo, declarada en la sección assets de pubspec.yaml.
  static const String imagenFondo = 'assets/images/fondo_inicio.jpg';

  /// El mensaje de bienvenida.
  static const String bienvenida = 'Hello World';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // La imagen es oscura: los iconos de la barra de estado van en claro.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. La base del Stack: la imagen de fondo cubre toda la pantalla.
            Image.asset(imagenFondo, fit: BoxFit.cover),
            // 2. Un velo que se oscurece hacia abajo, para que el texto se lea
            //    sobre la imagen.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.black87],
                ),
              ),
            ),
            // 3. El contenido, centrado: el icono, el nombre de la app, la
            //    bienvenida y el botón, uno debajo de otro.
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      const Icon(
                        Icons.local_movies,
                        size: 96,
                        color: Colors.white,
                      ),
                      Text(
                        nombreApp,
                        textAlign: TextAlign.center,
                        style: tema.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bienvenida,
                        style: tema.textTheme.titleLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CatalogoPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Ver el catálogo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
