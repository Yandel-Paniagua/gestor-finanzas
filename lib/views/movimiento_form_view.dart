import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento.dart';
import '../services/database_service.dart';

class MovimientoFormView extends StatefulWidget {
  final Movimiento? movimiento;
  final int usuarioId;

  const MovimientoFormView({
    super.key,
    this.movimiento,
    required this.usuarioId,
  });

  @override
  State<MovimientoFormView> createState() => _MovimientoFormViewState();
}

class _MovimientoFormViewState extends State<MovimientoFormView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();

  final DatabaseService _databaseService = DatabaseService.instance;

  String _tipoSeleccionado = 'ingreso';
  String? _categoriaSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now();
  bool _guardando = false;

  List<Map<String, dynamic>> get _categoriasPorTipo {
    return _databaseService
        .obtenerCategorias()
        .where((categoria) => categoria['tipo'] == _tipoSeleccionado)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final movimiento = widget.movimiento;
    if (movimiento != null) {
      _tipoSeleccionado = movimiento.tipo;
      _categoriaSeleccionada = movimiento.categoria;
      _montoCtrl.text = movimiento.monto.toStringAsFixed(2);
      _descripcionCtrl.text = movimiento.descripcion;
      _fechaSeleccionada = movimiento.fecha;
    } else {
      _categoriaSeleccionada = _categoriasPorTipo.isNotEmpty
          ? _categoriasPorTipo.first['nombre'] as String
          : null;
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarMovimiento() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')), 
      );
      return;
    }

    if (_categoriaSeleccionada == null || _categoriaSeleccionada!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')), 
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    final movimiento = Movimiento(
      id: widget.movimiento?.id,
      usuarioId: widget.usuarioId,
      tipo: _tipoSeleccionado,
      monto: monto,
      categoria: _categoriaSeleccionada!,
      descripcion: _descripcionCtrl.text.trim(),
      fecha: _fechaSeleccionada,
    );

    if (widget.movimiento == null) {
      await _databaseService.insertarMovimiento(movimiento);
    } else {
      await _databaseService.actualizarMovimiento(movimiento);
    }

    if (!mounted) return;
    setState(() {
      _guardando = false;
    });

    Navigator.pop(context, true);
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final categorias = _categoriasPorTipo;

    if (_categoriaSeleccionada == null && categorias.isNotEmpty) {
      _categoriaSeleccionada = categorias.first['nombre'] as String;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movimiento == null ? 'Agregar movimiento' : 'Editar movimiento'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Tipo de movimiento', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Ingreso'),
                        selected: _tipoSeleccionado == 'ingreso',
                        onSelected: (_) {
                          setState(() {
                            _tipoSeleccionado = 'ingreso';
                            _categoriaSeleccionada = _categoriasPorTipo.first['nombre'] as String;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Gasto'),
                        selected: _tipoSeleccionado == 'gasto',
                        onSelected: (_) {
                          setState(() {
                            _tipoSeleccionado = 'gasto';
                            _categoriaSeleccionada = _categoriasPorTipo.first['nombre'] as String;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: 'RD\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa el monto';
                    }
                    final valor = double.tryParse(val.trim().replaceAll(',', '.'));
                    if (valor == null || valor <= 0) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  key: ValueKey(_categoriaSeleccionada),
                  initialValue: _categoriaSeleccionada,
                  items: categorias
                      .map(
                        (categoria) => DropdownMenuItem<String>(
                          value: categoria['nombre'] as String,
                          child: Text(categoria['nombre'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoriaSeleccionada = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Text('Fecha', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _seleccionarFecha,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatoFecha.format(_fechaSeleccionada)),
                        const Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _guardando ? null : _guardarMovimiento,
                    child: _guardando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(widget.movimiento == null ? 'Guardar movimiento' : 'Actualizar movimiento'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
