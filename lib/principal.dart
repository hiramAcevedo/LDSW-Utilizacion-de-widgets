import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'administracion.dart';
import 'catalogo.dart';
import 'constantes.dart';
import 'servicios.dart';

/// La pantalla de quien ya tiene la sesión abierta. Arriba, la barra con el
/// nombre de la app, el menú de la cuenta y el menú de pestañas: Catálogo y
/// Administración.
class PrincipalPage extends StatelessWidget {
  const PrincipalPage({
    super.key,
    required this.servicios,
    required this.usuario,
  });

  final Servicios servicios;
  final User usuario;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: tema.colorScheme.inversePrimary,
          title: const Text(nombreApp),
          actions: [MenuDeCuenta(servicios: servicios, usuario: usuario)],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_movies_outlined), text: 'Catálogo'),
              Tab(icon: Icon(Icons.edit_note), text: 'Administración'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CatalogoVista(repositorio: servicios.catalogo),
            AdministracionVista(servicios: servicios, usuario: usuario),
          ],
        ),
      ),
    );
  }
}

/// El menú de la cuenta, a la derecha de la barra: quién tiene la sesión,
/// los créditos y el botón para cerrarla.
class MenuDeCuenta extends StatelessWidget {
  const MenuDeCuenta({
    super.key,
    required this.servicios,
    required this.usuario,
  });

  final Servicios servicios;
  final User usuario;

  String get _nombre {
    final nombre = usuario.displayName?.trim() ?? '';
    return nombre.isEmpty ? (usuario.email ?? 'Tu cuenta') : nombre;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Tu cuenta',
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: tema.colorScheme.primary,
        foregroundColor: tema.colorScheme.onPrimary,
        child: Text(_nombre.characters.first.toUpperCase()),
      ),
      onSelected: (opcion) {
        switch (opcion) {
          case 'acerca':
            showAboutDialog(
              context: context,
              applicationName: nombreApp,
              applicationVersion: 'Producto integrador',
              applicationIcon: const Icon(Icons.local_movies, size: 40),
              children: const [
                Text(
                  'Diseño de aplicaciones móviles. Las películas se guardan en '
                  'Cloud Firestore y las cuentas en Firebase Authentication.',
                ),
                SizedBox(height: 12),
                Text(
                  'La búsqueda de la pantalla de alta usa la API de TMDB, '
                  'pero TMDB no respalda ni certifica esta aplicación.',
                ),
              ],
            );
          case 'salir':
            servicios.sesion.salir();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_nombre),
            subtitle: Text(usuario.email ?? ''),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'acerca',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline),
            title: Text('Acerca de'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'salir',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }
}
