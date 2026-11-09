// Pruebas de widget de la Pokédex (actividad 3.6). El cliente HTTP es
// simulado, así que no salen a internet:
// - la lista: sin conexión muestra el mensaje con Reintentar y, al
//   reintentar, la lista;
// - el buscador: pide un número y abre su detalle, o avisa si no está
//   entre 1 y 151;
// - el detalle: Anterior y Siguiente piden el Pokémon de al lado, Anterior
//   está deshabilitado en el #001 y Siguiente en el #151.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ldsw_utilizacion_de_widgets/pokeapi.dart';
import 'package:ldsw_utilizacion_de_widgets/pokedex.dart';

/// Los 151 de la lista, en orden, como los entrega PokéAPI.
final List<PokemonResumen> pokedex = [
  for (var id = 1; id <= 151; id++)
    PokemonResumen(id: id, nombre: 'pokemon$id'),
];

/// Un cliente que responde GET /pokemon/{id} con un Pokémon mínimo y anota
/// cada número que se pide.
MockClient clienteDeDetalle(List<int> pedidos) {
  return MockClient((peticion) async {
    final id = int.parse(peticion.url.pathSegments.last);
    pedidos.add(id);
    return http.Response(
      jsonEncode({
        'id': id,
        'name': 'pokemon$id',
        'height': 10,
        'weight': 100,
        'types': [
          {
            'slot': 1,
            'type': {'name': 'normal'},
          },
        ],
        'stats': [
          for (final nombre in estadisticasEnEspanol.keys)
            {
              'base_stat': 50,
              'stat': {'name': nombre},
            },
        ],
        'sprites': {
          'other': {
            'official-artwork': {
              'front_default': 'https://pokeapi.co/sprites/$id.png',
            },
          },
        },
      }),
      200,
    );
  });
}

/// Un cliente que responde la lista de los 151 (GET /pokemon?limit=151) y,
/// para cada detalle, lo mismo que [clienteDeDetalle].
MockClient clienteDeListaYDetalle(List<int> pedidos) {
  final detalle = clienteDeDetalle(pedidos);
  return MockClient((peticion) async {
    if (peticion.url.pathSegments.last == 'pokemon') {
      return http.Response(
        jsonEncode({
          'results': [
            for (final p in pokedex)
              {
                'name': p.nombre,
                'url': 'https://pokeapi.co/api/v2/pokemon/${p.id}/',
              },
          ],
        }),
        200,
      );
    }
    return detalle.get(peticion.url);
  });
}

/// El botón (Anterior o Siguiente) que contiene ese texto.
ButtonStyleButton boton(WidgetTester tester, String texto) {
  return tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.text(texto),
      matching: find.bySubtype<ButtonStyleButton>(),
    ),
  );
}

void main() {
  testWidgets('Sin red muestra el mensaje y Reintentar trae la lista', (
    WidgetTester tester,
  ) async {
    var peticiones = 0;
    final cliente = MockClient((peticion) async {
      peticiones++;
      if (peticiones == 1) {
        throw http.ClientException('Sin conexión', peticion.url);
      }
      return http.Response(
        jsonEncode({
          'results': [
            {
              'name': 'bulbasaur',
              'url': 'https://pokeapi.co/api/v2/pokemon/1/',
            },
            {'name': 'pikachu', 'url': 'https://pokeapi.co/api/v2/pokemon/25/'},
          ],
        }),
        200,
      );
    });

    await tester.pumpWidget(MaterialApp(home: PokedexPage(cliente: cliente)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar la Pokédex'), findsOneWidget);
    expect(
      find.text('Revisa la conexión a internet e inténtalo de nuevo.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(peticiones, 2);
    expect(find.text('2 Pokémon'), findsOneWidget);
    expect(find.byType(TarjetaPokemon), findsNWidgets(2));
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('#001'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('#025'), findsOneWidget);
  });

  testWidgets(
    'En el #001 Anterior está deshabilitado y Siguiente pide el #002',
    (WidgetTester tester) async {
      final pedidos = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PokemonPage(
            pokedex: pokedex,
            indice: 0,
            cliente: clienteDeDetalle(pedidos),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('#001'), findsOneWidget);
      expect(boton(tester, 'Anterior').enabled, isFalse);
      expect(boton(tester, 'Siguiente').enabled, isTrue);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('#002'), findsOneWidget);
      expect(boton(tester, 'Anterior').enabled, isTrue);

      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(find.text('#001'), findsOneWidget);
      expect(pedidos, [1, 2, 1]);
    },
  );

  testWidgets(
    'El buscador pide el número con teclado numérico, avisa fuera del 1 al 151 '
    'y abre el detalle, donde siguen Anterior y Siguiente',
    (WidgetTester tester) async {
      final pedidos = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PokedexPage(cliente: clienteDeListaYDetalle(pedidos)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Buscar por número'));
      await tester.pumpAndSettle();
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.keyboardType, TextInputType.number);

      for (final fuera in ['152', '0']) {
        await tester.enterText(find.byType(TextField), fuera);
        await tester.tap(find.text('Ver'));
        await tester.pumpAndSettle();
        expect(find.text('Escribe un número del 1 al 151'), findsOneWidget);
        expect(find.byType(PokemonPage), findsNothing);
      }

      await tester.enterText(find.byType(TextField), '25');
      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();
      expect(find.byType(PokemonPage), findsOneWidget);
      expect(find.text('#025'), findsOneWidget);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('#026'), findsOneWidget);
      expect(pedidos, [25, 26]);
    },
  );

  testWidgets('En el #151 Siguiente está deshabilitado', (
    WidgetTester tester,
  ) async {
    final pedidos = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PokemonPage(
          pokedex: pokedex,
          indice: 150,
          cliente: clienteDeDetalle(pedidos),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('#151'), findsOneWidget);
    expect(boton(tester, 'Siguiente').enabled, isFalse);
    expect(boton(tester, 'Anterior').enabled, isTrue);
    expect(pedidos, [151]);
  });
}
