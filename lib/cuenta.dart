import 'package:material_ui/material_ui.dart';

import 'servicios.dart';
import 'sesion.dart';

/// Registrarse como usuario nuevo: nombre, correo y contraseña. La cuenta se
/// crea en Firebase Authentication y su registro en la colección `usuarios`.
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key, required this.servicios});

  final Servicios servicios;

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await widget.servicios.sesion.registrar(
        nombre: _nombre.text,
        correo: _correo.text,
        contrasena: _contrasena.text,
      );
      // Con la sesión abierta, la puerta ya muestra el catálogo debajo.
      if (mounted) Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = mensajeDeError(error));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaDeCuenta(
      titulo: 'Crear cuenta',
      explicacion:
          'Tu cuenta es tu correo con una contraseña. Con ella entras al '
          'catálogo desde cualquier teléfono.',
      formulario: _formulario,
      error: _error,
      campos: [
        TextFormField(
          key: const Key('nombre'),
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (valor) =>
              (valor ?? '').trim().isEmpty ? 'Escribe tu nombre' : null,
        ),
        CampoDeCorreo(controlador: _correo),
        CampoDeContrasena(
          llave: const Key('contrasena'),
          controlador: _contrasena,
          etiqueta: 'Contraseña',
          ayuda: 'Al menos 6 caracteres',
          accion: TextInputAction.next,
          validar: (valor) =>
              (valor ?? '').length < 6 ? 'Usa al menos 6 caracteres' : null,
        ),
        CampoDeContrasena(
          llave: const Key('confirmacion'),
          controlador: _confirmacion,
          etiqueta: 'Repite la contraseña',
          accion: TextInputAction.done,
          alEnviar: _crear,
          validar: (valor) =>
              valor != _contrasena.text ? 'Las contraseñas no coinciden' : null,
        ),
      ],
      boton: FilledButton.icon(
        key: const Key('crear'),
        onPressed: _enviando ? null : _crear,
        icon: _enviando
            ? const IndicadorChico()
            : const Icon(Icons.person_add_alt_1),
        label: Text(_enviando ? 'Creando la cuenta…' : 'Crear cuenta'),
      ),
      otraOpcion: TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => IngresoPage(servicios: widget.servicios),
          ),
        ),
        child: const Text('Ya tengo cuenta: ingresar'),
      ),
    );
  }
}

/// Ingresar con una cuenta que ya existe: correo y contraseña.
class IngresoPage extends StatefulWidget {
  const IngresoPage({super.key, required this.servicios});

  final Servicios servicios;

  @override
  State<IngresoPage> createState() => _IngresoPageState();
}

class _IngresoPageState extends State<IngresoPage> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await widget.servicios.sesion.ingresar(
        correo: _correo.text,
        contrasena: _contrasena.text,
      );
      if (mounted) Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = mensajeDeError(error));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaDeCuenta(
      titulo: 'Ingresar',
      explicacion: 'Entra con el correo y la contraseña de tu cuenta.',
      formulario: _formulario,
      error: _error,
      campos: [
        CampoDeCorreo(controlador: _correo),
        CampoDeContrasena(
          llave: const Key('contrasena'),
          controlador: _contrasena,
          etiqueta: 'Contraseña',
          accion: TextInputAction.done,
          alEnviar: _ingresar,
          validar: (valor) =>
              (valor ?? '').isEmpty ? 'Escribe tu contraseña' : null,
        ),
      ],
      boton: FilledButton.icon(
        key: const Key('ingresar'),
        onPressed: _enviando ? null : _ingresar,
        icon: _enviando ? const IndicadorChico() : const Icon(Icons.login),
        label: Text(_enviando ? 'Ingresando…' : 'Ingresar'),
      ),
      otraOpcion: TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RegistroPage(servicios: widget.servicios),
          ),
        ),
        child: const Text('¿No tienes cuenta? Crear una'),
      ),
    );
  }
}

/// El armazón de las dos pantallas de la cuenta: la explicación, los campos,
/// el error si lo hubo, el botón y el enlace a la otra pantalla.
class PantallaDeCuenta extends StatelessWidget {
  const PantallaDeCuenta({
    super.key,
    required this.titulo,
    required this.explicacion,
    required this.formulario,
    required this.campos,
    required this.boton,
    required this.otraOpcion,
    this.error,
  });

  final String titulo;
  final String explicacion;
  final GlobalKey<FormState> formulario;
  final List<Widget> campos;
  final Widget boton;
  final Widget otraOpcion;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.inversePrimary,
        title: Text(titulo),
      ),
      body: SafeArea(
        child: Form(
          key: formulario,
          child: AutofillGroup(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    explicacion,
                    style: tema.textTheme.bodyLarge?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final campo in campos) ...[
                    campo,
                    const SizedBox(height: 16),
                  ],
                  if (error != null) ...[
                    Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: tema.colorScheme.error,
                        ),
                        Expanded(
                          child: Text(
                            error!,
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: tema.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  boton,
                  const SizedBox(height: 8),
                  otraOpcion,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El campo del correo, con su teclado y su validación.
class CampoDeCorreo extends StatelessWidget {
  const CampoDeCorreo({super.key, required this.controlador});

  final TextEditingController controlador;

  static final RegExp _formato = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('correo'),
      controller: controlador,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(
        labelText: 'Correo',
        prefixIcon: Icon(Icons.mail_outline),
      ),
      validator: (valor) {
        final correo = (valor ?? '').trim();
        if (correo.isEmpty) return 'Escribe tu correo';
        if (!_formato.hasMatch(correo)) return 'Ese correo no es válido';
        return null;
      },
    );
  }
}

/// Un campo de contraseña con el botón para mostrarla u ocultarla.
class CampoDeContrasena extends StatefulWidget {
  const CampoDeContrasena({
    super.key,
    required this.llave,
    required this.controlador,
    required this.etiqueta,
    required this.validar,
    this.ayuda,
    this.accion = TextInputAction.done,
    this.alEnviar,
  });

  final Key llave;
  final TextEditingController controlador;
  final String etiqueta;
  final String? ayuda;
  final FormFieldValidator<String> validar;
  final TextInputAction accion;
  final VoidCallback? alEnviar;

  @override
  State<CampoDeContrasena> createState() => _CampoDeContrasenaState();
}

class _CampoDeContrasenaState extends State<CampoDeContrasena> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.llave,
      controller: widget.controlador,
      obscureText: _oculta,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.accion,
      onFieldSubmitted: (_) => widget.alEnviar?.call(),
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        helperText: widget.ayuda,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _oculta ? 'Mostrar' : 'Ocultar',
          onPressed: () => setState(() => _oculta = !_oculta),
          icon: Icon(_oculta ? Icons.visibility : Icons.visibility_off),
        ),
      ),
      validator: widget.validar,
    );
  }
}

/// El círculo de carga del tamaño de un icono, para los botones.
class IndicadorChico extends StatelessWidget {
  const IndicadorChico({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
