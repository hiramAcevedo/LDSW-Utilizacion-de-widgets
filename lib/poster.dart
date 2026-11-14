import 'package:material_ui/material_ui.dart';

import 'pelicula.dart';

/// El póster de una película: la imagen de su URL. Mientras carga, o si la
/// URL no responde, se ve un bloque de color con un icono.
class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.url,
    required this.color,
    this.radio = 8,
    this.tamanoDeIcono = 32,
  });

  /// La URL de la imagen; vacía si todavía no hay.
  final String url;

  /// El color del bloque de respaldo.
  final Color color;
  final double radio;
  final double tamanoDeIcono;

  @override
  Widget build(BuildContext context) {
    final respaldo = ColoredBox(
      color: color,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          color: Colors.white70,
          size: tamanoDeIcono,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: url.isEmpty
          ? respaldo
          : Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, imagen, progreso) =>
                  progreso == null ? imagen : respaldo,
              errorBuilder: (context, error, pila) => respaldo,
            ),
    );
  }
}

/// La tarjeta de la lista de administración, la misma de las actividades 3.4
/// a 3.7: un Container con una Row. A la izquierda el póster, un Stack con el
/// año encima; a la derecha los datos, en una Column; al final, la acción.
class TarjetaPelicula extends StatelessWidget {
  const TarjetaPelicula({
    super.key,
    required this.pelicula,
    this.accion,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Pelicula pelicula;

  /// Lo que va a la derecha, como el botón para dar de baja.
  final Widget? accion;

  /// El margen de la tarjeta: en la lista, 16 a cada lado.
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
          // El póster y, encima, la etiqueta del año en la esquina inferior
          // derecha.
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 72,
                height: 104,
                child: Poster(
                  url: pelicula.imagen,
                  color: pelicula.colorDeRespaldo,
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
                    Flexible(
                      child: Text(
                        pelicula.genero,
                        style: tema.textTheme.labelMedium?.copyWith(
                          color: tema.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}
