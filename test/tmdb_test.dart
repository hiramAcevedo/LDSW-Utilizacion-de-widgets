// Pruebas de las peticiones HTTP a TMDB con un cliente de prueba
// (MockClient): la dirección y los encabezados que se mandan, cómo se leen la
// búsqueda y la ficha, y los errores.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ldsw_utilizacion_de_widgets/tmdb.dart';

/// Una respuesta JSON en UTF-8, como las de TMDB.
http.Response json(Object cuerpo, [int codigo = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(cuerpo)),
  codigo,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// La ficha de Roma como la devuelve `GET /3/movie/426426` con sus créditos.
final fichaDeRoma = {
  'id': 426426,
  'title': 'Roma',
  'release_date': '2018-08-30',
  'overview': 'Cleo es una de las dos trabajadoras domésticas…',
  'poster_path': '/roma.jpg',
  'genres': [
    {'id': 18, 'name': 'Drama'},
  ],
  'credits': {
    'cast': [
      {'name': 'Yalitza Aparicio', 'character': 'Cleo'},
    ],
    'crew': [
      {'name': 'Alfonso Cuarón', 'job': 'Director'},
      {'name': 'Alfonso Cuarón', 'job': 'Screenplay'},
      {'name': 'Gabriela Rodríguez', 'job': 'Producer'},
    ],
  },
};

void main() {
  test(
    'buscar pide /3/search/movie en español con el token en el encabezado',
    () async {
      late http.Request pedida;
      final tmdb = Tmdb(
        token: 'eyJ.token.de.lectura',
        cliente: MockClient((peticion) async {
          pedida = peticion;
          return json({
            'results': [
              {
                'id': 426426,
                'title': 'Roma',
                'release_date': '2018-08-30',
                'poster_path': '/roma.jpg',
              },
              {'id': 1, 'title': 'Roma, ciudad abierta', 'release_date': ''},
            ],
          });
        }),
      );

      final resultados = await tmdb.buscar('  Roma ');

      expect(pedida.url.host, 'api.themoviedb.org');
      expect(pedida.url.path, '/3/search/movie');
      expect(pedida.url.queryParameters['query'], 'Roma');
      expect(pedida.url.queryParameters['language'], 'es-MX');
      expect(pedida.url.queryParameters.containsKey('api_key'), isFalse);
      expect(pedida.headers['authorization'], 'Bearer eyJ.token.de.lectura');
      expect(resultados, hasLength(2));
      expect(resultados.first.titulo, 'Roma');
      expect(resultados.first.anio, 2018);
      expect(
        resultados.first.miniatura,
        'https://image.tmdb.org/t/p/w185/roma.jpg',
      );
      expect(resultados.last.anio, isNull);
      expect(resultados.last.miniatura, isNull);
    },
  );

  test('Con la clave de la versión 3, va en la dirección', () async {
    late http.Request pedida;
    final tmdb = Tmdb(
      token: 'abc123',
      cliente: MockClient((peticion) async {
        pedida = peticion;
        return json({'results': []});
      }),
    );

    expect(await tmdb.buscar('xyz'), isEmpty);
    expect(pedida.url.queryParameters['api_key'], 'abc123');
    expect(pedida.headers.containsKey('authorization'), isFalse);
  });

  test('ficha trae el director de los créditos, los géneros, la sinopsis y el póster', () async {
    late http.Request pedida;
    final tmdb = Tmdb(
      token: 'eyJ.token.de.lectura',
      cliente: MockClient((peticion) async {
        pedida = peticion;
        return json(fichaDeRoma);
      }),
    );

    final ficha = await tmdb.ficha(426426);

    expect(pedida.url.path, '/3/movie/426426');
    expect(pedida.url.queryParameters['append_to_response'], 'credits');
    expect(ficha.titulo, 'Roma');
    expect(ficha.anio, 2018);
    expect(ficha.director, 'Alfonso Cuarón');
    expect(ficha.genero, 'Drama');
    expect(ficha.sinopsis, startsWith('Cleo es una'));
    expect(ficha.imagen, 'https://image.tmdb.org/t/p/w500/roma.jpg');
  });

  test(
    'Los errores de TMDB llegan como TmdbException con su mensaje',
    () async {
      Tmdb conCodigo(int codigo) => Tmdb(
        token: 'eyJ.token',
        cliente: MockClient(
          (peticion) async => json({'status_message': 'x'}, codigo),
        ),
      );

      await expectLater(
        conCodigo(401).buscar('Roma'),
        throwsA(
          isA<TmdbException>().having(
            (e) => e.mensaje,
            'mensaje',
            'TMDB no aceptó el token.',
          ),
        ),
      );
      await expectLater(conCodigo(404).ficha(1), throwsA(isA<TmdbException>()));
      await expectLater(
        conCodigo(500).buscar('Roma'),
        throwsA(
          isA<TmdbException>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('500'),
          ),
        ),
      );
    },
  );

  test('Sin token no hay búsqueda y no se manda ninguna petición', () async {
    var peticiones = 0;
    final tmdb = Tmdb(
      token: '  ',
      cliente: MockClient((peticion) async {
        peticiones++;
        return json({});
      }),
    );

    expect(tmdb.configurado, isFalse);
    await expectLater(tmdb.buscar('Roma'), throwsA(isA<TmdbException>()));
    expect(peticiones, 0);
  });
}
