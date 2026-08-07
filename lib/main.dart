import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'views/splash_screen.dart';
import 'views/login_view.dart';
import 'views/registro_view.dart';
import 'views/home_view.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const GestorFinanzasApp(),
    ),
  );
}

class GestorFinanzasApp extends StatelessWidget {
  const GestorFinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Finanzas',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginView(),
        '/registro': (context) => const RegistroView(),
        '/home': (context) => const HomeView(),
      },
    );
  }
}
