// Pruebas de widget del formulario Agregar película (actividad 3.7): valida
// cada campo, el año sólo acepta cifras dentro del rango, la vista previa
// sigue lo que se escribe y, desde el catálogo, la película se guarda en
// Firestore y aparece en la lista. La base es la simulada de
// fake_cloud_firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ldsw_utilizacion_de_widgets/agregar_pelicula.dart';
import 'package:ldsw_utilizacion_de_widgets/catalogo.dart';
import 'package:ldsw_utilizacion_de_widgets/repositorio_peliculas.dart';

Future<void> abrirFormulario(
  WidgetTester tester,
  RepositorioPeliculas repositorio,
) async {
  await tester.pumpWidget(
    MaterialApp(home: AgregarPeliculaPage(repositorio: repositorio)),
  );
}

/// El campo de texto que está dentro del TextFormField con esa llave.
Finder campo(String llave) => find.descendant(
  of: find.byKey(ValueKey(llave)),
  matching: find.byType(TextField),
);

Future<void> llenarFormulario(
  WidgetTester tester, {
  required String titulo,
  required String anio,
  required String director,
  required String genero,
  required int color,
}) async {
  await tester.enterText(campo('titulo'), titulo);
  await tester.enterText(campo('anio'), anio);
  await tester.enterText(campo('director'), director);

  await tester.ensureVisible(find.byKey(const ValueKey('genero')));
  await tester.tap(find.byKey(const ValueKey('genero')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(genero).last);
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.byKey(ValueKey('color-$color')));
  await tester.tap(find.byKey(ValueKey('color-$color')));
  await tester.pump();
}

Future<void> tocarGuardar(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('guardar')));
  await tester.tap(find.byKey(const ValueKey('guardar')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sin datos no guarda y dice qué falta en cada campo', (
    WidgetTester tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await abrirFormulario(tester, RepositorioPeliculas(firestore));

    await tocarGuardar(tester);

    expect(find.text('Escribe el título'), findsOneWidget);
    expect(find.text('Escribe el año de estreno'), findsOneWidget);
    expect(find.text('Escribe quién la dirigió'), findsOneWidget);
    expect(find.text('Elige el género'), findsOneWidget);
    expect((await firestore.collection('peliculas').get()).docs, isEmpty);
    expect(find.byType(AgregarPeliculaPage), findsOneWidget);
  });

  testWidgets(
    'El año usa el teclado numérico, sólo acepta cifras y va de 1888 al año que entra',
    (WidgetTester tester) async {
      await abrirFormulario(
        tester,
        RepositorioPeliculas(FakeFirebaseFirestore()),
      );

      final anio = tester.widget<TextField>(campo('anio'));
      expect(anio.keyboardType, TextInputType.number);

      await tester.enterText(campo('anio'), '19a5x7');
      expect(anio.controller!.text, '1957');

      await tester.enterText(campo('anio'), '1700');
      await tocarGuardar(tester);
      final ultimo = DateTime.now().year + 1;
      expect(find.text('Escribe un año de 1888 a $ultimo'), findsOneWidget);

      await tester.enterText(campo('anio'), '1888');
      await tocarGuardar(tester);
      expect(find.text('Escribe un año de 1888 a $ultimo'), findsNothing);
    },
  );

  testWidgets('La vista previa sigue lo que se escribe y el color elegido', (
    WidgetTester tester,
  ) async {
    await abrirFormulario(
      tester,
      RepositorioPeliculas(FakeFirebaseFirestore()),
    );

    await llenarFormulario(
      tester,
      titulo: 'Coco',
      anio: '2017',
      director: 'Lee Unkrich',
      genero: 'Animación',
      color: 1,
    );

    final previa = find.byType(TarjetaPelicula);
    expect(previa, findsOneWidget);
    for (final texto in ['Coco', '2017', 'Lee Unkrich', 'Animación']) {
      expect(
        find.descendant(of: previa, matching: find.text(texto)),
        findsOneWidget,
      );
    }
    final poster = tester.widget<Container>(
      find
          .descendant(
            of: find.descendant(of: previa, matching: find.byType(Stack)),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((poster.decoration as BoxDecoration).color, const Color(0xFFEF6C00));
  });

  testWidgets(
    'Desde el catálogo, el formulario guarda la película en Firestore y el catálogo la muestra',
    (WidgetTester tester) async {
      final firestore = FakeFirebaseFirestore();
      await tester.pumpWidget(
        MaterialApp(
          home: CatalogoPage(repositorio: RepositorioPeliculas(firestore)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Todavía no hay películas'), findsOneWidget);

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Agregar'));
      await tester.pumpAndSettle();
      expect(find.byType(AgregarPeliculaPage), findsOneWidget);

      await llenarFormulario(
        tester,
        titulo: 'Roma',
        anio: '2018',
        director: 'Alfonso Cuarón',
        genero: 'Drama',
        color: 0,
      );
      await tocarGuardar(tester);

      // De vuelta en el catálogo, con el aviso y la tarjeta nueva.
      expect(find.byType(AgregarPeliculaPage), findsNothing);
      expect(find.text('Se agregó Roma al catálogo.'), findsOneWidget);
      expect(find.text('1 título'), findsOneWidget);
      final tarjeta = find.byType(TarjetaPelicula);
      expect(tarjeta, findsOneWidget);
      expect(
        find.descendant(of: tarjeta, matching: find.text('Roma')),
        findsOneWidget,
      );

      // Y en la base, el documento con sus campos.
      final documentos = (await firestore.collection('peliculas').get()).docs;
      expect(documentos, hasLength(1));
      final datos = documentos.single.data();
      expect(datos['titulo'], 'Roma');
      expect(datos['anio'], 2018);
      expect(datos['director'], 'Alfonso Cuarón');
      expect(datos['genero'], 'Drama');
      expect(datos['color'], 0xFF546E7A);
      expect(datos['creada'], isA<Timestamp>());
    },
  );
}
