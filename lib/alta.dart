import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'catalogo.dart';
import 'cuenta.dart';
import 'pelicula.dart';
import 'poster.dart';
import 'servicios.dart';
import 'sesion.dart';
import 'tmdb.dart';

/// Dar de alta una película: título, año, director, género, sinopsis y URL
/// de la imagen. La búsqueda de arriba pide a TMDB las películas con ese
/// título y, al elegir una, llena el formulario con su ficha; todo se puede
/// corregir antes de guardar. Guardar crea el documento en `catalogo`.
class AltaPage extends StatefulWidget {
  const AltaPage({super.key, required this.servicios, required this.uid});

  final Servicios servicios;

  /// El uid de quien da de alta la película.
  final String uid;

  /// El primer año que acepta el formulario: el de la película más antigua
  /// que se conserva.
  static const int primerAnio = 1888;

  @override
  State<AltaPage> createState() => _AltaPageState();
}

class _AltaPageState extends State<AltaPage> {
  final _formulario = GlobalKey<FormState>();
  final _busqueda = TextEditingController();
  final _titulo = TextEditingController();
  final _anio = TextEditingController();
  final _director = TextEditingController();
  final _genero = TextEditingController();
  final _sinopsis = TextEditingController();
  final _imagen = TextEditingController();
  final int _ultimoAnio = DateTime.now().year + 1;

  int? _tmdbId;
  List<ResultadoTmdb>? _resultados;
  bool _buscando = false;
  bool _guardando = false;
  String? _errorDeBusqueda;

  Tmdb get _tmdb => widget.servicios.tmdb;

  @override
  void dispose() {
    for (final controlador in [
      _busqueda,
      _titulo,
      _anio,
      _director,
      _genero,
      _sinopsis,
      _imagen,
    ]) {
      controlador.dispose();
    }
    super.dispose();
  }

  Future<void> _buscar() async {
    final texto = _busqueda.text.trim();
    if (texto.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _buscando = true;
      _errorDeBusqueda = null;
    });
    try {
      final resultados = await _tmdb.buscar(texto);
      if (mounted) setState(() => _resultados = resultados);
    } on TmdbException catch (error) {
      if (mounted) setState(() => _errorDeBusqueda = error.mensaje);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _elegir(ResultadoTmdb resultado) async {
    setState(() {
      _buscando = true;
      _errorDeBusqueda = null;
    });
    try {
      final ficha = await _tmdb.ficha(resultado.id);
      if (!mounted) return;
      setState(() {
        _tmdbId = ficha.id;
        _titulo.text = ficha.titulo;
        _anio.text = ficha.anio?.toString() ?? '';
        _director.text = ficha.director;
        _genero.text = ficha.genero;
        _sinopsis.text = ficha.sinopsis;
        _imagen.text = ficha.imagen;
        _resultados = null;
      });
      // Lo que TMDB no trajo queda marcado para llenarlo a mano.
      _formulario.currentState!.validate();
    } on TmdbException catch (error) {
      if (mounted) setState(() => _errorDeBusqueda = error.mensaje);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Pelicula get _borrador => Pelicula(
    titulo: _titulo.text.trim().isEmpty ? 'Título' : _titulo.text.trim(),
    anio: int.tryParse(_anio.text) ?? DateTime.now().year,
    director: _director.text.trim(),
    genero: _genero.text.trim(),
    sinopsis: _sinopsis.text.trim(),
    imagen: _imagen.text.trim(),
    tmdbId: _tmdbId,
  );

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    final catalogo = widget.servicios.catalogo;
    try {
      final tmdbId = _tmdbId;
      if (tmdbId != null && await catalogo.yaEsta(tmdbId)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_titulo.text.trim()} ya está en el catálogo.'),
          ),
        );
        return;
      }
      final pelicula = _borrador;
      await catalogo.darDeAlta(pelicula, uid: widget.uid);
      if (mounted) Navigator.of(context).pop(pelicula);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo dar de alta: ${mensajeDeError(error)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _obligatorio(String? valor, String mensaje) =>
      (valor ?? '').trim().isEmpty ? mensaje : null;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    const anchoDeVistaPrevia = 150.0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.inversePrimary,
        title: const Text('Dar de alta una película'),
      ),
      body: Form(
        key: _formulario,
        // Una Column dentro de un SingleChildScrollView, no un ListView: así
        // todos los campos existen siempre y la validación los revisa todos,
        // aunque estén fuera de la pantalla.
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Buscar en TMDB', style: tema.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (!_tmdb.configurado)
                Text(
                  'La búsqueda necesita el token de TMDB (README, sección TMDB). '
                  'Mientras tanto, los datos se llenan a mano.',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('busqueda'),
                        controller: _busqueda,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscar(),
                        decoration: const InputDecoration(
                          hintText: 'Título de la película',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      key: const Key('buscar'),
                      tooltip: 'Buscar',
                      onPressed: _buscando ? null : _buscar,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                if (_buscando) const LinearProgressIndicator(),
                if (_errorDeBusqueda != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _errorDeBusqueda!,
                      style: TextStyle(color: tema.colorScheme.error),
                    ),
                  ),
                if (_resultados case final resultados?) ...[
                  const SizedBox(height: 8),
                  if (resultados.isEmpty)
                    const Text('TMDB no encontró películas con ese título.')
                  else
                    for (final resultado in resultados.take(8))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 40,
                          height: 60,
                          child: Poster(
                            url: resultado.miniatura ?? '',
                            color: tema.colorScheme.outlineVariant,
                            radio: 4,
                            tamanoDeIcono: 20,
                          ),
                        ),
                        title: Text(resultado.titulo),
                        subtitle: Text(
                          resultado.anio?.toString() ?? 'Sin fecha de estreno',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _buscando ? null : () => _elegir(resultado),
                      ),
                ],
              ],
              const SizedBox(height: 8),
              const AtribucionTmdb(),
              const Divider(height: 32),
              Text('Datos de la película', style: tema.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('titulo'),
                controller: _titulo,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (valor) => _obligatorio(valor, 'Escribe el título'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('anio'),
                controller: _anio,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Año de estreno',
                  helperText: 'De ${AltaPage.primerAnio} a $_ultimoAnio',
                ),
                validator: (valor) {
                  final anio = int.tryParse(valor ?? '');
                  if (anio == null) return 'Escribe el año de estreno';
                  if (anio < AltaPage.primerAnio || anio > _ultimoAnio) {
                    return 'Escribe un año de ${AltaPage.primerAnio} a $_ultimoAnio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('director'),
                controller: _director,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Director'),
                validator: (valor) =>
                    _obligatorio(valor, 'Escribe quién la dirigió'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('genero'),
                controller: _genero,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  helperText: 'Por ejemplo: Drama, o Drama, Fantasía',
                ),
                validator: (valor) => _obligatorio(valor, 'Escribe el género'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('sinopsis'),
                controller: _sinopsis,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Sinopsis',
                  alignLabelWithHint: true,
                ),
                validator: (valor) {
                  final texto = (valor ?? '').trim();
                  if (texto.isEmpty) return 'Escribe la sinopsis';
                  if (texto.length > 3000) {
                    return 'La sinopsis pasa de 3,000 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('imagen'),
                controller: _imagen,
                keyboardType: TextInputType.url,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'URL de la imagen',
                  helperText: 'La dirección del póster, con https://',
                ),
                validator: (valor) {
                  final url = (valor ?? '').trim();
                  if (url.isEmpty) return 'Escribe la URL de la imagen';
                  final direccion = Uri.tryParse(url);
                  final esWeb =
                      direccion != null &&
                      (direccion.isScheme('https') ||
                          direccion.isScheme('http'));
                  if (!esWeb || direccion.host.isEmpty) {
                    return 'La URL debe empezar con https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Así se verá en el catálogo',
                style: tema.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: anchoDeVistaPrevia,
                  child: IgnorePointer(
                    child: TarjetaDePoster(pelicula: _borrador),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('guardar'),
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const IndicadorChico()
                    : const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando…' : 'Dar de alta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El crédito de TMDB junto a la búsqueda: de dónde salen los datos y las
/// imágenes, y el aviso que piden sus condiciones de uso.
class AtribucionTmdb extends StatelessWidget {
  const AtribucionTmdb({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tenue = tema.textTheme.labelSmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text('Datos e imágenes de TMDB (themoviedb.org).', style: tenue),
        Text(
          Tmdb.atribucion,
          style: tenue?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
