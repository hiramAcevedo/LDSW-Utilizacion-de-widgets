import 'package:flutter/material.dart';

import 'constantes.dart';
import 'pelicula.dart';

/// La pantalla del catálogo: una Column con un encabezado y una tarjeta por
/// película, una debajo de otra.
class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.inversePrimary,
        title: const Text(nombreApp),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            // Encabezado: el texto de la izquierda y la cuenta de la derecha
            // comparten la línea base.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Películas disponibles',
                    style: tema.textTheme.titleMedium,
                  ),
                  Text(
                    '${peliculas.length} títulos',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final pelicula in peliculas)
              TarjetaPelicula(pelicula: pelicula),
          ],
        ),
      ),
    );
  }
}

/// Una tarjeta del catálogo: un Container con una Row. A la izquierda el
/// póster, un Stack con el año encima; a la derecha los datos, en una Column.
class TarjetaPelicula extends StatelessWidget {
  const TarjetaPelicula({super.key, required this.pelicula});

  final Pelicula pelicula;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tema.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 12,
        children: [
          // El póster: el bloque de color debajo y la etiqueta del año encima,
          // en la esquina inferior derecha.
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 104,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pelicula.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.movie_outlined,
                  color: Colors.white70,
                  size: 32,
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${pelicula.anio}',
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Los datos: título, director y género, alineados a la izquierda.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(
                  pelicula.titulo,
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  pelicula.director,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  spacing: 4,
                  children: [
                    Icon(
                      Icons.local_movies_outlined,
                      size: 16,
                      color: tema.colorScheme.primary,
                    ),
                    Text(
                      pelicula.genero,
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
