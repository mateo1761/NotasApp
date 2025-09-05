import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/storage/secure.dart';
import '../../auth/viewmodel/auth_view_model.dart';
import '../domain/note.dart';
import '../viewmodel/notes_view_model.dart';
import 'note_form_page.dart';

class NotesListPage extends StatelessWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => NotesViewModel(ctx.read<SecureStore>())..load(),
      child: const _NotesListBody(),
    );
  }
}

class _NotesListBody extends StatelessWidget {
  const _NotesListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotesViewModel>();
    final auth = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.of(context).pop(); // vuelve al Login (home se decide por AuthVM)
            },
          ),
        ],
      ),
      body: vm.busy
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.refresh,
              child: vm.items.isEmpty
                  ? const ListTile(title: Text('Sin notas. Pulsa + para crear.'))
                  : ListView.separated(
                      itemCount: vm.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _NoteTile(note: vm.items[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final data = await Navigator.of(context).push<Map<String, dynamic>?>(
            MaterialPageRoute(builder: (_) => const NoteFormPage()),
          );
          if (data != null) {
            final ok = await context.read<NotesViewModel>().add(data['title'], data['content']);
            if (!ok && context.mounted) {
              final err = context.read<NotesViewModel>().error ?? 'Error creando nota';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(
        note.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () async {
        final data = await Navigator.of(context).push<Map<String, dynamic>?>(
          MaterialPageRoute(
            builder: (_) => NoteFormPage(
              id: note.id,
              initialTitle: note.title,
              initialContent: note.content,
            ),
          ),
        );
        if (data != null) {
          final ok = await context.read<NotesViewModel>().edit(
                note.id,
                data['title'],
                data['content'],
              );
          if (!ok && context.mounted) {
            final err = context.read<NotesViewModel>().error ?? 'Error actualizando nota';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        }
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final ok = await context.read<NotesViewModel>().remove(note.id);
          if (!ok && context.mounted) {
            final err = context.read<NotesViewModel>().error ?? 'Error eliminando nota';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        },
      ),
    );
  }
}