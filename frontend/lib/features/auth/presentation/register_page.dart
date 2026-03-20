import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodel/auth_view_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name,  decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 8),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _pass,  decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.busy ? null : () async {
                  await auth.register(_name.text.trim(), _email.text.trim(), _pass.text);
                  if (!mounted) return;
                  if (auth.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro exitoso, inicia sesión.')));
                  Navigator.of(context).pop();
                },
                child: auth.busy ? const CircularProgressIndicator() : const Text('Crear cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}