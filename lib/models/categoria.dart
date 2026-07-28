class Categoria {
  int? id;
  String nombre;
  String icono;
  String tipo; // 'ingreso' o 'gasto'

  Categoria({
    this.id,
    required this.nombre,
    required this.icono,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre, 'icono': icono, 'tipo': tipo};
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nombre: map['nombre'],
      icono: map['icono'],
      tipo: map['tipo'],
    );
  }
}
