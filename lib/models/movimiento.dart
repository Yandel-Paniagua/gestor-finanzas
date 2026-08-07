class Movimiento {
  final int? id;
  final int usuarioId;
  final String tipo;
  final double monto;
  final String categoria;
  final String descripcion;
  final DateTime fecha;

  const Movimiento({
    this.id,
    required this.usuarioId,
    required this.tipo,
    required this.monto,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
  });

  bool get esIngreso => tipo.toLowerCase() == 'ingreso';

  bool get esGasto => tipo.toLowerCase() == 'gasto';

  Movimiento copyWith({
    int? id,
    int? usuarioId,
    String? tipo,
    double? monto,
    String? categoria,
    String? descripcion,
    DateTime? fecha,
  }) {
    return Movimiento(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
    );
  }

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'] as int?,
      usuarioId: map['usuarioId'] as int,
      tipo: map['tipo'] as String,
      monto: (map['monto'] as num).toDouble(),
      categoria: map['categoria'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'tipo': tipo,
      'monto': monto,
      'categoria': categoria,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
    };
  }
}