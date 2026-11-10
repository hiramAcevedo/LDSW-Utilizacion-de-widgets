import 'package:cloud_firestore/cloud_firestore.dart';

import 'pelicula.dart';

/// El acceso a la colección `peliculas` de Cloud Firestore. Las pantallas lo
/// reciben por el constructor: la app le pasa la base real y las pruebas una
/// simulada (`FakeFirebaseFirestore`), que no sale a internet.
class RepositorioPeliculas {
  RepositorioPeliculas(this.firestore);

  final FirebaseFirestore firestore;

  /// El nombre de la colección.
  static const String coleccion = 'peliculas';

  /// La colección con su convertidor: lee y escribe objetos [Pelicula] en vez
  /// de mapas.
  CollectionReference<Pelicula> get peliculas => firestore
      .collection(coleccion)
      .withConverter<Pelicula>(
        fromFirestore: Pelicula.fromFirestore,
        toFirestore: (pelicula, _) => pelicula.toFirestore(),
      );

  /// Las películas ordenadas por título. El Stream manda una lista nueva cada
  /// vez que la colección cambia, también cuando la app agrega una.
  Stream<List<Pelicula>> escuchar() => peliculas
      .orderBy('titulo')
      .snapshots()
      .map(
        (consulta) => [for (final documento in consulta.docs) documento.data()],
      );

  /// Guarda una película nueva. Firestore le asigna el id del documento.
  Future<DocumentReference<Pelicula>> agregar(Pelicula pelicula) =>
      peliculas.add(pelicula);
}
