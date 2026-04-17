import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:frontend/core/utils/routes.dart';
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
      create: (ctx) {
        final vm = NotesViewModel();
        // Inicializa sin bloquear el build
        Future.microtask(() async {
          final isAndroid = Platform.isAndroid;
          final host = isAndroid ? '10.0.2.2' : 'localhost';
          await vm.init(ctx.read<SecureStore>(), host: host, port: 3000);
        });
        return vm;
      },
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
        title: const Text(
          'Tus Notas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            color: Colors.white,
            tooltip: 'Sincronizar',
            onPressed: vm.busy
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Sincronizando...')),
                    );

                    await context.read<NotesViewModel>().sync();

                    if (context.mounted) {
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Sincronización completa'),
                        ),
                      );
                    }
                  },
            icon: vm.busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
          IconButton(
            color: Colors.white,
            tooltip: 'Configuracion',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              Navigator.pushNamed(context, Routes.infoScreen);
            },
          ),
          IconButton(
            color: Colors.white,
            tooltip: 'Cerrar Session',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, Routes.loginScreen);
              }
            },
          ),
        ],
      ),
      body: vm.busy
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.sync,
              child: vm.items.isEmpty
                  ? const Center(child: Text('Sin notas. Pulsa + para crear.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: vm.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _NoteTile(note: vm.items[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        onPressed: () async {
          final data = await Navigator.of(context).push<Map<String, dynamic>?>(
            MaterialPageRoute(builder: (_) => const NoteFormPage()),
          );
          if (data != null) {
            final ok = await context.read<NotesViewModel>().add(
              data['title'] as String,
              data['content'] as String,
              location: data['location'] as String?,
            );
            if (!ok && context.mounted) {
              final err =
                  context.read<NotesViewModel>().error ?? 'Error creando nota';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(err)));
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
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar nota'),
            content: const Text(
              '¿Estás seguro de que quieres eliminar esta nota?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<NotesViewModel>().remove(note.id);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.deepPurpleAccent, width: 2.5),
        ),
        child: ListTile(
          title: Text(
            note.title,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.location != null && note.location!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.deepPurpleAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () async {
            final data = await Navigator.of(context)
                .push<Map<String, dynamic>?>(
                  MaterialPageRoute(
                    builder: (_) => NoteFormPage(
                      id: note.id,
                      initialTitle: note.title,
                      initialContent: note.content,
                      initialLocation: note.location,
                    ),
                  ),
                );
            if (data != null) {
              final ok = await context.read<NotesViewModel>().edit(
                note.id,
                data['title'] as String,
                data['content'] as String,
                location: data['location'] as String?,
              );
              if (!ok && context.mounted) {
                final err =
                    context.read<NotesViewModel>().error ??
                    'Error actualizando nota';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err)));
              }
            }
          },
        ),
      ),
    );
  }
}
