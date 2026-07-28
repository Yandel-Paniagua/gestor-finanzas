import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  Usuario? usuario;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final u = await AuthService.instance.obtenerSesion();
    setState(() => usuario = u);
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await AuthService.instance.cerrarSesion();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF1A237E),
                    child: Text(
                      usuario!.nombre.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    usuario!.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    usuario!.email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Info cards
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: Color(0xFF1A237E),
                          ),
                          title: const Text('Nombre'),
                          subtitle: Text(usuario!.nombre),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.email,
                            color: Color(0xFF1A237E),
                          ),
                          title: const Text('Email'),
                          subtitle: Text(usuario!.email),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _cerrarSesion,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
