// Pruebas de widget de la pantalla del catálogo. Las seis primeras vienen de
// la actividad 3.4 (Text, Row, Column, Stack y Container donde deben y con la
// configuración que se les dio); desde la 3.7 las películas llegan de Cloud
// Firestore, aquí de la base simulada de fake_cloud_firestore. Las demás
// prueban lo que trajo la base: el catálogo vacío, el error y una película
// nueva que aparece sola.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ldsw_utilizacion_de_widgets/catalogo.dart';
import 'package:ldsw_utilizacion_de_widgets/pelicula.dart';
import 'package:ldsw_utilizacion_de_widgets/repositorio_peliculas.dart';

import 'datos_de_prueba.dart';

/// Abre el catálogo sobre esa base y espera la primera respuesta.
Future<void> abrirCatalogo(
  WidgetTester tester,
  RepositorioPeliculas repositorio,
) async {
  await tester.pumpWidget(
    MaterialApp(home: CatalogoPage(repositorio: repositorio)),
  );
  await tester.pumpAndSettle();
}

/// Una base que, al pedirle las películas, responde con un error de permisos.
class RepositorioSinPermiso extends RepositorioPeliculas {
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
  testWidgets(
    'Muestra el nombre de la app en la barra y las cuatro películas de la base',
    (WidgetTester tester) async {
      await abrirCatalogo(tester, await repositorioConEjemplos());

      final titulo = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Catálogo de películas'),
      );
      expect(titulo, findsOneWidget);
      expect(find.text('4 títulos'), findsOneWidget);
      expect(
        find.byType(TarjetaPelicula),
        findsNWidgets(peliculasDeEjemplo.length),
      );
      for (final pelicula in peliculasDeEjemplo) {
        expect(find.text(pelicula.titulo), findsOneWidget);
        expect(find.text(pelicula.director), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Text: el título lleva estilo, dos líneas como máximo y puntos suspensivos',
    (WidgetTester tester) async {
      await abrirCatalogo(tester, await repositorioConEjemplos());

      final titulo = tester.widget<Text>(find.text('El laberinto del fauno'));
      expect(titulo.maxLines, 2);
      expect(titulo.overflow, TextOverflow.ellipsis);
      expect(titulo.style?.fontWeight, FontWeight.w600);

      final director = tester.widget<Text>(find.text('Guillermo del Toro'));
      expect(director.maxLines, 1);
      expect(director.overflow, TextOverflow.ellipsis);
    },
  );

  testWidgets('Row: cada tarjeta acomoda el póster y los datos en horizontal', (
    WidgetTester tester,
  ) async {
    await abrirCatalogo(tester, await repositorioConEjemplos());

    final tarjeta = find.byType(TarjetaPelicula).first;
    final fila = find.descendant(of: tarjeta, matching: find.byType(Row)).first;
    final poster = find.descendant(of: fila, matching: find.byType(Stack));
    final datos = find.descendant(of: fila, matching: find.byType(Column));
    expect(poster, findsOneWidget);
    expect(datos, findsOneWidget);

    // El póster queda a la izquierda de los datos y los dos están centrados
    // en la misma altura.
    expect(tester.getTopRight(poster).dx < tester.getTopLeft(datos).dx, isTrue);
    expect(
      tester.getCenter(datos).dy,
      moreOrLessEquals(tester.getCenter(poster).dy, epsilon: 1),
    );
  });

  testWidgets(
    'Column: las tarjetas van una debajo de otra, ordenadas por título',
    (WidgetTester tester) async {
      await abrirCatalogo(tester, await repositorioConEjemplos());

      final tarjetas = find.byType(TarjetaPelicula);
      final columna = find
          .ancestor(of: tarjetas.first, matching: find.byType(Column))
          .first;
      for (var i = 0; i < peliculasPorTitulo.length; i++) {
        // Cada tarjeta cuelga de la misma Column y muestra la película que le
        // toca por orden alfabético.
        expect(
          find.descendant(
            of: tarjetas.at(i),
            matching: find.text(peliculasPorTitulo[i].titulo),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: columna,
            matching: find.text(peliculasPorTitulo[i].titulo),
          ),
          findsOneWidget,
        );
        if (i > 0) {
          expect(
            tester.getTopLeft(tarjetas.at(i)).dy >
                tester.getBottomLeft(tarjetas.at(i - 1)).dy,
            isTrue,
          );
          expect(
            tester.getTopLeft(tarjetas.at(i)).dx,
            tester.getTopLeft(tarjetas.at(i - 1)).dx,
          );
        }
      }
    },
  );

  testWidgets(
    'Stack: el año va encima del póster, en su esquina inferior derecha',
    (WidgetTester tester) async {
      await abrirCatalogo(tester, await repositorioConEjemplos());

      // La primera tarjeta, por título, es Amores perros, del 2000.
      final poster = find.descendant(
        of: find.byType(TarjetaPelicula).first,
        matching: find.byType(Stack),
      );
      final anio = find.descendant(of: poster, matching: find.text('2000'));
      expect(anio, findsOneWidget);
      expect(
        find.ancestor(of: anio, matching: find.byType(Positioned)),
        findsOneWidget,
      );

      final etiqueta = tester.getRect(
        find.ancestor(of: anio, matching: find.byType(Container)).first,
      );
      final rectPoster = tester.getRect(poster);
      expect(
        etiqueta.right,
        moreOrLessEquals(rectPoster.right - 4, epsilon: 1),
      );
      expect(
        etiqueta.bottom,
        moreOrLessEquals(rectPoster.bottom - 4, epsilon: 1),
      );
    },
  );

  testWidgets(
    'Container: la tarjeta tiene margen, relleno, esquinas redondeadas y sombra; el póster, medida fija',
    (WidgetTester tester) async {
      await abrirCatalogo(tester, await repositorioConEjemplos());

      final tarjeta = find.byType(TarjetaPelicula).first;
      final contenedor = tester.widget<Container>(
        find.descendant(of: tarjeta, matching: find.byType(Container)).first,
      );
      expect(contenedor.margin, const EdgeInsets.symmetric(horizontal: 16));
      expect(contenedor.padding, const EdgeInsets.all(12));
      final decoracion = contenedor.decoration as BoxDecoration;
      expect(decoracion.borderRadius, BorderRadius.circular(16));
      expect(decoracion.boxShadow, isNotEmpty);

      final poster = find.descendant(of: tarjeta, matching: find.byType(Stack));
      expect(tester.getSize(poster), const Size(72, 104));
    },
  );

  testWidgets('Sin películas en la base, invita a agregar la primera', (
    WidgetTester tester,
  ) async {
    await abrirCatalogo(tester, RepositorioPeliculas(FakeFirebaseFirestore()));

    expect(find.text('Todavía no hay películas'), findsOneWidget);
    expect(
      find.text('Agrega la primera con el botón Agregar.'),
      findsOneWidget,
    );
    expect(find.byType(TarjetaPelicula), findsNothing);
    expect(
      find.widgetWithText(FloatingActionButton, 'Agregar'),
      findsOneWidget,
    );
  });

  testWidgets('Si la base responde con un error, lo dice en vez de la lista', (
    WidgetTester tester,
  ) async {
    await abrirCatalogo(tester, RepositorioSinPermiso());

    expect(find.text('No se pudo leer el catálogo'), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsOneWidget);
    expect(find.byType(TarjetaPelicula), findsNothing);
  });

  testWidgets(
    'Una película que llega a la base aparece sola, en su lugar por título',
    (WidgetTester tester) async {
      final repositorio = await repositorioConEjemplos();
      await abrirCatalogo(tester, repositorio);
      expect(find.byType(TarjetaPelicula), findsNWidgets(4));

      // Alguien la agrega desde otro teléfono: el catálogo no se recarga.
      await repositorio.agregar(
        const Pelicula(
          titulo: 'Como agua para chocolate',
          anio: 1992,
          director: 'Alfonso Arau',
          genero: 'Romance',
          color: Color(0xFFC62828),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 títulos'), findsOneWidget);
      final tarjetas = find.byType(TarjetaPelicula);
      expect(tarjetas, findsNWidgets(5));
      // Entre Coco y El laberinto del fauno.
      expect(
        find.descendant(
          of: tarjetas.at(2),
          matching: find.text('Como agua para chocolate'),
        ),
        findsOneWidget,
      );
    },
  );
}
