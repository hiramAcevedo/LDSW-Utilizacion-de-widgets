import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'constantes.dart';
import 'cuenta.dart';
import 'servicios.dart';

/// La pantalla de inicio: la imagen de fondo de la actividad 3.5 y, encima,
/// el icono, el nombre de la aplicación, la bienvenida y las dos opciones:
/// registrarse como usuario nuevo o ingresar con una cuenta que ya existe.
///
/// El widget de layout es un Stack (con un Center y una Column adentro),
/// como en "Lay out a widget" (docs.flutter.dev/ui/layout).
class InicioPage extends StatelessWidget {
  const InicioPage({super.key, required this.servicios});

  final Servicios servicios;

  /// Ruta de la imagen de fondo, declarada en la sección assets de pubspec.yaml.
  static const String imagenFondo = 'assets/images/fondo_inicio.jpg';

  static const String bienvenida = 'Te damos la bienvenida';
  static const String invitacion =
      'Crea tu cuenta o ingresa para ver el catálogo, abrir la ficha de cada '
      'película y administrar la lista.';

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // La imagen es oscura: los iconos de las barras del sistema van en
      // claro, y la de navegación, sin el velo blanco que Android le pone.
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
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
            // 3. El contenido, centrado: el icono, el nombre, la bienvenida y
            //    los dos botones, uno debajo de otro.
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          textAlign: TextAlign.center,
                          style: tema.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          invitacion,
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _abrir(
                            context,
                            RegistroPage(servicios: servicios),
                          ),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Crear cuenta'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _abrir(
                            context,
                            IngresoPage(servicios: servicios),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text('Ya tengo cuenta'),
                        ),
                      ],
                    ),
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
