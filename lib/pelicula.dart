import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Una película del catálogo, con los datos que muestra su tarjeta. Cada una
/// es un documento de la colección `peliculas` de Cloud Firestore.
class Pelicula {
  const Pelicula({
    this.id,
    required this.titulo,
    required this.anio,
    required this.director,
    required this.genero,
    required this.color,
    this.creada,
  });

  /// El id del documento en Firestore; es `null` mientras no se guarda.
  final String? id;

  final String titulo;
  final int anio;
  final String director;
  final String genero;

  /// Color del póster mientras el catálogo no tiene imágenes.
  final Color color;

  /// Cuándo se guardó en la base. Lo pone el servidor de Firestore.
  final DateTime? creada;

  /// Lee una película de un documento de la colección `peliculas`. Si al
  /// documento le falta un campo o trae otro tipo, lanza [FormatException].
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
            'color': int color,
          } &&
          final datos =>
        Pelicula(
          id: documento.id,
          titulo: titulo,
          anio: anio,
          director: director,
          genero: genero,
          color: Color(color),
          // Mientras el servidor no confirma la escritura, creada llega nula.
          creada: (datos['creada'] as Timestamp?)?.toDate(),
        ),
      _ => throw FormatException(
        'La película ${documento.id} no tiene los campos esperados.',
      ),
    };
  }

  /// Los campos del documento. El color se guarda como entero ARGB y, si la
  /// película es nueva, la fecha de creación la pone el servidor.
  Map<String, Object?> toFirestore() => {
    'titulo': titulo,
    'anio': anio,
    'director': director,
    'genero': genero,
    'color': color.toARGB32(),
    'creada': creada == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(creada!),
  };
}

/// Los géneros que ofrece el formulario para agregar una película.
const List<String> generos = [
  'Acción',
  'Animación',
  'Ciencia ficción',
  'Comedia',
  'Documental',
  'Drama',
  'Fantasía',
  'Musical',
  'Romance',
  'Suspenso',
  'Terror',
];

/// Los colores de póster que ofrece el formulario. Los cuatro primeros son los
/// de las películas de ejemplo de las actividades 3.4 y 3.5.
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
