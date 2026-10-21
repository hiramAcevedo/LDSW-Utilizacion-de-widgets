# Catálogo de películas

Hiram Agustín Acevedo López · Licenciatura en Desarrollo de Sistemas Web

Aplicación en Flutter del catálogo de películas que vengo desarrollando en la unidad 3 de Diseño de aplicaciones móviles. Parte del Hello World de la actividad 3.3 (https://github.com/hiramAcevedo/ih732_hello_world) y sigue el wireframe de la actividad 3.2. Cada actividad queda fija en una etiqueta del repositorio:

| Etiqueta | Actividad | Qué añade |
|---|---|---|
| `act-3.4` | 3.4. Utilización de widgets | la pantalla del catálogo, con Text, Row, Column, Stack y Container |
| `act-3.5` | 3.5. Home screen | la pantalla de inicio, con la imagen de fondo, el icono y el mensaje Hello World |

<p>
<img src="docs/inicio.png" width="300" alt="La pantalla de inicio en el emulador Pixel 9: la imagen de fondo, el icono de película, el nombre Catálogo de películas, el texto Hello World y el botón Ver el catálogo">
<img src="docs/catalogo.png" width="300" alt="La pantalla del catálogo en el emulador Pixel 9: la barra Catálogo de películas y cuatro tarjetas, cada una con el póster, el año, el título, el director y el género">
</p>

## Pantalla de inicio (actividad 3.5)

Está en `lib/inicio.dart` y es la pantalla con la que arranca la app. La armé con los pasos de Layouts in Flutter (docs.flutter.dev/ui/layout): elegir el widget de layout, crear los widgets visibles, meterlos en el layout y poner el layout en la página.

| Widget | Dónde | Qué configuré |
|---|---|---|
| `Image` | la base del `Stack`: la imagen de fondo, `assets/images/fondo_inicio.jpg` | `Image.asset` con `fit: BoxFit.cover`, para que cubra toda la pantalla; el archivo está declarado en `assets` de `pubspec.yaml` |
| `Icon` | arriba del nombre de la app | `Icons.local_movies`, `size`, `color` |
| `Text` | el nombre de la app y el mensaje de bienvenida, Hello World | `style` del tema (`headlineMedium` en negritas y `titleLarge`), `textAlign` |
| `Stack` | el layout de la pantalla: la imagen debajo, un velo con degradado y el contenido encima | `fit: StackFit.expand` |
| `Center` y `Column` | el contenido centrado: icono, nombre, bienvenida y botón, uno debajo de otro | `mainAxisSize`, `spacing` |

El botón Ver el catálogo abre la pantalla del catálogo con `Navigator.push`. El registro y el ingreso del wireframe llegan en las actividades siguientes.

La imagen de fondo es un diseño propio hecho para esta app (un degradado morado con luces desenfocadas y una tira de película), sin derechos de terceros.

## Pantalla del catálogo (actividad 3.4)

Está en `lib/catalogo.dart`. Es una lista de tarjetas, una por película, y cada tarjeta repite la misma composición.

| Widget | Dónde | Qué configuré |
|---|---|---|
| `Column` | el cuerpo de la pantalla (encabezado y tarjetas) y los datos de cada tarjeta | `crossAxisAlignment`, `mainAxisSize`, `spacing` |
| `Row` | cada tarjeta (póster a la izquierda, datos a la derecha), el encabezado y la línea del género | `mainAxisAlignment`, `crossAxisAlignment`, `textBaseline`, `spacing`, un hijo `Expanded` |
| `Stack` | el póster: el bloque de color debajo y, encima, el año en la esquina inferior derecha | `alignment`, `clipBehavior`, un hijo `Positioned` |
| `Container` | la tarjeta, el póster y la etiqueta del año | `margin`, `padding`, `width`, `height`, `alignment`, `decoration` (color, `borderRadius`, `boxShadow`) |
| `Text` | el nombre de la app, el encabezado, el título, el director, el género y el año | `style` del tema, `maxLines`, `overflow` |

Las películas están en `lib/pelicula.dart`. Son contenido de ejemplo mientras el catálogo no se conecta a un servicio. El nombre de la app está en `lib/constantes.dart` y `lib/main.dart` arma el `MaterialApp`.

## Abrir el proyecto

1. Clona el repositorio.
2. Con Flutter 3.47.5 instalado, entra a la carpeta y corre `flutter pub get`.
3. Enciende un emulador de Android (o conecta un teléfono) y corre `flutter run`. También corre en el navegador con `flutter run -d chrome`.

## Pruebas

`flutter test` corre once pruebas de widget. Las cinco de `test/inicio_test.dart` comprueban la pantalla de inicio: que muestra el nombre, Hello World y el icono; que la `Image` es la base del `Stack`, es el asset declarado y mide lo mismo que la pantalla; que el `Icon` va en blanco sobre la imagen y arriba del nombre; que los cuatro elementos bajan centrados y en orden; y que el botón abre el catálogo. Las seis de `test/catalogo_test.dart` son las de la actividad 3.4, una por widget.

Hecho con Flutter 3.47.5 (Dart 3.13.4). Probado en el emulador Pixel 9 con Android 16 y en Chrome.
