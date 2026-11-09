import 'dart:convert';

import 'package:http/http.dart' as http;

/// La dirección base de PokéAPI (https://pokeapi.co): una API REST pública,
/// sin llave ni registro, que responde en JSON.
const String urlPokeApi = 'https://pokeapi.co/api/v2';

/// Cuántos Pokémon trae la lista: los 151 de la primera generación.
const int totalPokedex = 151;

/// Lo que pasa cuando PokéAPI responde con un código distinto de 200. Como en
/// la receta "Fetch data from the internet", se lanza una excepción en vez de
/// devolver null, para que el FutureBuilder lo reciba como error.
class PokeApiException implements Exception {
  const PokeApiException(this.codigo);

  final int codigo;

  @override
  String toString() => 'PokéAPI respondió con el código $codigo.';
}

/// Un Pokémon de la lista, tal como llega en GET /pokemon?limit=151: el
/// nombre y la dirección de su detalle, de la que se toma el número.
class PokemonResumen {
  const PokemonResumen({required this.id, required this.nombre});

  final int id;
  final String nombre;

  /// La imagen chica de la lista (96 x 96). Es la dirección que el detalle
  /// devuelve en sprites.front_default; se arma con el número para no pedir
  /// los 151 detalles sólo para dibujar la lista.
  String get imagen =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

  factory PokemonResumen.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'name': String nombre, 'url': String url} => PokemonResumen(
        id: _numeroDesdeUrl(url),
        nombre: nombre,
      ),
      _ => throw const FormatException(
        'La lista no tiene el formato esperado.',
      ),
    };
  }
}

/// El detalle de un Pokémon, tal como llega en GET /pokemon/{id}.
class Pokemon {
  const Pokemon({
    required this.id,
    required this.nombre,
    required this.tipos,
    required this.altura,
    required this.peso,
    required this.estadisticas,
    required this.imagen,
  });

  final int id;
  final String nombre;

  /// Los tipos en inglés, como los da la API (por ejemplo, electric).
  final List<String> tipos;

  /// La altura en decímetros y el peso en hectogramos, las unidades de la API.
  final int altura;
  final int peso;

  /// Las seis estadísticas base, por su nombre en la API (hp, attack, etc.).
  final Map<String, int> estadisticas;

  /// La imagen oficial (sprites.other.official-artwork.front_default).
  final String? imagen;

  double get alturaEnMetros => altura / 10;
  double get pesoEnKilos => peso / 10;

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'name': String nombre,
        'height': int altura,
        'weight': int peso,
        'types': List<dynamic> tipos,
        'stats': List<dynamic> estadisticas,
        'sprites': Map<String, dynamic> sprites,
      } =>
        Pokemon(
          id: id,
          nombre: nombre,
          altura: altura,
          peso: peso,
          tipos: [
            for (final tipo in tipos)
              if (tipo case {'type': {'name': String nombreTipo}}) nombreTipo,
          ],
          estadisticas: {
            for (final estadistica in estadisticas)
              if (estadistica case {
                'base_stat': int valor,
                'stat': {'name': String clave},
              })
                clave: valor,
          },
          imagen: switch (sprites) {
            {'other': {'official-artwork': {'front_default': String url}}} =>
              url,
            {'front_default': String url} => url,
            _ => null,
          },
        ),
      _ => throw const FormatException(
        'El Pokémon no tiene el formato esperado.',
      ),
    };
  }
}

/// Pide la lista de la Pokédex: GET /pokemon?limit=151.
Future<List<PokemonResumen>> obtenerLista(http.Client cliente) async {
  final datos = await _pedirJson(
    cliente,
    Uri.parse('$urlPokeApi/pokemon?limit=$totalPokedex'),
  );
  return switch (datos) {
    {'results': List<dynamic> resultados} => [
      for (final resultado in resultados)
        PokemonResumen.fromJson(resultado as Map<String, dynamic>),
    ],
    _ => throw const FormatException('La lista no tiene el formato esperado.'),
  };
}

/// Pide el detalle de un Pokémon por su número: GET /pokemon/{id}.
Future<Pokemon> obtenerPokemon(http.Client cliente, int id) async {
  final datos = await _pedirJson(cliente, Uri.parse('$urlPokeApi/pokemon/$id'));
  return Pokemon.fromJson(datos);
}

/// La petición GET y la conversión del cuerpo a un Map, con el código 200
/// como única respuesta válida.
Future<Map<String, dynamic>> _pedirJson(http.Client cliente, Uri url) async {
  final respuesta = await cliente.get(
    url,
    headers: {'Accept': 'application/json'},
  );
  if (respuesta.statusCode != 200) {
    throw PokeApiException(respuesta.statusCode);
  }
  return jsonDecode(respuesta.body) as Map<String, dynamic>;
}

/// El número del Pokémon, que es el último tramo de su dirección
/// (https://pokeapi.co/api/v2/pokemon/25/ es el 25).
int _numeroDesdeUrl(String url) {
  final tramos = Uri.parse(url).pathSegments.where((t) => t.isNotEmpty);
  return int.parse(tramos.last);
}

/// El nombre como se escribe, no como lo guarda la API: la primera letra en
/// mayúscula y los cuatro casos de la primera generación que la API escribe
/// distinto.
String nombreVisible(String nombre) {
  const especiales = {
    'nidoran-f': 'Nidoran♀',
    'nidoran-m': 'Nidoran♂',
    'mr-mime': 'Mr. Mime',
    'farfetchd': "Farfetch'd",
  };
  final especial = especiales[nombre];
  if (especial != null) return especial;
  if (nombre.isEmpty) return nombre;
  return nombre[0].toUpperCase() + nombre.substring(1);
}

/// El número con tres cifras, como en la Pokédex: 25 es #025.
String numeroVisible(int id) => '#${id.toString().padLeft(3, '0')}';

/// Los tipos en español, con los nombres oficiales de los juegos.
const Map<String, String> tiposEnEspanol = {
  'normal': 'Normal',
  'fire': 'Fuego',
  'water': 'Agua',
  'electric': 'Eléctrico',
  'grass': 'Planta',
  'ice': 'Hielo',
  'fighting': 'Lucha',
  'poison': 'Veneno',
  'ground': 'Tierra',
  'flying': 'Volador',
  'psychic': 'Psíquico',
  'bug': 'Bicho',
  'rock': 'Roca',
  'ghost': 'Fantasma',
  'dragon': 'Dragón',
  'dark': 'Siniestro',
  'steel': 'Acero',
  'fairy': 'Hada',
};

/// Las seis estadísticas base, en el orden en que llegan y con su nombre en
/// español.
const Map<String, String> estadisticasEnEspanol = {
  'hp': 'PS',
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'Ataque esp.',
  'special-defense': 'Defensa esp.',
  'speed': 'Velocidad',
};
