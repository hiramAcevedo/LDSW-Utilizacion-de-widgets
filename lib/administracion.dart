import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'alta.dart';
import 'pelicula.dart';
import 'poster.dart';
import 'servicios.dart';
import 'sesion.dart';

/// La pestaña de administración: dar de alta una película (el botón de
/// arriba abre el formulario con la búsqueda en TMDB) y darla de baja (la
/// papelera de su tarjeta la borra de la base de datos).
class AdministracionVista extends StatefulWidget {
  const AdministracionVista({
    super.key,
    required this.servicios,
    required this.usuario,
  });

  final Servicios servicios;
  final User usuario;

  @override
  State<AdministracionVista> createState() => _AdministracionVistaState();
}

class _AdministracionVistaState extends State<AdministracionVista> {
  late final Stream<List<Pelicula>> _peliculas = widget.servicios.catalogo
      .escuchar();

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _darDeAlta() async {
    final nueva = await Navigator.of(context).push<Pelicula>(
      MaterialPageRoute(
        builder: (_) =>
            AltaPage(servicios: widget.servicios, uid: widget.usuario.uid),
      ),
    );
    if (nueva != null && mounted) {
      _avisar('Se dio de alta ${nueva.titulo} en el catálogo.');
    }
  }

  Future<void> _darDeBaja(Pelicula pelicula) async {
    final confirmada = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('¿Dar de baja ${pelicula.titulo}?'),
        content: const Text(
          'Se borra de la base de datos y deja de verse en el catálogo de '
          'todos los usuarios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
    if (confirmada != true) return;
    try {
      await widget.servicios.catalogo.darDeBaja(pelicula);
      if (mounted) _avisar('Se dio de baja ${pelicula.titulo}.');
    } on Exception catch (error) {
      if (mounted) _avisar(mensajeDeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tenue = tema.textTheme.bodyMedium?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    return StreamBuilder<List<Pelicula>>(
      stream: _peliculas,
      builder: (context, respuesta) {
        final peliculas = respuesta.data;
        return ListView(
          // Abajo queda espacio para la barra de navegación del sistema.
          padding: EdgeInsets.only(
            top: 16,
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  FilledButton.icon(
                    key: const Key('dar-de-alta'),
                    onPressed: _darDeAlta,
                    icon: const Icon(Icons.add),
                    label: const Text('Dar de alta una película'),
                  ),
                  Text(
                    'Para dar de baja una película, toca la papelera de su '
                    'tarjeta.',
                    style: tenue,
                  ),
                ],
              ),
            ),
            if (respuesta.hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No se pudo leer el catálogo: ${respuesta.error}',
                  style: TextStyle(color: tema.colorScheme.error),
                ),
              )
            else if (peliculas == null)
              const Center(child: CircularProgressIndicator())
            else if (peliculas.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'El catálogo está vacío: da de alta la primera película.',
                  style: tenue,
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final pelicula in peliculas)
                Padding(
                  key: ValueKey(pelicula.id ?? pelicula.titulo),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TarjetaPelicula(
                    pelicula: pelicula,
                    accion: IconButton(
                      tooltip: 'Dar de baja',
                      onPressed: () => _darDeBaja(pelicula),
                      icon: Icon(
                        Icons.delete_outline,
                        color: tema.colorScheme.error,
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
