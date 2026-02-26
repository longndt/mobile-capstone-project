import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Educational App',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SplashDecider(),
    );
  }
}

class SplashDecider extends StatelessWidget {
  const SplashDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getSavedToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          // Replace with your real HomeScreen
          return const _LoggedInPlaceholder();
        }

        return const LoginScreen();
      },
    );
  }
}

class _LoggedInPlaceholder extends StatelessWidget {
  const _LoggedInPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Auto-login success (token found)')),
    );
  }
}
