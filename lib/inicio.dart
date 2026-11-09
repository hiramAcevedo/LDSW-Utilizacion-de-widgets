import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'constantes.dart';
import 'pokedex.dart';

/// La pantalla de inicio: el frente rojo de una Pokédex, con su lente azul y
/// sus tres luces arriba, el nombre de la app, un texto corto y el botón que
/// abre la lista.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key, this.cliente});

  /// El cliente HTTP que se pasa a la Pokédex. Las pruebas pasan uno simulado.
  final http.Client? cliente;

  /// El texto corto debajo del nombre.
  static const String descripcion =
      'Los 151 Pokémon de la primera generación, con los datos y las '
      'imágenes de PokéAPI.';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // El fondo es rojo oscuro: los iconos de las barras del sistema van en
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
            // 1. El fondo: un degradado del rojo de la Pokédex a uno más oscuro.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rojoPokedex, Color(0xFF8B0019)],
                ),
              ),
            ),
            // 2. Una Poké Ball grande y tenue, cortada por la orilla derecha.
            Positioned(
              right: -120,
              bottom: -80,
              child: Icon(
                Icons.catching_pokemon,
                size: 420,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            // 3. El contenido: la lente y las luces arriba; el nombre, el
            //    texto y el botón al centro.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LenteYLuces(),
                    const Spacer(),
                    Text(
                      nombreApp,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      descripcion,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: rojoPokedex,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          textStyle: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PokedexPage(cliente: cliente),
                            ),
                          );
                        },
                        icon: const Icon(Icons.catching_pokemon),
                        label: const Text('Ver la Pokédex'),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La lente azul con su aro blanco y las tres luces (roja, amarilla y verde)
/// de la parte de arriba de una Pokédex.
class _LenteYLuces extends StatelessWidget {
  const _LenteYLuces();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 6),
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              colors: [Color(0xFF9FE4FF), Color(0xFF1E88E5), Color(0xFF0D47A1)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        for (final color in const [
          Color(0xFFFF5252),
          Color(0xFFFFD740),
          Color(0xFF69F0AE),
        ])
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black38, width: 2),
            ),
          ),
      ],
    );
  }
}
