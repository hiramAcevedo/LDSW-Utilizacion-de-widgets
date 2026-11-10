// Pruebas de widget de la pantalla de inicio (actividad 3.5): el Text con
// Hello World, la Image de fondo y el Icon están donde deben y con la
// configuración que se les dio, y el botón abre el catálogo. Desde la 3.7 la
// app recibe la base de películas; aquí, la simulada de fake_cloud_firestore.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ldsw_utilizacion_de_widgets/app.dart';
import 'package:ldsw_utilizacion_de_widgets/catalogo.dart';
import 'package:ldsw_utilizacion_de_widgets/constantes.dart';
import 'package:ldsw_utilizacion_de_widgets/inicio.dart';
import 'package:ldsw_utilizacion_de_widgets/repositorio_peliculas.dart';

import 'datos_de_prueba.dart';

/// La app sobre una base simulada vacía.
MyApp appSinPeliculas() =>
    MyApp(repositorio: RepositorioPeliculas(FakeFirebaseFirestore()));

void main() {
  testWidgets(
    'La app arranca en el inicio y muestra el nombre, Hello World y el icono',
    (WidgetTester tester) async {
      await tester.pumpWidget(appSinPeliculas());

      expect(find.byType(InicioPage), findsOneWidget);
      expect(find.text(nombreApp), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byIcon(Icons.local_movies), findsOneWidget);
    },
  );

  testWidgets(
    'Image: la imagen de fondo es la base del Stack, es el asset declarado y cubre la pantalla',
    (WidgetTester tester) async {
      await tester.pumpWidget(appSinPeliculas());

      final imagen = find.byType(Image);
      expect(imagen, findsOneWidget);
      final widget = tester.widget<Image>(imagen);
      expect(widget.image, isA<AssetImage>());
      expect((widget.image as AssetImage).assetName, InicioPage.imagenFondo);
      expect(widget.fit, BoxFit.cover);

      // Es el primer hijo del Stack (la base, debajo de todo lo demás) y el
      // Stack la estira a la pantalla completa.
      final pila = tester.widget<Stack>(
        find
            .descendant(
              of: find.byType(InicioPage),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(pila.fit, StackFit.expand);
      expect(pila.children.first, isA<Image>());
      expect(tester.getSize(imagen), tester.getSize(find.byType(InicioPage)));
    },
  );

  testWidgets(
    'Icon: el icono va sobre la imagen, en blanco y arriba del nombre de la app',
    (WidgetTester tester) async {
      await tester.pumpWidget(appSinPeliculas());

      final icono = find.byIcon(Icons.local_movies);
      final widget = tester.widget<Icon>(icono);
      expect(widget.size, 96);
      expect(widget.color, Colors.white);

      final rectImagen = tester.getRect(find.byType(Image));
      expect(rectImagen.contains(tester.getCenter(icono)), isTrue);
      expect(
        tester.getBottomLeft(icono).dy <=
            tester.getTopLeft(find.text(nombreApp)).dy,
        isTrue,
      );
    },
  );

  testWidgets(
    'Column: icono, nombre, bienvenida y botón bajan centrados, en ese orden',
    (WidgetTester tester) async {
      await tester.pumpWidget(appSinPeliculas());

      final icono = find.byIcon(Icons.local_movies);
      final nombre = find.text(nombreApp);
      final bienvenida = find.text('Hello World');
      final boton = find.bySubtype<FilledButton>();
      expect(boton, findsOneWidget);

      // Los cuatro cuelgan de la misma Column.
      final columna = find
          .ancestor(of: icono, matching: find.byType(Column))
          .first;
      for (final elemento in [nombre, bienvenida, boton]) {
        expect(
          find.descendant(of: columna, matching: elemento),
          findsOneWidget,
        );
      }

      // En orden, de arriba abajo.
      expect(
        tester.getBottomLeft(icono).dy <= tester.getTopLeft(nombre).dy,
        isTrue,
      );
      expect(
        tester.getBottomLeft(nombre).dy <= tester.getTopLeft(bienvenida).dy,
        isTrue,
      );
      expect(
        tester.getBottomLeft(bienvenida).dy <= tester.getTopLeft(boton).dy,
        isTrue,
      );

      // Y centrados en el ancho de la pantalla.
      final centro = tester.getCenter(find.byType(InicioPage)).dx;
      for (final elemento in [icono, nombre, bienvenida, boton]) {
        expect(
          tester.getCenter(elemento).dx,
          moreOrLessEquals(centro, epsilon: 1),
        );
      }
    },
  );

  testWidgets('El botón Ver el catálogo abre la pantalla del catálogo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(repositorio: await repositorioConEjemplos()));

    await tester.tap(find.text('Ver el catálogo'));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogoPage), findsOneWidget);
    expect(find.text('Roma'), findsOneWidget);
  });
}
