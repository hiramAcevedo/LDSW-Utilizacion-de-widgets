import 'package:flutter/material.dart';

import 'agregar_pelicula.dart';
import 'constantes.dart';
import 'pelicula.dart';
import 'repositorio_peliculas.dart';

/// La pantalla del catálogo. Las películas llegan de Cloud Firestore con un
/// StreamBuilder, así que una película nueva aparece sola; el botón Agregar
/// abre el formulario que la guarda.
class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key, required this.repositorio});

  final RepositorioPeliculas repositorio;

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  // Se escucha una sola vez: si el Stream se creara en build, cada
  // reconstrucción abriría una consulta nueva.
  late final Stream<List<Pelicula>> _peliculas = widget.repositorio.escuchar();

  Future<void> _agregar() async {
    final agregada = await Navigator.of(context).push<Pelicula>(
      MaterialPageRoute(
        builder: (_) => AgregarPeliculaPage(repositorio: widget.repositorio),
      ),
    );
    if (agregada == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Se agregó ${agregada.titulo} al catálogo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.inversePrimary,
        title: const Text(nombreApp),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: StreamBuilder<List<Pelicula>>(
        stream: _peliculas,
        builder: (context, respuesta) {
          if (respuesta.hasError) {
            return MensajeDeError(error: respuesta.error!);
          }
          if (!respuesta.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final peliculas = respuesta.requireData;
          if (peliculas.isEmpty) return const CatalogoVacio();
          return ListaDePeliculas(peliculas: peliculas);
        },
      ),
    );
  }
}

/// La lista del catálogo: una Column con un encabezado y una tarjeta por
/// película, una debajo de otra.
class ListaDePeliculas extends StatelessWidget {
  const ListaDePeliculas({super.key, required this.peliculas});

  final List<Pelicula> peliculas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SingleChildScrollView(
      // Abajo queda espacio para el botón Agregar y para la barra de
      // navegación del sistema, que en Android 16 se dibuja encima de la app.
      padding: EdgeInsets.only(
        top: 16,
        bottom: 96 + MediaQuery.paddingOf(context).bottom,
      ),
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
                  peliculas.length == 1
                      ? '1 título'
                      : '${peliculas.length} títulos',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final pelicula in peliculas)
            TarjetaPelicula(
              key: ValueKey(pelicula.id ?? pelicula.titulo),
              pelicula: pelicula,
            ),
        ],
      ),
    );
  }
}

/// Lo que se ve cuando la colección todavía no tiene películas.
class CatalogoVacio extends StatelessWidget {
  const CatalogoVacio({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: tema.colorScheme.primary,
            ),
            Text(
              'Todavía no hay películas',
              style: tema.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              'Agrega la primera con el botón Agregar.',
              style: tema.textTheme.bodyLarge?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// El aviso cuando la base responde con un error, por ejemplo si las reglas
/// de Firestore no dejan leer la colección.
class MensajeDeError extends StatelessWidget {
  const MensajeDeError({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(Icons.cloud_off, size: 64, color: tema.colorScheme.error),
            Text(
              'No se pudo leer el catálogo',
              style: tema.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              '$error',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Una tarjeta del catálogo: un Container con una Row. A la izquierda el
/// póster, un Stack con el año encima; a la derecha los datos, en una Column.
class TarjetaPelicula extends StatelessWidget {
  const TarjetaPelicula({
    super.key,
    required this.pelicula,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Pelicula pelicula;

  /// El margen de la tarjeta: en la lista, 16 a cada lado; la vista previa
  /// del formulario la usa sin margen.
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      margin: margin,
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
