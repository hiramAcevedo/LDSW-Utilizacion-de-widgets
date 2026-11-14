// Pruebas del modelo y del catálogo en Firestore: cómo se escribe una
// película en un documento, cómo se lee de vuelta, qué pasa si al documento
// le falta un dato, y el alta y la baja. Usan la base simulada de
// fake_cloud_firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ldsw_utilizacion_de_widgets/pelicula.dart';
import 'package:ldsw_utilizacion_de_widgets/repositorio_catalogo.dart';

import 'datos_de_prueba.dart';

void main() {
  final roma = peliculasDeEjemplo.first;

  // FieldValue se queda con la fábrica que encuentra la primera vez que se
  // usa, y la base simulada instala la suya al crearse: tiene que ir antes.
  setUpAll(FakeFirebaseFirestore.new);

  test('toFirestore guarda los seis datos, el id de TMDB, el autor y la hora '
      'del servidor', () {
    final datos = roma.conAutor('uid-1').toFirestore();

    expect(
      datos.keys,
      unorderedEquals([
        'titulo',
        'anio',
        'director',
        'genero',
        'sinopsis',
        'imagen',
        'tmdbId',
        'agregadaPor',
        'creada',
      ]),
    );
    expect(datos['titulo'], 'Roma');
    expect(datos['anio'], 2018);
    expect(datos['director'], 'Alfonso Cuarón');
    expect(datos['genero'], 'Drama');
    expect(datos['sinopsis'], startsWith('Cleo trabaja'));
    expect(datos['imagen'], 'https://image.tmdb.org/t/p/w500/roma.jpg');
    expect(datos['tmdbId'], 426426);
    expect(datos['agregadaPor'], 'uid-1');
    expect(datos['creada'], isA<FieldValue>());
  });

  test('fromFirestore lee el documento con su id y su fecha', () async {
    final firestore = FakeFirebaseFirestore();
    final guardada = DateTime.utc(2026, 11, 14, 12);
    await firestore.collection('catalogo').doc('roma').set({
      'titulo': 'Roma',
      'anio': 2018,
      'director': 'Alfonso Cuarón',
      'genero': 'Drama',
      'sinopsis': 'Cleo trabaja para una familia de la colonia Roma.',
      'imagen': 'https://image.tmdb.org/t/p/w500/roma.jpg',
      'tmdbId': null,
      'agregadaPor': 'uid-1',
      'creada': Timestamp.fromDate(guardada),
    });

    final documento = await RepositorioCatalogo(firestore).peliculas
        .doc('roma')
        .get();
    final pelicula = documento.data()!;

    expect(pelicula.id, 'roma');
    expect(pelicula.titulo, 'Roma');
    expect(pelicula.anio, 2018);
    expect(pelicula.sinopsis, startsWith('Cleo'));
    expect(pelicula.tmdbId, isNull);
    expect(pelicula.agregadaPor, 'uid-1');
    expect(pelicula.creada!.isAtSameMomentAs(guardada), isTrue);
  });

  test(
    'Un documento al que le falta la sinopsis lanza FormatException',
    () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('catalogo').doc('incompleta').set({
        'titulo': 'Roma',
        'anio': 2018,
        'director': 'Alfonso Cuarón',
        'genero': 'Drama',
        'imagen': 'https://image.tmdb.org/t/p/w500/roma.jpg',
      });

      final referencia = RepositorioCatalogo(firestore).peliculas
          .doc('incompleta');

      // La conversión puede ocurrir al leer el documento o al pedir sus datos.
      await expectLater(
        () async => (await referencia.get()).data(),
        throwsFormatException,
      );
    },
  );

  test('darDeAlta crea el documento a nombre de quien la da de alta', () async {
    final firestore = FakeFirebaseFirestore();

    final referencia = await RepositorioCatalogo(firestore)
        .darDeAlta(roma, uid: 'uid-1');

    final coleccion = await firestore.collection('catalogo').get();
    expect(coleccion.docs, hasLength(1));
    final documento = coleccion.docs.single;
    expect(documento.id, referencia.id);
    expect(documento.data()['titulo'], 'Roma');
    expect(documento.data()['agregadaPor'], 'uid-1');
    expect(documento.data()['creada'], isA<Timestamp>());
  });

  test(
    'darDeBaja borra el documento y yaEsta lo reconoce por su id de TMDB',
    () async {
      final firestore = FakeFirebaseFirestore();
      final catalogo = RepositorioCatalogo(firestore);
      await catalogo.darDeAlta(roma, uid: 'uid-1');
      expect(await catalogo.yaEsta(426426), isTrue);
      expect(await catalogo.yaEsta(55), isFalse);

      final guardada = (await catalogo.peliculas.get()).docs.single.data();
      await catalogo.darDeBaja(guardada);

      expect((await firestore.collection('catalogo').get()).docs, isEmpty);
      expect(await catalogo.yaEsta(426426), isFalse);
    },
  );

  test('Cada título conserva su color de respaldo', () {
    expect(roma.colorDeRespaldo, roma.colorDeRespaldo);
    expect(coloresDePoster, contains(roma.colorDeRespaldo));
  });
}
