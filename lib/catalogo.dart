import 'package:material_ui/material_ui.dart';

import 'descripcion.dart';
import 'pelicula.dart';
import 'poster.dart';
import 'repositorio_catalogo.dart';

/// La pestaña del catálogo: el póster y el título de cada película, en una
/// cuadrícula. Las películas llegan de Cloud Firestore con un StreamBuilder,
/// así que un alta o una baja se ve sin recargar. Tocar una abre su ficha.
class CatalogoVista extends StatefulWidget {
  const CatalogoVista({super.key, required this.repositorio});

  final RepositorioCatalogo repositorio;

  @override
  State<CatalogoVista> createState() => _CatalogoVistaState();
}

class _CatalogoVistaState extends State<CatalogoVista> {
  // Se escucha una sola vez: si el Stream se creara en build, cada
  // reconstrucción abriría una consulta nueva.
  late final Stream<List<Pelicula>> _peliculas = widget.repositorio.escuchar();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pelicula>>(
      stream: _peliculas,
      builder: (context, respuesta) {
        if (respuesta.hasError) {
          return Aviso(
            icono: Icons.cloud_off,
            titulo: 'No se pudo leer el catálogo',
            texto: '${respuesta.error}',
            esError: true,
          );
        }
        if (!respuesta.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final peliculas = respuesta.requireData;
        if (peliculas.isEmpty) {
          return const Aviso(
            icono: Icons.movie_filter_outlined,
            titulo: 'Todavía no hay películas',
            texto: 'Da de alta la primera en la pestaña Administración.',
          );
        }
        return CuadriculaDePosteres(peliculas: peliculas);
      },
    );
  }
}

/// La cuadrícula: un encabezado con la cuenta de títulos y un póster con su
/// título por película.
class CuadriculaDePosteres extends StatelessWidget {
  const CuadriculaDePosteres({super.key, required this.peliculas});

  final List<Pelicula> peliculas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
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
        ),
        SliverPadding(
          // Abajo queda espacio para la barra de navegación del sistema, que
          // en Android 16 se dibuja encima de la app.
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.52,
            ),
            itemCount: peliculas.length,
            itemBuilder: (context, i) => TarjetaDePoster(
              key: ValueKey(peliculas[i].id ?? peliculas[i].titulo),
              pelicula: peliculas[i],
            ),
          ),
        ),
      ],
    );
  }
}

/// Una película del catálogo: el póster y, debajo, el título. Al tocarla se
/// abre la pantalla de descripción.
class TarjetaDePoster extends StatelessWidget {
  const TarjetaDePoster({super.key, required this.pelicula});

  final Pelicula pelicula;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DescripcionPage(pelicula: pelicula),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Hero(
              tag: 'poster-${pelicula.id ?? pelicula.titulo}',
              child: Poster(
                url: pelicula.imagen,
                color: pelicula.colorDeRespaldo,
                radio: 12,
                tamanoDeIcono: 48,
              ),
            ),
          ),
          Text(
            pelicula.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un aviso a media pantalla: el catálogo vacío o un error de la base.
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    this.esError = false,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(
              icono,
              size: 64,
              color: esError
                  ? tema.colorScheme.error
                  : tema.colorScheme.primary,
            ),
            Text(
              titulo,
              style: tema.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              texto,
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
