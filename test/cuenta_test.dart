// Pruebas del registro y del ingreso con Firebase Authentication simulado
// (firebase_auth_mocks): los avisos del formulario, la cuenta nueva con su
// registro en `usuarios`, y el ingreso correcto y el equivocado.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import 'datos_de_prueba.dart';

Future<void> llenar(WidgetTester tester, String llave, String texto) async {
  // El campo tiene que estar a la vista para recibir el foco.
  await tester.ensureVisible(find.byKey(Key(llave)));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(Key(llave)), texto);
}

void main() {
  setUpAll(FakeFirebaseFirestore.new);

  testWidgets('El registro dice qué falta y revisa el correo y la contraseña', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester, await serviciosDePrueba(conSesion: false));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('crear')));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu nombre'), findsOneWidget);
    expect(find.text('Escribe tu correo'), findsOneWidget);
    expect(find.text('Usa al menos 6 caracteres'), findsOneWidget);

    await llenar(tester, 'nombre', 'Luis');
    await llenar(tester, 'correo', 'luis@');
    await llenar(tester, 'contrasena', 'secreta1');
    await llenar(tester, 'confirmacion', 'secreta2');
    await tester.tap(find.byKey(const Key('crear')));
    await tester.pumpAndSettle();
    expect(find.text('Ese correo no es válido'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets(
    'Al registrarse se abre la sesión, se ve el catálogo y el usuario '
    'queda en la colección usuarios',
    (WidgetTester tester) async {
      final auth = MockFirebaseAuth();
      final firestore = FakeFirebaseFirestore();
      await abrirApp(
        tester,
        await serviciosDePrueba(
          conSesion: false,
          auth: auth,
          firestore: firestore,
        ),
      );
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      await llenar(tester, 'nombre', 'Luis Pérez');
      await llenar(tester, 'correo', 'luis@ejemplo.com');
      await llenar(tester, 'contrasena', 'secreta1');
      await llenar(tester, 'confirmacion', 'secreta1');
      await tester.tap(find.byKey(const Key('crear')));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Películas disponibles'), findsOneWidget);
      expect(auth.currentUser!.displayName, 'Luis Pérez');
      final usuarios = await firestore.collection('usuarios').get();
      expect(usuarios.docs, hasLength(1));
      final registro = usuarios.docs.single;
      expect(registro.id, auth.currentUser!.uid);
      expect(registro.data()['nombre'], 'Luis Pérez');
      expect(registro.data()['correo'], 'luis@ejemplo.com');
      expect(registro.data()['creado'], isA<Timestamp>());
    },
  );

  testWidgets('Ingresar con una contraseña equivocada muestra el aviso', (
    WidgetTester tester,
  ) async {
    final auth = MockFirebaseAuth(mockUser: usuarioDePrueba);
    whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
        .on(auth)
        .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    await abrirApp(
      tester,
      await serviciosDePrueba(conSesion: false, auth: auth),
    );
    await tester.tap(find.text('Ya tengo cuenta'));
    await tester.pumpAndSettle();

    await llenar(tester, 'correo', 'ana@ejemplo.com');
    await llenar(tester, 'contrasena', 'equivocada');
    await tester.tap(find.byKey(const Key('ingresar')));
    await tester.pumpAndSettle();

    expect(
      find.text('El correo o la contraseña no coinciden.'),
      findsOneWidget,
    );
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('Ingresar con la cuenta abre el catálogo', (
    WidgetTester tester,
  ) async {
    await abrirApp(
      tester,
      await serviciosDePrueba(
        conSesion: false,
        auth: MockFirebaseAuth(mockUser: usuarioDePrueba),
      ),
    );
    await tester.tap(find.text('Ya tengo cuenta'));
    await tester.pumpAndSettle();

    await llenar(tester, 'correo', 'ana@ejemplo.com');
    await llenar(tester, 'contrasena', 'secreta1');
    await tester.tap(find.byKey(const Key('ingresar')));
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('4 títulos'), findsOneWidget);
  });
}
