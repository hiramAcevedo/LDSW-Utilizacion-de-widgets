import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'inicio.dart';
import 'principal.dart';
import 'servicios.dart';

/// Decide qué se ve según la sesión: sin sesión, la pantalla de inicio con
/// la bienvenida; con sesión, la pantalla principal con el catálogo. Escucha
/// a Firebase Authentication, así que registrarse, ingresar o cerrar la
/// sesión cambia la pantalla sola.
class PuertaDeSesion extends StatefulWidget {
  const PuertaDeSesion({super.key, required this.servicios});

  final Servicios servicios;

  @override
  State<PuertaDeSesion> createState() => _PuertaDeSesionState();
}

class _PuertaDeSesionState extends State<PuertaDeSesion> {
  late final Stream<User?> _usuario = widget.servicios.sesion.cambios;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _usuario,
      initialData: widget.servicios.sesion.actual,
      builder: (context, respuesta) {
        final usuario = respuesta.data;
        if (usuario == null) return InicioPage(servicios: widget.servicios);
        return PrincipalPage(servicios: widget.servicios, usuario: usuario);
      },
    );
  }
}
