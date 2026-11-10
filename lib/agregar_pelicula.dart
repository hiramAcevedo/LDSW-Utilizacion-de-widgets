import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'catalogo.dart';
import 'pelicula.dart';
import 'repositorio_peliculas.dart';

/// El formulario para agregar una película: título, año, director, género y
/// color del póster. Valida los campos, guarda la película en Cloud Firestore
/// y regresa al catálogo con la película guardada.
class AgregarPeliculaPage extends StatefulWidget {
  const AgregarPeliculaPage({super.key, required this.repositorio});

  final RepositorioPeliculas repositorio;

  /// El primer año que acepta: 1888, el de la película más antigua que se
  /// conserva.
  static const int primerAnio = 1888;

  @override
  State<AgregarPeliculaPage> createState() => _AgregarPeliculaPageState();
}

class _AgregarPeliculaPageState extends State<AgregarPeliculaPage> {
  final _formulario = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _anio = TextEditingController();
  final _director = TextEditingController();
  String? _genero;
  Color _color = coloresDePoster.first;
  bool _guardando = false;

  /// El último año que acepta: el que entra, por los estrenos ya anunciados.
  int get _ultimoAnio => DateTime.now().year + 1;

  @override
  void dispose() {
    _titulo.dispose();
    _anio.dispose();
    _director.dispose();
    super.dispose();
  }

  /// La película con lo que lleva escrito el formulario, para la vista previa.
  Pelicula get _borrador => Pelicula(
    titulo: _titulo.text.trim().isEmpty ? 'Título' : _titulo.text.trim(),
    anio: int.tryParse(_anio.text) ?? DateTime.now().year,
    director: _director.text.trim().isEmpty
        ? 'Director'
        : _director.text.trim(),
    genero: _genero ?? 'Género',
    color: _color,
  );

  String? _validarAnio(String? texto) {
    final anio = int.tryParse(texto ?? '');
    if (anio == null) return 'Escribe el año de estreno';
    if (anio < AgregarPeliculaPage.primerAnio || anio > _ultimoAnio) {
      return 'Escribe un año de ${AgregarPeliculaPage.primerAnio} a $_ultimoAnio';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    final pelicula = Pelicula(
      titulo: _titulo.text.trim(),
      anio: int.parse(_anio.text),
      director: _director.text.trim(),
      genero: _genero!,
      color: _color,
    );
    try {
      // add termina cuando el servidor de Firestore confirma la escritura.
      await widget.repositorio.agregar(pelicula);
      if (mounted) Navigator.of(context).pop(pelicula);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la película: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.inversePrimary,
        title: const Text('Agregar película'),
      ),
      body: Form(
        key: _formulario,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              TextFormField(
                key: const ValueKey('titulo'),
                controller: _titulo,
                enabled: !_guardando,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: (texto) =>
                    (texto ?? '').trim().isEmpty ? 'Escribe el título' : null,
              ),
              TextFormField(
                key: const ValueKey('anio'),
                controller: _anio,
                enabled: !_guardando,
                decoration: InputDecoration(
                  labelText: 'Año de estreno',
                  helperText:
                      'De ${AgregarPeliculaPage.primerAnio} a $_ultimoAnio',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: _validarAnio,
              ),
              TextFormField(
                key: const ValueKey('director'),
                controller: _director,
                enabled: !_guardando,
                decoration: const InputDecoration(
                  labelText: 'Director',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                validator: (texto) => (texto ?? '').trim().isEmpty
                    ? 'Escribe quién la dirigió'
                    : null,
              ),
              DropdownButtonFormField<String>(
                key: const ValueKey('genero'),
                initialValue: _genero,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final genero in generos)
                    DropdownMenuItem(value: genero, child: Text(genero)),
                ],
                onChanged: _guardando
                    ? null
                    : (genero) => setState(() => _genero = genero),
                validator: (genero) =>
                    genero == null ? 'Elige el género' : null,
              ),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Color del póster',
                  border: OutlineInputBorder(),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (i, color) in coloresDePoster.indexed)
                      MuestraDeColor(
                        key: ValueKey('color-$i'),
                        color: color,
                        numero: i + 1,
                        elegido: color == _color,
                        alTocar: _guardando
                            ? null
                            : () => setState(() => _color = color),
                      ),
                  ],
                ),
              ),
              Text(
                'Así se verá en el catálogo',
                style: tema.textTheme.titleSmall,
              ),
              // La misma tarjeta del catálogo, sin el margen de la lista.
              TarjetaPelicula(pelicula: _borrador, margin: EdgeInsets.zero),
              FilledButton.icon(
                key: const ValueKey('guardar'),
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando…' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un círculo de color para elegir el póster; el elegido lleva una palomita.
class MuestraDeColor extends StatelessWidget {
  const MuestraDeColor({
    super.key,
    required this.color,
    required this.numero,
    required this.elegido,
    required this.alTocar,
  });

  final Color color;
  final int numero;
  final bool elegido;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: 'Color $numero',
      child: InkWell(
        onTap: alTocar,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: elegido
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: elegido
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}
