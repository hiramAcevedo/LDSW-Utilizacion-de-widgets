import 'package:flutter/material.dart';

/// Una película del catálogo, con los datos que muestra su tarjeta.
class Pelicula {
  const Pelicula({
    required this.titulo,
    required this.anio,
    required this.director,
    required this.genero,
    required this.color,
  });

  final String titulo;
  final int anio;
  final String director;
  final String genero;

  /// Color del póster mientras el catálogo no tiene imágenes.
  final Color color;
}

/// Las películas del catálogo. Son contenido de ejemplo: en las actividades
/// siguientes llegarán de un servicio HTTP y de la base de datos.
const List<Pelicula> peliculas = [
  Pelicula(
    titulo: 'Roma',
    anio: 2018,
    director: 'Alfonso Cuarón',
    genero: 'Drama',
    color: Color(0xFF546E7A),
  ),
  Pelicula(
    titulo: 'Coco',
    anio: 2017,
    director: 'Lee Unkrich',
    genero: 'Animación',
    color: Color(0xFFEF6C00),
  ),
  Pelicula(
    titulo: 'Amores perros',
    anio: 2000,
    director: 'Alejandro González Iñárritu',
    genero: 'Drama',
    color: Color(0xFF8D6E63),
  ),
  Pelicula(
    titulo: 'El laberinto del fauno',
    anio: 2006,
    director: 'Guillermo del Toro',
    genero: 'Fantasía',
    color: Color(0xFF2E7D32),
  ),
];
