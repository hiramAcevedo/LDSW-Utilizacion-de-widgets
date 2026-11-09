// Pruebas de widget de la pantalla de inicio de la Pokédex (actividad 3.6):
// la app arranca ahí con el nombre, el texto y el botón, y el botón abre la
// lista. El cliente HTTP es simulado.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ldsw_utilizacion_de_widgets/constantes.dart';
import 'package:ldsw_utilizacion_de_widgets/inicio.dart';
import 'package:ldsw_utilizacion_de_widgets/main.dart';
import 'package:ldsw_utilizacion_de_widgets/pokedex.dart';

void main() {
  testWidgets(
    'La app arranca en el inicio con el nombre, el texto y el botón',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(InicioPage), findsOneWidget);
      expect(find.text(nombreApp), findsOneWidget);
      expect(find.text(InicioPage.descripcion), findsOneWidget);
      expect(find.text('Ver la Pokédex'), findsOneWidget);
      // Lo de la pantalla de inicio de la actividad 3.5 ya no está.
      expect(find.text('Hello World'), findsNothing);
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets('Ver la Pokédex abre la lista', (WidgetTester tester) async {
    final cliente = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'results': [
            {
              'name': 'bulbasaur',
              'url': 'https://pokeapi.co/api/v2/pokemon/1/',
            },
          ],
        }),
        200,
      ),
    );

    await tester.pumpWidget(MaterialApp(home: InicioPage(cliente: cliente)));
    await tester.tap(find.text('Ver la Pokédex'));
    await tester.pumpAndSettle();

    expect(find.byType(PokedexPage), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
  });
}
