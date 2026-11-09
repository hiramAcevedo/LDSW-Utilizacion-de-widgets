// Pruebas de las peticiones HTTP de la Pokédex (actividad 3.6). Usan el
// cliente simulado del propio paquete http (MockClient), así que no salen a
// internet: comprueban la dirección que se pide, la conversión del JSON y la
// excepción cuando la respuesta no es 200.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ldsw_utilizacion_de_widgets/pokeapi.dart';

/// Los campos que usa la app de GET /pokemon/25, copiados de la respuesta
/// real de pokeapi.co del 07-11-2026.
final Map<String, dynamic> pikachu = {
  'id': 25,
  'name': 'pikachu',
  'height': 4,
  'weight': 60,
  'types': [
    {
      'slot': 1,
      'type': {'name': 'electric', 'url': 'https://pokeapi.co/api/v2/type/13/'},
    },
  ],
  'stats': [
    {
      'base_stat': 35,
      'stat': {'name': 'hp'},
    },
    {
      'base_stat': 55,
      'stat': {'name': 'attack'},
    },
    {
      'base_stat': 40,
      'stat': {'name': 'defense'},
    },
    {
      'base_stat': 50,
      'stat': {'name': 'special-attack'},
    },
    {
      'base_stat': 50,
      'stat': {'name': 'special-defense'},
    },
    {
      'base_stat': 90,
      'stat': {'name': 'speed'},
    },
  ],
  'sprites': {
    'front_default': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
    'other': {
      'official-artwork': {
        'front_default': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
      },
    },
  },
};

void main() {
  test(
    'obtenerLista pide /pokemon?limit=151 y convierte cada resultado',
    () async {
      late Uri pedida;
      final cliente = MockClient((peticion) async {
        pedida = peticion.url;
        return http.Response(
          jsonEncode({
            'count': 1351,
            'results': [
              {
                'name': 'bulbasaur',
                'url': 'https://pokeapi.co/api/v2/pokemon/1/',
              },
              {
                'name': 'mr-mime',
                'url': 'https://pokeapi.co/api/v2/pokemon/122/',
              },
            ],
          }),
          200,
        );
      });

      final lista = await obtenerLista(cliente);

      expect(pedida.toString(), 'https://pokeapi.co/api/v2/pokemon?limit=151');
      expect(lista.map((p) => p.id), [1, 122]);
      expect(nombreVisible(lista.first.nombre), 'Bulbasaur');
      expect(nombreVisible(lista.last.nombre), 'Mr. Mime');
      expect(lista.first.imagen, endsWith('/sprites/pokemon/1.png'));
    },
  );

  test(
    'obtenerPokemon convierte tipos, medidas, estadísticas e imagen',
    () async {
      late Uri pedida;
      final cliente = MockClient((peticion) async {
        pedida = peticion.url;
        return http.Response(jsonEncode(pikachu), 200);
      });

      final pokemon = await obtenerPokemon(cliente, 25);

      expect(pedida.toString(), 'https://pokeapi.co/api/v2/pokemon/25');
      expect(pokemon.nombre, 'pikachu');
      expect(pokemon.tipos, ['electric']);
      expect(tiposEnEspanol[pokemon.tipos.first], 'Eléctrico');
      // La API mide en decímetros y pesa en hectogramos.
      expect(pokemon.alturaEnMetros, 0.4);
      expect(pokemon.pesoEnKilos, 6.0);
      expect(pokemon.estadisticas.keys, estadisticasEnEspanol.keys);
      expect(pokemon.estadisticas['speed'], 90);
      expect(pokemon.imagen, endsWith('/official-artwork/25.png'));
    },
  );

  test('Una respuesta distinta de 200 lanza PokeApiException', () async {
    final cliente = MockClient((_) async => http.Response('Not Found', 404));

    await expectLater(
      obtenerPokemon(cliente, 9999),
      throwsA(isA<PokeApiException>().having((e) => e.codigo, 'codigo', 404)),
    );
  });
}
