// Datos que comparten las pruebas: las cuatro películas de ejemplo de las
// actividades 3.4 y 3.5 y una base simulada de Cloud Firestore que ya las
// tiene guardadas. FakeFirebaseFirestore vive en memoria: no sale a internet.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:ldsw_utilizacion_de_widgets/pelicula.dart';
import 'package:ldsw_utilizacion_de_widgets/repositorio_peliculas.dart';

const List<Pelicula> peliculasDeEjemplo = [
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

/// Las mismas, en el orden en que las muestra el catálogo: por título.
final List<Pelicula> peliculasPorTitulo = [...peliculasDeEjemplo]
  ..sort((a, b) => a.titulo.compareTo(b.titulo));

/// Una base simulada con las cuatro películas de ejemplo ya guardadas.
Future<RepositorioPeliculas> repositorioConEjemplos() async {
  final repositorio = RepositorioPeliculas(FakeFirebaseFirestore());
  for (final pelicula in peliculasDeEjemplo) {
    await repositorio.agregar(pelicula);
  }
  return repositorio;
}
