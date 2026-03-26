import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:frontend/core/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/storage/secure.dart';
import 'features/auth/viewmodel/auth_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const NotasApp());
}

class NotasApp extends StatelessWidget {
  const NotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SecureStore()),
        ChangeNotifierProvider(
          create: (ctx) => AuthViewModel(ctx.read<SecureStore>())..init(),
        ),
      ],
      child: Consumer<AuthViewModel>(
        builder: (_, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NotasApp',
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
            initialRoute: auth.isAuthenticated
                ? Routes.menuScreen
                : Routes.loginScreen,

            routes: Routes.routes,
          );
        },
      ),
    );
  }
}

//Test@gmail.com

