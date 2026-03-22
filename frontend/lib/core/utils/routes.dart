import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/login_page.dart';
import 'package:frontend/features/auth/presentation/register_page.dart';
import 'package:frontend/features/notes/presentation/note_form_page.dart';
import 'package:frontend/features/notes/presentation/notes_list_page.dart';

class Routes {
  static const initialRoute = loginScreen;

  static const String loginScreen = 'loginscreen';
  static const String registerScreen = 'registerscreen';
  static const String menuScreen = 'menuscreen';
  static const String noteScreen = 'notescreen';

  static Map<String, Widget Function(BuildContext)> routes = {
    loginScreen: (context) => const LoginPage(),
    menuScreen: (context) => const NotesListPage(),
    registerScreen: (context) => const RegisterPage(),
    noteScreen: (context) => const NoteFormPage(),
  };
}
