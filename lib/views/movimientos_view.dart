import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'movimiento_form_view.dart';

class MovimientosView extends StatefulWidget {
  const MovimientosView({super.key});

  @override
  State<MovimientosView> createState() => _MovimientosViewState();
}

class _MovimientosViewState extends State<MovimientosView> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final TextEditingController _busquedaCtrl = TextEditingController();

  bool _cargando = true;
  int _usuarioId = 1;
  String _tipoSeleccionado = 'todos';
  String _categoriaSeleccionada = 'todos';
  DateTime _mesSeleccionado = DateTime.now();

  List<Movimiento> _movimientos = [];
  List<Map<String, dynamic>> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMovimientos() async {
    final usuario = await AuthService.instance.obtenerSesion();
    _usuarioId = usuario?.id ?? 1;
    _categorias = _databaseService.obtenerCategorias();
    await _actualizarLista();
  }

  Future<void> _actualizarLista() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
    });

    final tipo = _tipoSeleccionado == 'todos' ? null : _tipoSeleccionado;
    final categoria = _categoriaSeleccionada == 'todos'
        ? null
        : _categoriasFiltradas
            .firstWhere((item) => item['valor'] == _categoriaSeleccionada,
                orElse: () => {})
            ['nombre'] as String?;
    final busqueda = _busquedaCtrl.text.trim().isEmpty
        ? null
        : _busquedaCtrl.text.trim();

    _movimientos = await _databaseService.obtenerMovimientosUsuario(
      _usuarioId,
      tipo: tipo,
      categoria: categoria,
      mes: _mesSeleccionado,
      busqueda: busqueda,
    );

    if (!mounted) return;
    setState(() {
      _cargando = false;
    });
  }

  List<Map<String, dynamic>> get _categoriasFiltradas {
    final categorias = _categorias
        .where((categoria) =>
            _tipoSeleccionado == 'todos' ||
            categoria['tipo'] == _tipoSeleccionado)
        .map((categoria) => {
              'valor': '${categoria['tipo']}:${categoria['nombre']}',
              'nombre': categoria['nombre'],
              'tipo': categoria['tipo'],
            })
        .toList();
    return [
      {'valor': 'todos', 'nombre': 'Todos', 'tipo': 'todos'},
      ...categorias,
    ];
  }

  double get _totalIngresos {
    return _movimientos
        .where((movimiento) => movimiento.esIngreso)
        .fold(0.0, (total, movimiento) => total + movimiento.monto);
  }

  double get _totalGastos {
    return _movimientos
        .where((movimiento) => movimiento.esGasto)
        .fold(0.0, (total, movimiento) => total + movimiento.monto);
  }

  Future<void> _seleccionarMes(int cantidad) async {
    final nuevoMes = DateTime(
      _mesSeleccionado.year,
      _mesSeleccionado.month + cantidad,
    );
    setState(() {
      _mesSeleccionado = nuevoMes;
    });
    await _actualizarLista();
  }

  Future<void> _abrirFormulario([Movimiento? movimiento]) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MovimientoFormView(
          usuarioId: _usuarioId,
          movimiento: movimiento,
        ),
      ),
    );

    if (resultado == true) {
      await _actualizarLista();
    }
  }

  Future<void> _confirmarEliminar(Movimiento movimiento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Estás seguro de eliminar este movimiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await _databaseService.eliminarMovimiento(movimiento.id!);
    await _actualizarLista();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Movimiento eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoMes = DateFormat('MMMM yyyy', 'es_DO').format(_mesSeleccionado);
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Ingresos y Gastos'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _actualizarLista,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ingresos'),
                            const SizedBox(height: 8),
                            Text(
                              'RD\$ ${_totalIngresos.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gastos'),
                            const SizedBox(height: 8),
                            Text(
                              'RD\$ ${_totalGastos.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: _tipoSeleccionado == 'todos',
                      onSelected: (_) async {
                        setState(() {
                          _tipoSeleccionado = 'todos';
                          _categoriaSeleccionada = 'todos';
                        });
                        await _actualizarLista();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Ingresos'),
                      selected: _tipoSeleccionado == 'ingreso',
                      onSelected: (_) async {
                        setState(() {
                          _tipoSeleccionado = 'ingreso';
                          _categoriaSeleccionada = 'todos';
                        });
                        await _actualizarLista();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Gastos'),
                      selected: _tipoSeleccionado == 'gasto',
                      onSelected: (_) async {
                        setState(() {
                          _tipoSeleccionado = 'gasto';
                          _categoriaSeleccionada = 'todos';
                        });
                        await _actualizarLista();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey(_categoriaSeleccionada),
                      initialValue: _categoriaSeleccionada,
                      items: _categoriasFiltradas
                          .map(
                            (categoria) => DropdownMenuItem<String>(
                              value: categoria['valor'] as String,
                              child: Text(categoria['nombre'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                        await _actualizarLista();
                      },
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _seleccionarMes(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatoMes,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _seleccionarMes(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _busquedaCtrl,
                onSubmitted: (_) => _actualizarLista(),
                decoration: InputDecoration(
                  hintText: 'Buscar por descripción o categoría',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () async {
                      _busquedaCtrl.clear();
                      setState(() {});
                      await _actualizarLista();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _movimientos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.sentiment_dissatisfied,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No hay movimientos registrados para este mes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _movimientos.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final movimiento = _movimientos[index];
                              final ingreso = movimiento.esIngreso;
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: ingreso
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    child: Icon(
                                      ingreso ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: ingreso ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    movimiento.descripcion.isEmpty
                                        ? movimiento.categoria
                                        : movimiento.descripcion,
                                  ),
                                  subtitle: Text(
                                    '${movimiento.categoria} • ${formatoFecha.format(movimiento.fecha)}',
                                  ),
                                  trailing: SizedBox(
                                    width: 110,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'RD\$ ${movimiento.monto.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: ingreso ? Colors.green : Colors.red,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              ingreso ? 'Ingreso' : 'Gasto',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'editar') {
                                              _abrirFormulario(movimiento);
                                            } else if (value == 'eliminar') {
                                              _confirmarEliminar(movimiento);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'editar',
                                              child: Text('Editar'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'eliminar',
                                              child: Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo movimiento'),
      ),
    );
  }
}
