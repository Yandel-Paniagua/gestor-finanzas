import 'package:flutter/material.dart';
import 'perfil_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _paginaActual = 0;

  final List<Widget> _paginas = [
    const Center(
      child: Text(
        'Dashboard\n(Integrante 3)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24),
      ),
    ),
    const Center(
      child: Text(
        'Ingresos y Gastos\n(Integrante 2)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24),
      ),
    ),
    const PerfilView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaActual,
        selectedItemColor: const Color(0xFF1A237E),
        onTap: (index) => setState(() => _paginaActual = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Finanzas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
