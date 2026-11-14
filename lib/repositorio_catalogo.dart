import 'package:cloud_firestore/cloud_firestore.dart';

import 'pelicula.dart';

/// El catálogo en Cloud Firestore: la colección `catalogo`, leída y escrita
/// siempre a través de [Pelicula.fromFirestore] y [Pelicula.toFirestore].
class RepositorioCatalogo {
  RepositorioCatalogo(this.firestore);

  final FirebaseFirestore firestore;

  /// La colección del producto integrador. La de la actividad 3.7,
  /// `peliculas`, se queda como estaba.
  static const String coleccion = 'catalogo';

  CollectionReference<Pelicula> get peliculas => firestore
      .collection(coleccion)
      .withConverter<Pelicula>(
        fromFirestore: Pelicula.fromFirestore,
        toFirestore: (pelicula, _) => pelicula.toFirestore(),
      );

  /// El catálogo ordenado por título. Es un Stream: cada alta o baja llega
  /// sola a las pantallas que lo escuchan.
  Stream<List<Pelicula>> escuchar() => peliculas
      .orderBy('titulo')
      .snapshots()
      .map(
        (consulta) => [for (final documento in consulta.docs) documento.data()],
      );

  /// Da de alta la película a nombre del usuario [uid].
  Future<DocumentReference<Pelicula>> darDeAlta(
    Pelicula pelicula, {
    required String uid,
  }) => peliculas.add(pelicula.conAutor(uid));

  /// Da de baja la película: borra su documento.
  Future<void> darDeBaja(Pelicula pelicula) {
    final id = pelicula.id;
    if (id == null) {
      throw ArgumentError('La película ${pelicula.titulo} no está guardada.');
    }
    return peliculas.doc(id).delete();
  }

  /// Si en el catálogo ya hay una película con ese id de TMDB.
  Future<bool> yaEsta(int tmdbId) async {
    final consulta = await peliculas
        .where('tmdbId', isEqualTo: tmdbId)
        .limit(1)
        .get();
    return consulta.docs.isNotEmpty;
  }
}
