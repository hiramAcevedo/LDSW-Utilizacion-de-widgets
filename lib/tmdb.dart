import 'dart:convert';

import 'package:http/http.dart' as http;

/// Las peticiones HTTP a la API de TMDB (developer.themoviedb.org), en
/// español de México: buscar una película por su título y traer su ficha
/// para llenar el formulario de alta.
///
/// El token no va en el código: se pasa al compilar con
/// `--dart-define-from-file=tmdb.json` (ver README). Acepta el token de
/// lectura (API Read Access Token) o la clave de la versión 3 (API Key).
class Tmdb {
  Tmdb({required String token, http.Client? cliente})
    : token = token.trim(),
      _cliente = cliente ?? http.Client();

  final String token;
  final http.Client _cliente;

  static const String servidor = 'api.themoviedb.org';

  /// El aviso que piden las condiciones de uso de la API de TMDB, tal cual.
  static const String atribucion =
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';
  static const String idioma = 'es-MX';

  /// Si hay token. Sin él, la pantalla de alta sólo ofrece el formulario.
  bool get configurado => token.isNotEmpty;

  /// La URL de una imagen de TMDB en el tamaño pedido (`w185`, `w500`…), o
  /// null si la película no tiene póster.
  static String? urlDeImagen(Object? ruta, {required String tamano}) =>
      ruta is String && ruta.isNotEmpty
      ? 'https://image.tmdb.org/t/p/$tamano$ruta'
      : null;

  /// Busca películas por título: `GET /3/search/movie`.
  Future<List<ResultadoTmdb>> buscar(String texto) async {
    final json = await _get('/3/search/movie', {
      'query': texto.trim(),
      'language': idioma,
      'include_adult': 'false',
      'page': '1',
    });
    final resultados = json['results'] as List<dynamic>? ?? const [];
    return [
      for (final resultado in resultados)
        if (resultado is Map<String, dynamic>)
          ResultadoTmdb.desdeJson(resultado),
    ];
  }

  /// La ficha de una película con su reparto y su equipo:
  /// `GET /3/movie/{id}?append_to_response=credits`.
  Future<FichaTmdb> ficha(int id) async {
    final json = await _get('/3/movie/$id', {
      'language': idioma,
      'append_to_response': 'credits',
    });
    return FichaTmdb.desdeJson(json);
  }

  Future<Map<String, dynamic>> _get(
    String ruta,
    Map<String, String> parametros,
  ) async {
    if (!configurado) throw const TmdbException('Falta el token de TMDB.');
    // El token de lectura es un JWT (lleva puntos) y va en el encabezado;
    // la clave de la versión 3 va en la dirección.
    final conClave = !token.contains('.');
    final direccion = Uri.https(servidor, ruta, {
      ...parametros,
      if (conClave) 'api_key': token,
    });
    final http.Response respuesta;
    try {
      respuesta = await _cliente.get(
        direccion,
        headers: {
          'accept': 'application/json',
          if (!conClave) 'authorization': 'Bearer $token',
        },
      );
    } on http.ClientException {
      throw const TmdbException('Sin conexión con TMDB.');
    }
    switch (respuesta.statusCode) {
      case 200:
        return jsonDecode(utf8.decode(respuesta.bodyBytes))
            as Map<String, dynamic>;
      case 401:
        throw const TmdbException('TMDB no aceptó el token.');
      case 404:
        throw const TmdbException('TMDB no encontró esa película.');
      case 429:
        throw const TmdbException(
          'Demasiadas búsquedas seguidas: espera unos segundos.',
        );
      default:
        throw TmdbException(
          'TMDB respondió con el código ${respuesta.statusCode}.',
        );
    }
  }
}

/// Un resultado de la búsqueda: lo necesario para reconocer la película.
class ResultadoTmdb {
  const ResultadoTmdb({
    required this.id,
    required this.titulo,
    this.anio,
    this.miniatura,
  });

  factory ResultadoTmdb.desdeJson(Map<String, dynamic> json) => ResultadoTmdb(
    id: json['id'] as int,
    titulo:
        json['title'] as String? ??
        json['original_title'] as String? ??
        'Sin título',
    anio: anioDe(json['release_date']),
    miniatura: Tmdb.urlDeImagen(json['poster_path'], tamano: 'w185'),
  );

  final int id;
  final String titulo;
  final int? anio;
  final String? miniatura;
}

/// La ficha de una película con los datos que pide la pantalla de alta.
class FichaTmdb {
  const FichaTmdb({
    required this.id,
    required this.titulo,
    required this.anio,
    required this.director,
    required this.genero,
    required this.sinopsis,
    required this.imagen,
  });

  factory FichaTmdb.desdeJson(Map<String, dynamic> json) {
    final creditos = json['credits'] as Map<String, dynamic>?;
    final equipo = creditos?['crew'] as List<dynamic>? ?? const [];
    final directores = [
      for (final persona in equipo)
        if (persona is Map<String, dynamic> && persona['job'] == 'Director')
          persona['name'] as String,
    ];
    final generos = [
      for (final genero in json['genres'] as List<dynamic>? ?? const [])
        if (genero is Map<String, dynamic>) genero['name'] as String,
    ];
    return FichaTmdb(
      id: json['id'] as int,
      titulo: json['title'] as String? ?? '',
      anio: anioDe(json['release_date']),
      director: directores.take(2).join(', '),
      genero: generos.take(2).join(', '),
      sinopsis: (json['overview'] as String? ?? '').trim(),
      imagen: Tmdb.urlDeImagen(json['poster_path'], tamano: 'w500') ?? '',
    );
  }

  final int id;
  final String titulo;
  final int? anio;

  /// Quien la dirigió; si son dos, separados por coma.
  final String director;

  /// Los dos primeros géneros de TMDB, separados por coma.
  final String genero;
  final String sinopsis;

  /// La URL del póster en 500 px de ancho, o vacía si no tiene.
  final String imagen;
}

/// El año de una fecha de TMDB (`2018-08-30`), o null si no trae.
int? anioDe(Object? fecha) => fecha is String && fecha.length >= 4
    ? int.tryParse(fecha.substring(0, 4))
    : null;

/// Un error de TMDB con su mensaje en español.
class TmdbException implements Exception {
  const TmdbException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
