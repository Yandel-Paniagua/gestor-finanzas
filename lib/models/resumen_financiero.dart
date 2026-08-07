class ResumenFinanciero {
  final double ingresos;
  final double gastos;
  final double balance;
  final int cantidadIngresos;
  final int cantidadGastos;

  const ResumenFinanciero({
    required this.ingresos,
    required this.gastos,
    required this.balance,
    required this.cantidadIngresos,
    required this.cantidadGastos,
  });

  factory ResumenFinanciero.vacio() {
    return const ResumenFinanciero(
      ingresos: 0,
      gastos: 0,
      balance: 0,
      cantidadIngresos: 0,
      cantidadGastos: 0,
    );
  }
}