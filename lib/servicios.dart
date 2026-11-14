import 'repositorio_catalogo.dart';
import 'sesion.dart';
import 'tmdb.dart';

/// Lo que la app usa de fuera: la sesión (Firebase Authentication), el
/// catálogo (Cloud Firestore) y la búsqueda (la API de TMDB). `main.dart`
/// pasa los reales; las pruebas, unos simulados.
class Servicios {
  const Servicios({
    required this.sesion,
    required this.catalogo,
    required this.tmdb,
  });

  final Sesion sesion;
  final RepositorioCatalogo catalogo;
  final Tmdb tmdb;
}
