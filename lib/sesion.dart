import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// El registro y el ingreso de los usuarios con Firebase Authentication, con
/// correo y contraseña. Al registrarse, el usuario queda también en la
/// colección `usuarios` de Firestore, con su nombre, su correo y la fecha.
class Sesion {
  Sesion({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  static const String coleccionDeUsuarios = 'usuarios';

  /// El usuario con la sesión abierta, o null sin sesión. Avisa también
  /// cuando cambia su nombre.
  Stream<User?> get cambios => auth.userChanges();

  /// El usuario con la sesión abierta en este momento.
  User? get actual => auth.currentUser;

  /// Crea la cuenta, le pone el nombre y guarda su registro en `usuarios`.
  /// Al terminar, la sesión queda abierta.
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final credencial = await auth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );
    final usuario = credencial.user!;
    await usuario.updateDisplayName(nombre.trim());
    await firestore.collection(coleccionDeUsuarios).doc(usuario.uid).set({
      'nombre': nombre.trim(),
      'correo': usuario.email,
      'creado': FieldValue.serverTimestamp(),
    });
  }

  /// Abre la sesión de una cuenta que ya existe.
  Future<void> ingresar({required String correo, required String contrasena}) =>
      auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );

  /// Cierra la sesión; la app vuelve a la pantalla de inicio.
  Future<void> salir() => auth.signOut();
}

/// El mensaje, en español, de un error de Firebase o de la red.
String mensajeDeError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'email-already-in-use' =>
        'Ese correo ya tiene una cuenta: ingresa con él.',
      'invalid-email' => 'Ese correo no es válido.',
      'weak-password' =>
        'La contraseña es muy débil: usa al menos 6 caracteres.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' => 'El correo o la contraseña no coinciden.',
      'user-disabled' => 'Esta cuenta está deshabilitada.',
      'too-many-requests' =>
        'Demasiados intentos seguidos. Espera unos minutos.',
      'network-request-failed' => 'Sin conexión a internet.',
      'operation-not-allowed' =>
        'El registro con correo no está activado en Firebase.',
      _ => 'No se pudo completar (${error.code}).',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'La base de datos no aceptó el cambio.',
      'unavailable' => 'La base de datos no responde: revisa tu conexión.',
      _ => 'No se pudo completar (${error.code}).',
    };
  }
  return 'No se pudo completar: $error';
}
