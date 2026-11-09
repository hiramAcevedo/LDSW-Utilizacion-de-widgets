import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'pokeapi.dart';

/// La lista de la Pokédex: los 151 Pokémon de la primera generación en una
/// cuadrícula. Los datos llegan de PokéAPI con una sola petición HTTP, que se
/// lanza en initState y se muestra con un FutureBuilder, como en la receta
/// "Fetch data from the internet".
class PokedexPage extends StatefulWidget {
  const PokedexPage({super.key, this.cliente});

  /// El cliente HTTP. La app abre uno propio; las pruebas pasan uno simulado.
  final http.Client? cliente;

  @override
  State<PokedexPage> createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  late final http.Client _cliente;
  late Future<List<PokemonResumen>> _lista;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente ?? http.Client();
    _lista = obtenerLista(_cliente);
  }

  @override
  void dispose() {
    // Sólo se cierra el cliente que abrió esta pantalla.
    if (widget.cliente == null) _cliente.close();
    super.dispose();
  }

  void _reintentar() {
    setState(() {
      _lista = obtenerLista(_cliente);
    });
  }

  /// Abre el detalle del Pokémon de la posición [indice] de la lista.
  void _abrir(List<PokemonResumen> lista, int indice) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PokemonPage(pokedex: lista, indice: indice, cliente: _cliente),
      ),
    );
  }

  /// El buscador: pide un número y abre el detalle de ese Pokémon.
  Future<void> _buscar(List<PokemonResumen> lista) async {
    final numero = await showDialog<int>(
      context: context,
      builder: (_) => DialogoBuscarNumero(maximo: lista.length),
    );
    if (numero == null || !mounted) return;
    final indice = lista.indexWhere((p) => p.id == numero);
    if (indice >= 0) _abrir(lista, indice);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return FutureBuilder<List<PokemonResumen>>(
      future: _lista,
      builder: (context, snapshot) {
        final cargando = snapshot.connectionState != ConnectionState.done;
        // La lista, sólo cuando ya llegó: el buscador la necesita.
        final lista = cargando || snapshot.hasError ? null : snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pokédex'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Buscar por número',
                onPressed: lista == null ? null : () => _buscar(lista),
              ),
            ],
          ),
          body: _cuerpo(context, tema, snapshot, lista),
        );
      },
    );
  }

  Widget _cuerpo(
    BuildContext context,
    ThemeData tema,
    AsyncSnapshot<List<PokemonResumen>> snapshot,
    List<PokemonResumen>? cargada,
  ) {
    // Mientras llega la respuesta, también al reintentar.
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError || cargada == null) {
      return MensajeDeError(
        titulo: 'No se pudo cargar la Pokédex',
        error: snapshot.error,
        alReintentar: _reintentar,
      );
    }
    final lista = cargada;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Primera generación', style: tema.textTheme.titleMedium),
              Text(
                '${lista.length} Pokémon',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            // Abajo se suma la barra de navegación del sistema, para
            // que la última fila no quede debajo de ella.
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: lista.length,
            itemBuilder: (context, i) => TarjetaPokemon(
              pokemon: lista[i],
              alTocar: () => _abrir(lista, i),
            ),
          ),
        ),
      ],
    );
  }
}

/// El diálogo del buscador: pide un número con el teclado numérico y lo
/// devuelve sólo si está entre 1 y [maximo]; si no, avisa debajo del campo.
class DialogoBuscarNumero extends StatefulWidget {
  const DialogoBuscarNumero({super.key, required this.maximo});

  final int maximo;

  @override
  State<DialogoBuscarNumero> createState() => _DialogoBuscarNumeroState();
}

class _DialogoBuscarNumeroState extends State<DialogoBuscarNumero> {
  final _numero = TextEditingController();
  String? _aviso;

  @override
  void dispose() {
    _numero.dispose();
    super.dispose();
  }

  void _ver() {
    final numero = int.tryParse(_numero.text);
    if (numero == null || numero < 1 || numero > widget.maximo) {
      setState(() => _aviso = 'Escribe un número del 1 al ${widget.maximo}');
      return;
    }
    Navigator.of(context).pop(numero);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar por número'),
      content: TextField(
        controller: _numero,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _ver(),
        decoration: InputDecoration(
          labelText: 'Número en la Pokédex',
          hintText: 'Por ejemplo, 25',
          errorText: _aviso,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _ver, child: const Text('Ver')),
      ],
    );
  }
}

/// Una celda de la cuadrícula: la imagen, el número y el nombre. Al tocarla
/// se abre el detalle.
class TarjetaPokemon extends StatelessWidget {
  const TarjetaPokemon({
    super.key,
    required this.pokemon,
    required this.alTocar,
  });

  final PokemonResumen pokemon;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      color: tema.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            spacing: 2,
            children: [
              Expanded(
                child: Image.network(
                  pokemon.imagen,
                  fit: BoxFit.contain,
                  // La imagen de la lista es pixel art de 96 x 96: sin filtro
                  // se agranda nítida.
                  filterQuality: FilterQuality.none,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.catching_pokemon,
                    size: 40,
                    color: tema.colorScheme.outline,
                  ),
                ),
              ),
              Text(
                numeroVisible(pokemon.id),
                style: tema.textTheme.labelSmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                nombreVisible(pokemon.nombre),
                style: tema.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El detalle de un Pokémon, con su propia petición a PokéAPI. Los botones
/// Anterior y Siguiente piden el Pokémon de al lado sin volver a la lista.
class PokemonPage extends StatefulWidget {
  const PokemonPage({
    super.key,
    required this.pokedex,
    required this.indice,
    this.cliente,
  });

  /// La lista completa, en orden, y la posición del Pokémon que se abre.
  final List<PokemonResumen> pokedex;
  final int indice;
  final http.Client? cliente;

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  late final http.Client _cliente;
  late int _indice;
  late Future<Pokemon> _pokemon;

  PokemonResumen get _actual => widget.pokedex[_indice];

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente ?? http.Client();
    _indice = widget.indice;
    _pokemon = obtenerPokemon(_cliente, _actual.id);
  }

  @override
  void dispose() {
    if (widget.cliente == null) _cliente.close();
    super.dispose();
  }

  /// Pide y muestra el Pokémon de la posición [indice]. Con la posición
  /// actual, es el Reintentar.
  void _mostrar(int indice) {
    setState(() {
      _indice = indice;
      _pokemon = obtenerPokemon(_cliente, _actual.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hayAnterior = _indice > 0;
    final haySiguiente = _indice < widget.pokedex.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(nombreVisible(_actual.nombre))),
      body: FutureBuilder<Pokemon>(
        future: _pokemon,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MensajeDeError(
              titulo: 'No se pudo cargar este Pokémon',
              error: snapshot.error,
              alReintentar: () => _mostrar(_indice),
            );
          }
          final pokemon = snapshot.data!;
          // La llave nueva regresa el desplazamiento arriba en cada Pokémon.
          return DetallePokemon(key: ValueKey(pokemon.id), pokemon: pokemon);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  // Deshabilitado en el primero de la lista, el #001.
                  onPressed: hayAnterior ? () => _mostrar(_indice - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Anterior'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  // Deshabilitado en el último de la lista, el #151.
                  onPressed: haySiguiente ? () => _mostrar(_indice + 1) : null,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [Text('Siguiente'), Icon(Icons.chevron_right)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El gris muy claro de la pantalla de la imagen del detalle y su borde.
const Color _pantalla = Color(0xFFF1F1F1);
const Color _bordePantalla = Color(0xFFD6D6D6);

/// Lo que se ve del detalle: la imagen oficial, el nombre, los tipos, la
/// altura, el peso y las estadísticas base.
class DetallePokemon extends StatelessWidget {
  const DetallePokemon({super.key, required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final imagen = pokemon.imagen;
    return SingleChildScrollView(
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
          // La imagen, sobre un gris muy claro con borde, como la pantalla de
          // una Pokédex: ahí se ven igual los Pokémon rojos que los rosas.
          Container(
            height: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _pantalla,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _bordePantalla, width: 2),
            ),
            child: imagen == null
                ? const Icon(
                    Icons.catching_pokemon,
                    size: 96,
                    color: Colors.black26,
                  )
                : Image.network(
                    imagen,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.catching_pokemon,
                      size: 96,
                      color: Colors.black26,
                    ),
                  ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 8,
            children: [
              Flexible(
                child: Text(
                  nombreVisible(pokemon.nombre),
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                numeroVisible(pokemon.id),
                style: tema.textTheme.titleMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tipo in pokemon.tipos)
                Chip(label: Text(tiposEnEspanol[tipo] ?? tipo)),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: _Medida(
                  icono: Icons.height,
                  etiqueta: 'Altura',
                  valor: '${pokemon.alturaEnMetros.toStringAsFixed(1)} m',
                ),
              ),
              Expanded(
                child: _Medida(
                  icono: Icons.monitor_weight_outlined,
                  etiqueta: 'Peso',
                  valor: '${pokemon.pesoEnKilos.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
          Text('Estadísticas base', style: tema.textTheme.titleMedium),
          for (final estadistica in pokemon.estadisticas.entries)
            _BarraDeEstadistica(
              nombre: estadisticasEnEspanol[estadistica.key] ?? estadistica.key,
              valor: estadistica.value,
            ),
        ],
      ),
    );
  }
}

/// Una medida del detalle (altura o peso) en un recuadro.
class _Medida extends StatelessWidget {
  const _Medida({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 8,
        children: [
          Icon(icono, color: tema.colorScheme.primary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: tema.textTheme.labelMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(valor, style: tema.textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una estadística base: el nombre, el valor y una barra contra 255, el
/// máximo que puede tener una estadística base.
class _BarraDeEstadistica extends StatelessWidget {
  const _BarraDeEstadistica({required this.nombre, required this.valor});

  final String nombre;
  final int valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      spacing: 12,
      children: [
        SizedBox(
          width: 104,
          child: Text(nombre, style: tema.textTheme.bodyMedium),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$valor',
            textAlign: TextAlign.end,
            style: tema.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: valor / 255,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Lo que se ve cuando la petición falla: el motivo y un botón para volver a
/// pedir los datos.
class MensajeDeError extends StatelessWidget {
  const MensajeDeError({
    super.key,
    required this.titulo,
    required this.error,
    required this.alReintentar,
  });

  final String titulo;
  final Object? error;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final detalle = error is PokeApiException
        ? '$error Inténtalo de nuevo en un momento.'
        : 'Revisa la conexión a internet e inténtalo de nuevo.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(Icons.wifi_off, size: 56, color: tema.colorScheme.outline),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium,
            ),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            FilledButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
