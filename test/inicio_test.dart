// Pruebas de la pantalla de inicio: sin sesión, la app da la bienvenida y
// ofrece registrarse o ingresar; el fondo es la imagen de la actividad 3.5.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ldsw_utilizacion_de_widgets/cuenta.dart';
import 'package:ldsw_utilizacion_de_widgets/inicio.dart';

import 'datos_de_prueba.dart';

void main() {
  setUpAll(FakeFirebaseFirestore.new);

  testWidgets('Sin sesión, el inicio da la bienvenida y ofrece registrarse o '
      'ingresar', (WidgetTester tester) async {
    await abrirApp(tester, await serviciosDePrueba(conSesion: false));

    expect(find.byType(InicioPage), findsOneWidget);
    expect(find.text('Catálogo de películas'), findsOneWidget);
    expect(find.text(InicioPage.bienvenida), findsOneWidget);
    expect(find.text(InicioPage.invitacion), findsOneWidget);
    expect(botonCon('Crear cuenta'), findsOneWidget);
    expect(botonCon('Ya tengo cuenta'), findsOneWidget);
    // Sin sesión no se ve el catálogo.
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets(
    'El fondo es la imagen de la actividad 3.5, en la base de un Stack',
    (WidgetTester tester) async {
      await abrirApp(tester, await serviciosDePrueba(conSesion: false));

      final fondo = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == InicioPage.imagenFondo,
      );
      expect(fondo, findsOneWidget);
      final stack = find
          .ancestor(of: fondo, matching: find.byType(Stack))
          .first;
      expect(
        find.descendant(of: stack, matching: find.text(InicioPage.bienvenida)),
        findsOneWidget,
      );
    },
  );

  testWidgets('Crear cuenta abre el registro y Ya tengo cuenta, el ingreso', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester, await serviciosDePrueba(conSesion: false));

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.byType(RegistroPage), findsOneWidget);

    // El botón Atrás de la barra, con su texto en español.
    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya tengo cuenta'));
    await tester.pumpAndSettle();
    expect(find.byType(IngresoPage), findsOneWidget);
  });
}
