import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

/// Una película del catálogo, como se guarda en la colección `catalogo` de
/// Cloud Firestore: los seis datos de la pantalla de administración, el id de
/// TMDB si se dio de alta desde la búsqueda, quién la dio de alta y cuándo.
class Pelicula {
  const Pelicula({
    this.id,
    required this.titulo,
    required this.anio,
    required this.director,
    required this.genero,
    required this.sinopsis,
    required this.imagen,
    this.tmdbId,
    this.agregadaPor,
    this.creada,
  });

  /// El id del documento en Firestore; nulo mientras no se guarda.
  final String? id;
  final String titulo;

  /// El año de estreno.
  final int anio;
  final String director;

  /// El género cinematográfico; si son dos, van separados por coma.
  final String genero;
  final String sinopsis;

  /// La URL del póster.
  final String imagen;

  /// El id de la película en TMDB, si se dio de alta desde la búsqueda.
  final int? tmdbId;

  /// El uid de quien la dio de alta.
  final String? agregadaPor;

  /// La hora del servidor en que se dio de alta.
  final DateTime? creada;

  /// Convierte un documento de Firestore en una película. Si al documento le
  /// falta un dato o trae otro tipo, lanza un FormatException.
  factory Pelicula.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> documento,
    SnapshotOptions? opciones,
  ) {
    return switch (documento.data()) {
      {
            'titulo': String titulo,
            'anio': int anio,
            'director': String director,
            'genero': String genero,
            'sinopsis': String sinopsis,
            'imagen': String imagen,
          } &&
          final datos =>
        Pelicula(
          id: documento.id,
          titulo: titulo,
          anio: anio,
          director: director,
          genero: genero,
          sinopsis: sinopsis,
          imagen: imagen,
          tmdbId: datos['tmdbId'] as int?,
          agregadaPor: datos['agregadaPor'] as String?,
          creada: (datos['creada'] as Timestamp?)?.toDate(),
        ),
      _ => throw FormatException(
        'La película ${documento.id} no tiene los campos esperados.',
      ),
    };
  }

  /// Los campos del documento. Si la película es nueva, la hora la pone el
  /// servidor.
  Map<String, Object?> toFirestore() => {
    'titulo': titulo,
    'anio': anio,
    'director': director,
    'genero': genero,
    'sinopsis': sinopsis,
    'imagen': imagen,
    'tmdbId': tmdbId,
    'agregadaPor': agregadaPor,
    'creada': creada == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(creada!),
  };

  /// La misma película, a nombre de quien la da de alta.
  Pelicula conAutor(String uid) => Pelicula(
    id: id,
    titulo: titulo,
    anio: anio,
    director: director,
    genero: genero,
    sinopsis: sinopsis,
    imagen: imagen,
    tmdbId: tmdbId,
    agregadaPor: uid,
    creada: creada,
  );

  /// El color del bloque que se ve mientras carga el póster o si la URL no
  /// responde. Sale del título, así que cada película conserva el suyo.
  Color get colorDeRespaldo =>
      coloresDePoster[titulo.codeUnits.fold(0, (suma, letra) => suma + letra) %
          coloresDePoster.length];
}

/// Los colores de los pósteres de las actividades 3.4 a 3.7; ahora son el
/// fondo mientras carga la imagen.
const List<Color> coloresDePoster = [
  Color(0xFF546E7A),
  Color(0xFFEF6C00),
  Color(0xFF8D6E63),
  Color(0xFF2E7D32),
  Color(0xFF6A1B9A),
  Color(0xFFC62828),
  Color(0xFF1565C0),
  Color(0xFF00838F),
];
