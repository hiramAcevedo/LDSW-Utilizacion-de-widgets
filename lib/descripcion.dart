import 'package:material_ui/material_ui.dart';

import 'pelicula.dart';
import 'poster.dart';

/// La descripción de la película elegida en el catálogo: el póster, el
/// título, el año de estreno, quién la dirigió, el género y la sinopsis.
class DescripcionPage extends StatelessWidget {
  const DescripcionPage({super.key, required this.pelicula});

  final Pelicula pelicula;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.inversePrimary,
        title: Text(pelicula.titulo),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Hero(
                    tag: 'poster-${pelicula.id ?? pelicula.titulo}',
                    child: Poster(
                      url: pelicula.imagen,
                      color: pelicula.colorDeRespaldo,
                      radio: 16,
                      tamanoDeIcono: 64,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pelicula.titulo,
              textAlign: TextAlign.center,
              style: tema.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            DatoDeLaPelicula(
              icono: Icons.calendar_today_outlined,
              etiqueta: 'Año de estreno',
              valor: '${pelicula.anio}',
            ),
            DatoDeLaPelicula(
              icono: Icons.movie_creation_outlined,
              etiqueta: 'Dirección',
              valor: pelicula.director,
            ),
            DatoDeLaPelicula(
              icono: Icons.local_movies_outlined,
              etiqueta: 'Género',
              valor: pelicula.genero,
            ),
            const SizedBox(height: 16),
            Text('Sinopsis', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(pelicula.sinopsis, style: tema.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

/// Una línea de la ficha: el icono, la etiqueta y el valor.
class DatoDeLaPelicula extends StatelessWidget {
  const DatoDeLaPelicula({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(icono, size: 20, color: tema.colorScheme.primary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(valor, style: tema.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
