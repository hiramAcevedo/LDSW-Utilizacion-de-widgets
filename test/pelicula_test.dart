// Pruebas del modelo y del acceso a Firestore (actividad 3.7): cómo se escribe
// una película en un documento, cómo se lee de vuelta y qué pasa si al
// documento le falta un campo. Usan la base simulada de fake_cloud_firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ldsw_utilizacion_de_widgets/repositorio_peliculas.dart';

import 'datos_de_prueba.dart';

void main() {
  final roma = peliculasDeEjemplo.first;

  // FieldValue se queda con la fábrica que encuentra la primera vez que se
  // usa, y la base simulada instala la suya al crearse: tiene que ir antes.
  setUpAll(FakeFirebaseFirestore.new);

  test('toFirestore guarda los cinco datos con su tipo y deja la fecha al servidor', () {
    final datos = roma.toFirestore();

    expect(
      datos.keys,
      unorderedEquals([
        'titulo',
        'anio',
        'director',
        'genero',
        'color',
        'creada',
      ]),
    );
    expect(datos['titulo'], 'Roma');
    expect(datos['anio'], 2018);
    expect(datos['director'], 'Alfonso Cuarón');
    expect(datos['genero'], 'Drama');
    expect(datos['color'], 0xFF546E7A);
    expect(datos['creada'], isA<FieldValue>());
  });

  test(
    'fromFirestore lee el documento con su id, su color y su fecha',
    () async {
      final firestore = FakeFirebaseFirestore();
      final guardada = DateTime.utc(2026, 11, 10, 12);
      await firestore.collection('peliculas').doc('roma').set({
        'titulo': 'Roma',
        'anio': 2018,
        'director': 'Alfonso Cuarón',
        'genero': 'Drama',
        'color': 0xFF546E7A,
        'creada': Timestamp.fromDate(guardada),
      });

      final documento = await RepositorioPeliculas(firestore).peliculas
          .doc('roma')
          .get();
      final pelicula = documento.data()!;

      expect(pelicula.id, 'roma');
      expect(pelicula.titulo, 'Roma');
      expect(pelicula.anio, 2018);
      expect(pelicula.director, 'Alfonso Cuarón');
      expect(pelicula.genero, 'Drama');
      expect(pelicula.color, const Color(0xFF546E7A));
      expect(pelicula.creada!.isAtSameMomentAs(guardada), isTrue);
    },
  );

  test('Un documento al que le falta un campo lanza FormatException', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('peliculas').doc('incompleta').set({
      'titulo': 'Roma',
      'anio': '2018',
    });

    final referencia = RepositorioPeliculas(firestore).peliculas
        .doc('incompleta');

    // La conversión puede ocurrir al leer el documento o al pedir sus datos.
    await expectLater(
      () async => (await referencia.get()).data(),
      throwsFormatException,
    );
  });

  test(
    'agregar crea un documento en peliculas con el id que pone Firestore',
    () async {
      final firestore = FakeFirebaseFirestore();

      final referencia = await RepositorioPeliculas(firestore).agregar(roma);

      final coleccion = await firestore.collection('peliculas').get();
      expect(coleccion.docs, hasLength(1));
      final documento = coleccion.docs.single;
      expect(documento.id, referencia.id);
      expect(documento.data()['titulo'], 'Roma');
      expect(documento.data()['anio'], 2018);
      expect(documento.data()['creada'], isA<Timestamp>());
    },
  );
}
