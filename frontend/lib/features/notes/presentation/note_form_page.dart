import 'package:flutter/material.dart';

class NoteFormPage extends StatefulWidget {
  final String? id; // si es null => crear
  final String? initialTitle;
  final String? initialContent;

  const NoteFormPage({
    super.key,
    this.id,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _content;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle ?? '');
    _content = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Text(
          isEdit ? 'Editar nota' : 'Nueva nota',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () => Navigator.of(context).pop({
              'id': widget.id,
              'title': _title.text.trim(),
              'content': _content.text.trim(),
            }),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _content,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

