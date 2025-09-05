import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/viewmodel/auth_view_model.dart';
import '../../notes/presentation/notes_list_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.busy ? null : () async {
                  await auth.login(_email.text.trim(), _pass.text);
                  if (!mounted) return;
                  if (auth.isAuthenticated) {
                    // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NotesListPage()));
                  } else if (auth.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
                  }
                },
                child: auth.busy ? const CircularProgressIndicator() : const Text('Entrar'),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
