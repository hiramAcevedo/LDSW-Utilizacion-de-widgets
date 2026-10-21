// Pruebas de widget de la pantalla del catálogo (actividad 3.4): cada uno de
// los cinco widgets (Text, Row, Column, Stack y Container) está donde debe y
// con la configuración que se le dio. Se prueba la pantalla directamente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ldsw_utilizacion_de_widgets/catalogo.dart';
import 'package:ldsw_utilizacion_de_widgets/pelicula.dart';

void main() {
  testWidgets(
    'Muestra el nombre de la app en la barra y las cuatro películas',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CatalogoPage()));

      final titulo = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Catálogo de películas'),
      );
      expect(titulo, findsOneWidget);
      expect(find.byType(TarjetaPelicula), findsNWidgets(peliculas.length));
      for (final pelicula in peliculas) {
        expect(find.text(pelicula.titulo), findsOneWidget);
        expect(find.text(pelicula.director), findsOneWidget);
      }
    },
  );

  testWidgets(
    'Text: el título lleva estilo, dos líneas como máximo y puntos suspensivos',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CatalogoPage()));

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
    await tester.pumpWidget(const MaterialApp(home: CatalogoPage()));

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
    'Column: las tarjetas van una debajo de otra, en el orden del catálogo',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CatalogoPage()));

      final tarjetas = find.byType(TarjetaPelicula);
      final columna = find
          .ancestor(of: tarjetas.first, matching: find.byType(Column))
          .first;
      for (var i = 0; i < peliculas.length; i++) {
        // Cada tarjeta cuelga de la misma Column y muestra la película que le toca.
        expect(
          find.descendant(
            of: tarjetas.at(i),
            matching: find.text(peliculas[i].titulo),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: columna,
            matching: find.text(peliculas[i].titulo),
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
      await tester.pumpWidget(const MaterialApp(home: CatalogoPage()));

      final poster = find.descendant(
        of: find.byType(TarjetaPelicula).first,
        matching: find.byType(Stack),
      );
      final anio = find.descendant(of: poster, matching: find.text('2018'));
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
      await tester.pumpWidget(const MaterialApp(home: CatalogoPage()));

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
}
