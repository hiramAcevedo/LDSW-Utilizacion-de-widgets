import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'repositorio_peliculas.dart';

/// Arranca Firebase con la configuración que generó `flutterfire configure`
/// y, después, la app con la base real de Cloud Firestore.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp(repositorio: RepositorioPeliculas(FirebaseFirestore.instance)));
}
