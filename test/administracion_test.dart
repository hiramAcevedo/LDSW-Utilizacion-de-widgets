// Pruebas de la pantalla de administración: la lista con la tarjeta de la
// actividad 3.4 (Text, Row, Column, Stack y Container), la baja con
// confirmación y el alta, a mano y con la búsqueda de TMDB (un cliente HTTP
// de prueba responde por TMDB).

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ldsw_utilizacion_de_widgets/alta.dart';
import 'package:ldsw_utilizacion_de_widgets/poster.dart';
import 'package:ldsw_utilizacion_de_widgets/servicios.dart';

import 'datos_de_prueba.dart';

Future<void> abrirAdministracion(
  WidgetTester tester,
  Servicios servicios,
) async {
  await abrirApp(tester, servicios);
  await tester.tap(find.text('Administración'));
  await tester.pumpAndSettle();
}

Future<void> llenar(WidgetTester tester, String llave, String texto) async {
  // El campo tiene que estar a la vista para recibir el foco.
  await tester.ensureVisible(find.byKey(Key(llave)));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(Key(llave)), texto);
}

Future<void> tocar(WidgetTester tester, String llave) async {
  await tester.ensureVisible(find.byKey(Key(llave)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(llave)));
  await tester.pumpAndSettle();
}

String textoDe(WidgetTester tester, String llave) =>
    tester.widget<TextFormField>(find.byKey(Key(llave))).controller!.text;

/// TMDB de prueba: la búsqueda devuelve [resultados] y cada ficha sale de
/// [fichas]. Guarda las direcciones pedidas.
http.Client tmdbDePrueba(
  List<Map<String, Object?>> resultados,
  Map<int, Map<String, Object?>> fichas,
  List<Uri> pedidas,
) => MockClient((peticion) async {
  pedidas.add(peticion.url);
  final cuerpo = peticion.url.path == '/3/search/movie'
      ? {'results': resultados}
      : fichas[int.parse(peticion.url.pathSegments.last)];
  return http.Response.bytes(
    utf8.encode(jsonEncode(cuerpo)),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});

final fichaYTuMama = {
  'id': 1391,
  'title': 'Y tu mamá también',
  'release_date': '2001-06-08',
  'overview': 'Dos amigos y una mujer viajan a una playa que no existe.',
  'poster_path': '/ytu.jpg',
  'genres': [
    {'name': 'Drama'},
    {'name': 'Comedia'},
    {'name': 'Romance'},
  ],
  'credits': {
    'crew': [
      {'name': 'Alfonso Cuarón', 'job': 'Director'},
    ],
  },
};

void main() {
  setUpAll(FakeFirebaseFirestore.new);

  testWidgets(
    'La lista usa la tarjeta de la 3.4: Row, Column, Stack y Container',
    (WidgetTester tester) async {
      await abrirAdministracion(tester, await serviciosDePrueba());

      expect(botonCon('Dar de alta una película'), findsOneWidget);
      // La primera, por título, es Amores perros, del 2000.
      final tarjeta = find.byType(TarjetaPelicula).first;
      expect(
        find.descendant(of: tarjeta, matching: find.text('Amores perros')),
        findsOneWidget,
      );
      final fila = find
          .descendant(of: tarjeta, matching: find.byType(Row))
          .first;
      final poster = find
          .descendant(of: fila, matching: find.byType(Stack))
          .first;
      final datos = find
          .descendant(of: fila, matching: find.byType(Column))
          .first;
      expect(
        tester.getTopRight(poster).dx < tester.getTopLeft(datos).dx,
        isTrue,
      );
      expect(tester.getSize(poster), const Size(72, 104));

      // El año encima del póster, en su esquina inferior derecha.
      final anio = find.descendant(of: poster, matching: find.text('2000'));
      expect(
        find.ancestor(of: anio, matching: find.byType(Positioned)),
        findsOneWidget,
      );
      final etiqueta = tester.getRect(
        find.ancestor(of: anio, matching: find.byType(Container)).first,
      );
      expect(
        etiqueta.right,
        moreOrLessEquals(tester.getRect(poster).right - 4, epsilon: 1),
      );

      final contenedor = tester.widget<Container>(
        find.descendant(of: tarjeta, matching: find.byType(Container)).first,
      );
      expect(contenedor.margin, const EdgeInsets.symmetric(horizontal: 16));
      expect(contenedor.padding, const EdgeInsets.all(12));
      final decoracion = contenedor.decoration! as BoxDecoration;
      expect(decoracion.borderRadius, BorderRadius.circular(16));
      expect(decoracion.boxShadow, isNotEmpty);
      expect(
        find.descendant(of: tarjeta, matching: find.byTooltip('Dar de baja')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'La papelera pide confirmar y da de baja la película de la base',
    (WidgetTester tester) async {
      final firestore = FakeFirebaseFirestore();
      await abrirAdministracion(
        tester,
        await serviciosDePrueba(firestore: firestore),
      );
      Future<int> cuantas() async =>
          (await firestore.collection('catalogo').get()).docs.length;

      await tester.tap(find.byTooltip('Dar de baja').first);
      await tester.pumpAndSettle();
      expect(find.text('¿Dar de baja Amores perros?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await cuantas(), 4);

      await tester.tap(find.byTooltip('Dar de baja').first);
      await tester.pumpAndSettle();
      await tester.tap(botonCon('Dar de baja'));
      await tester.pumpAndSettle();

      expect(await cuantas(), 3);
      expect(find.text('Se dio de baja Amores perros.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TarjetaPelicula),
          matching: find.text('Amores perros'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('Dar de alta a mano: el formulario dice qué falta y guarda la '
      'película a nombre de quien la da de alta', (WidgetTester tester) async {
    final firestore = FakeFirebaseFirestore();
    await abrirAdministracion(
      tester,
      await serviciosDePrueba(
        firestore: firestore,
        conPeliculas: false,
        tokenTmdb: '',
      ),
    );
    await tester.tap(find.byKey(const Key('dar-de-alta')));
    await tester.pumpAndSettle();
    expect(find.byType(AltaPage), findsOneWidget);
    expect(find.textContaining('necesita el token de TMDB'), findsOneWidget);

    await tocar(tester, 'guardar');
    for (final aviso in [
      'Escribe el título',
      'Escribe el año de estreno',
      'Escribe quién la dirigió',
      'Escribe el género',
      'Escribe la sinopsis',
      'Escribe la URL de la imagen',
    ]) {
      expect(find.text(aviso), findsOneWidget, reason: aviso);
    }

    await llenar(tester, 'titulo', 'Nosotros los pobres');
    await llenar(tester, 'anio', '1700');
    await llenar(tester, 'director', 'Ismael Rodríguez');
    await llenar(tester, 'genero', 'Drama');
    await llenar(tester, 'sinopsis', 'Pepe el Toro vive en una vecindad.');
    await llenar(tester, 'imagen', 'ftp://ejemplo.com/pobres.jpg');
    await tocar(tester, 'guardar');
    expect(find.textContaining('Escribe un año de 1888 a'), findsOneWidget);
    expect(find.text('La URL debe empezar con https://'), findsOneWidget);

    await llenar(tester, 'anio', '1948');
    await llenar(tester, 'imagen', 'https://ejemplo.com/pobres.jpg');
    await tocar(tester, 'guardar');

    expect(find.byType(AltaPage), findsNothing);
    expect(
      find.text('Se dio de alta Nosotros los pobres en el catálogo.'),
      findsOneWidget,
    );
    final guardada = (await firestore.collection('catalogo').get()).docs.single;
    expect(guardada.data()['titulo'], 'Nosotros los pobres');
    expect(guardada.data()['anio'], 1948);
    expect(guardada.data()['imagen'], 'https://ejemplo.com/pobres.jpg');
    expect(guardada.data()['tmdbId'], isNull);
    expect(guardada.data()['agregadaPor'], 'uid-de-prueba');
    expect(guardada.data()['creada'], isA<Timestamp>());
  });

  testWidgets('Dar de alta con TMDB: la búsqueda llena el formulario y se '
      'guarda con su id', (WidgetTester tester) async {
    final firestore = FakeFirebaseFirestore();
    final pedidas = <Uri>[];
    await abrirAdministracion(
      tester,
      await serviciosDePrueba(
        firestore: firestore,
        conPeliculas: false,
        clienteTmdb: tmdbDePrueba(
          [
            {
              'id': 1391,
              'title': 'Y tu mamá también',
              'release_date': '2001-06-08',
              'poster_path': '/ytu.jpg',
            },
          ],
          {1391: fichaYTuMama},
          pedidas,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('dar-de-alta')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('busqueda')), 'y tu mama');
    await tester.tap(find.byKey(const Key('buscar')));
    await tester.pumpAndSettle();
    expect(find.text('2001'), findsOneWidget);
    await tester.tap(find.text('Y tu mamá también'));
    await tester.pumpAndSettle();

    expect(pedidas.map((uri) => uri.path), [
      '/3/search/movie',
      '/3/movie/1391',
    ]);
    expect(textoDe(tester, 'titulo'), 'Y tu mamá también');
    expect(textoDe(tester, 'anio'), '2001');
    expect(textoDe(tester, 'director'), 'Alfonso Cuarón');
    expect(textoDe(tester, 'genero'), 'Drama, Comedia');
    expect(textoDe(tester, 'sinopsis'), startsWith('Dos amigos'));
    expect(
      textoDe(tester, 'imagen'),
      'https://image.tmdb.org/t/p/w500/ytu.jpg',
    );

    await tocar(tester, 'guardar');

    final guardada = (await firestore.collection('catalogo').get()).docs.single;
    expect(guardada.data()['titulo'], 'Y tu mamá también');
    expect(guardada.data()['tmdbId'], 1391);
    expect(
      find.text('Se dio de alta Y tu mamá también en el catálogo.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Una película que ya está en el catálogo no se da de alta dos veces',
    (WidgetTester tester) async {
      final firestore = FakeFirebaseFirestore();
      final roma = peliculasDeEjemplo.first;
      await abrirAdministracion(
        tester,
        await serviciosDePrueba(
          firestore: firestore,
          clienteTmdb: tmdbDePrueba(
            [
              {
                'id': roma.tmdbId,
                'title': 'Roma',
                'release_date': '2018-08-30',
              },
            ],
            {
              roma.tmdbId!: {
                'id': roma.tmdbId,
                'title': 'Roma',
                'release_date': '2018-08-30',
                'overview': roma.sinopsis,
                'poster_path': '/roma.jpg',
                'genres': [
                  {'name': 'Drama'},
                ],
                'credits': {
                  'crew': [
                    {'name': 'Alfonso Cuarón', 'job': 'Director'},
                  ],
                },
              },
            },
            [],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('dar-de-alta')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('busqueda')), 'Roma');
      await tester.tap(find.byKey(const Key('buscar')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Roma'));
      await tester.pumpAndSettle();

      await tocar(tester, 'guardar');

      expect(find.text('Roma ya está en el catálogo.'), findsOneWidget);
      expect(find.byType(AltaPage), findsOneWidget);
      expect((await firestore.collection('catalogo').get()).docs, hasLength(4));
    },
  );
}
