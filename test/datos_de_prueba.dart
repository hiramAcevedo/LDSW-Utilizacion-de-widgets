// Los datos y los servicios simulados que comparten las pruebas: cuatro
// películas de ejemplo, una base de Firestore en memoria
// (fake_cloud_firestore), una sesión de Firebase simulada
// (firebase_auth_mocks) y TMDB con un cliente HTTP de prueba.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ldsw_utilizacion_de_widgets/app.dart';
import 'package:ldsw_utilizacion_de_widgets/pelicula.dart';
import 'package:ldsw_utilizacion_de_widgets/repositorio_catalogo.dart';
import 'package:ldsw_utilizacion_de_widgets/servicios.dart';
import 'package:ldsw_utilizacion_de_widgets/sesion.dart';
import 'package:ldsw_utilizacion_de_widgets/tmdb.dart';

/// El usuario de las pruebas.
final usuarioDePrueba = MockUser(
  uid: 'uid-de-prueba',
  email: 'ana@ejemplo.com',
  displayName: 'Ana',
);

/// Las cuatro películas de ejemplo, en el orden en que se dieron de alta.
const List<Pelicula> peliculasDeEjemplo = [
  Pelicula(
    titulo: 'Roma',
    anio: 2018,
    director: 'Alfonso Cuarón',
    genero: 'Drama',
    sinopsis: 'Cleo trabaja para una familia de la colonia Roma en 1970.',
    imagen: 'https://image.tmdb.org/t/p/w500/roma.jpg',
    tmdbId: 426426,
  ),
  Pelicula(
    titulo: 'Coco',
    anio: 2017,
    director: 'Lee Unkrich',
    genero: 'Animación, Familia',
    sinopsis: 'Miguel cruza a la Tierra de los Muertos en Día de Muertos.',
    imagen: 'https://image.tmdb.org/t/p/w500/coco.jpg',
    tmdbId: 354912,
  ),
  Pelicula(
    titulo: 'El laberinto del fauno',
    anio: 2006,
    director: 'Guillermo del Toro',
    genero: 'Fantasía, Drama',
    sinopsis: 'Ofelia encuentra un laberinto en la posguerra española.',
    imagen: 'https://image.tmdb.org/t/p/w500/fauno.jpg',
    tmdbId: 1417,
  ),
  Pelicula(
    titulo: 'Amores perros',
    anio: 2000,
    director: 'Alejandro González Iñárritu',
    genero: 'Drama, Suspense',
    sinopsis: 'Un choque en la Ciudad de México cruza tres historias.',
    imagen: 'https://image.tmdb.org/t/p/w500/amores.jpg',
    tmdbId: 55,
  ),
];

/// Las mismas, como las ordena el catálogo: por título.
final List<Pelicula> peliculasPorTitulo = [...peliculasDeEjemplo]
  ..sort((a, b) => a.titulo.compareTo(b.titulo));

/// Un cliente HTTP que no se debería usar: falla si alguien pide algo.
final http.Client clienteSinRed = MockClient(
  (peticion) async => throw StateError('Petición inesperada: ${peticion.url}'),
);

/// Los servicios de la app sobre una base en memoria. Con [conSesion], Ana ya
/// ingresó; con [conPeliculas], el catálogo trae las cuatro de ejemplo.
Future<Servicios> serviciosDePrueba({
  bool conSesion = true,
  bool conPeliculas = true,
  http.Client? clienteTmdb,
  String tokenTmdb = 'token.de.prueba',
  MockFirebaseAuth? auth,
  FakeFirebaseFirestore? firestore,
}) async {
  final base = firestore ?? FakeFirebaseFirestore();
  final catalogo = RepositorioCatalogo(base);
  if (conPeliculas) {
    for (final pelicula in peliculasDeEjemplo) {
      await catalogo.darDeAlta(pelicula, uid: 'uid-de-hiram');
    }
  }
  return Servicios(
    sesion: Sesion(
      auth:
          auth ??
          MockFirebaseAuth(signedIn: conSesion, mockUser: usuarioDePrueba),
      firestore: base,
    ),
    catalogo: catalogo,
    tmdb: Tmdb(token: tokenTmdb, cliente: clienteTmdb ?? clienteSinRed),
  );
}

/// Abre la app sobre esos servicios y espera a que se asiente.
Future<void> abrirApp(WidgetTester tester, Servicios servicios) async {
  await tester.pumpWidget(CatalogoApp(servicios: servicios));
  await tester.pumpAndSettle();
}

/// El botón (de cualquier estilo) que lleva ese texto.
Finder botonCon(String texto) => find.ancestor(
  of: find.text(texto),
  matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
);
