import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/storage/secure.dart';
import 'features/auth/viewmodel/auth_view_model.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/notes/presentation/notes_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotasApp());
}

class NotasApp extends StatelessWidget {
  const NotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SecureStore()),
        ChangeNotifierProvider(create: (ctx) => AuthViewModel(ctx.read<SecureStore>())..init()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (_, auth, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NotasApp',
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
            home: auth.isAuthenticated ? const NotesListPage() : const LoginPage(),
          );
        },
      ),
    );
  }
}
