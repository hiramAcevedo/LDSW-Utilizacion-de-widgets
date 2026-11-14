// Pruebas de la pantalla principal con la sesión abierta: el menú de
// pestañas de arriba, el catálogo con el título y el póster de cada película,
// la descripción de la película elegida, los avisos y el menú de la cuenta.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ldsw_utilizacion_de_widgets/catalogo.dart';
import 'package:ldsw_utilizacion_de_widgets/descripcion.dart';
import 'package:ldsw_utilizacion_de_widgets/inicio.dart';
import 'package:ldsw_utilizacion_de_widgets/pelicula.dart';
import 'package:ldsw_utilizacion_de_widgets/poster.dart';
import 'package:ldsw_utilizacion_de_widgets/repositorio_catalogo.dart';
import 'package:ldsw_utilizacion_de_widgets/servicios.dart';
import 'package:ldsw_utilizacion_de_widgets/sesion.dart';
import 'package:ldsw_utilizacion_de_widgets/tmdb.dart';

import 'datos_de_prueba.dart';

/// Una base que, al pedirle el catálogo, responde con un error de permisos.
class RepositorioSinPermiso extends RepositorioCatalogo {
  RepositorioSinPermiso() : super(FakeFirebaseFirestore());

  @override
  Stream<List<Pelicula>> escuchar() => Stream.error(
    FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing or insufficient permissions.',
    ),
  );
}

void main() {
  setUpAll(FakeFirebaseFirestore.new);

  testWidgets(
    'Arriba está el menú para elegir el catálogo o la administración',
    (WidgetTester tester) async {
      await abrirApp(tester, await serviciosDePrueba());

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Catálogo de películas'),
        ),
        findsOneWidget,
      );
      final menu = find.byType(TabBar);
      expect(menu, findsOneWidget);
      expect(
        find.descendant(of: menu, matching: find.text('Catálogo')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: menu, matching: find.text('Administración')),
        findsOneWidget,
      );
      // El menú está arriba, debajo del título.
      expect(tester.getTopLeft(menu).dy < 200, isTrue);
    },
  );

  testWidgets('El catálogo muestra el título y el póster de cada película, por '
      'título', (WidgetTester tester) async {
    await abrirApp(tester, await serviciosDePrueba());

    expect(find.text('4 títulos'), findsOneWidget);
    final tarjetas = find.byType(TarjetaDePoster);
    expect(tarjetas, findsNWidgets(4));
    for (var i = 0; i < peliculasPorTitulo.length; i++) {
      final pelicula = peliculasPorTitulo[i];
      expect(
        find.descendant(
          of: tarjetas.at(i),
          matching: find.text(pelicula.titulo),
        ),
        findsOneWidget,
      );
      final poster = tester.widget<Poster>(
        find.descendant(of: tarjetas.at(i), matching: find.byType(Poster)),
      );
      expect(poster.url, pelicula.imagen);
    }
  });

  testWidgets('Tocar una película abre su descripción con todos sus datos', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester, await serviciosDePrueba());

    await tester.tap(find.text('El laberinto del fauno'));
    await tester.pumpAndSettle();

    final fauno = peliculasDeEjemplo[2];
    final descripcion = find.byType(DescripcionPage);
    expect(descripcion, findsOneWidget);
    Finder dentro(String texto) =>
        find.descendant(of: descripcion, matching: find.text(texto));
    // El título va en la barra y como encabezado.
    expect(dentro(fauno.titulo), findsNWidgets(2));
    expect(dentro('Año de estreno'), findsOneWidget);
    expect(dentro('2006'), findsOneWidget);
    expect(dentro('Dirección'), findsOneWidget);
    expect(dentro('Guillermo del Toro'), findsOneWidget);
    expect(dentro('Género'), findsOneWidget);
    expect(dentro('Fantasía, Drama'), findsOneWidget);
    expect(dentro('Sinopsis'), findsOneWidget);
    expect(dentro(fauno.sinopsis), findsOneWidget);
    final poster = tester.widget<Poster>(
      find.descendant(of: descripcion, matching: find.byType(Poster)),
    );
    expect(poster.url, fauno.imagen);
  });

  testWidgets('Sin películas en la base, el catálogo lo dice', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester, await serviciosDePrueba(conPeliculas: false));

    expect(find.text('Todavía no hay películas'), findsOneWidget);
    expect(find.byType(TarjetaDePoster), findsNothing);
  });

  testWidgets('Si la base responde con un error, lo dice en vez del catálogo', (
    WidgetTester tester,
  ) async {
    final servicios = Servicios(
      sesion: Sesion(
        auth: MockFirebaseAuth(signedIn: true, mockUser: usuarioDePrueba),
        firestore: FakeFirebaseFirestore(),
      ),
      catalogo: RepositorioSinPermiso(),
      tmdb: Tmdb(token: '', cliente: clienteSinRed),
    );
    await abrirApp(tester, servicios);

    expect(find.text('No se pudo leer el catálogo'), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsOneWidget);
  });

  testWidgets('Una película dada de alta en otro teléfono aparece sola', (
    WidgetTester tester,
  ) async {
    final servicios = await serviciosDePrueba();
    await abrirApp(tester, servicios);
    expect(find.byType(TarjetaDePoster), findsNWidgets(4));

    await servicios.catalogo.darDeAlta(
      const Pelicula(
        titulo: 'Como agua para chocolate',
        anio: 1992,
        director: 'Alfonso Arau',
        genero: 'Romance',
        sinopsis: 'Tita cocina lo que no puede decir.',
        imagen: 'https://image.tmdb.org/t/p/w500/agua.jpg',
      ),
      uid: 'otro-usuario',
    );
    await tester.pumpAndSettle();

    expect(find.text('5 títulos'), findsOneWidget);
    // Entre Coco y El laberinto del fauno.
    expect(
      find.descendant(
        of: find.byType(TarjetaDePoster).at(2),
        matching: find.text('Como agua para chocolate'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('El menú de la cuenta dice quién ingresó y Cerrar sesión vuelve '
      'al inicio', (WidgetTester tester) async {
    await abrirApp(tester, await serviciosDePrueba());

    await tester.tap(find.byTooltip('Tu cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('ana@ejemplo.com'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(InicioPage), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });
}
