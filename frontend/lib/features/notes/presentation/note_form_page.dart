import 'package:flutter/material.dart';
import 'package:frontend/core/utils/location.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class NoteFormPage extends StatefulWidget {
  final String? id;
  final String? initialTitle;
  final String? initialContent;
  final String? initialLocation;

  const NoteFormPage({
    super.key,
    this.id,
    this.initialTitle,
    this.initialContent,
    this.initialLocation,
  });

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _location;
  bool _loadingLocation = false;

  Future<void> _getCurrentLocation() async {
    final currentText = _location.text.trim();

    // If there's already a URL, ask user if they want to open it
    if (currentText.startsWith('https://')) {
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Abrir Google Maps?'),
          content: const Text('¿Desea abrir esta ubicación en Google Maps?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sí'),
            ),
          ],
        ),
      );
      if (shouldOpen == true) {
        final uri = Uri.parse(currentText);
        await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      }
      return;
    }

    // Get new GPS location
    setState(() => _loadingLocation = true);
    try {
      // Check if location services are enabled
      final serviceEnabled = await LocationUtils.isServiceEnabled();
      if (!serviceEnabled && mounted) {
        // Ask user to enable location services
        final enableLocation = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('GPS desactivado'),
            content: const Text('¿Desea activar el GPS para obtener su ubicación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Activar'),
              ),
            ],
          ),
        );
        if (enableLocation == true) {
          await LocationUtils.openLocationSettings();
        }
        return;
      }

      final position = await LocationUtils.getCurrentPosition();
      if (position != null && mounted) {
        final locationText = LocationUtils.formatCoordinates(position);
        _location.text = locationText;

        // Ask user if they want to open it
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Abrir Google Maps?'),
            content: const Text('¿Desea abrir esta ubicación en Google Maps?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sí'),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          final uri = Uri.parse(locationText);
          await url_launcher.launchUrl(
            uri,
            mode: url_launcher.LaunchMode.externalApplication,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle ?? '');
    _content = TextEditingController(text: widget.initialContent ?? '');
    _location = TextEditingController(text: widget.initialLocation ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _location.dispose();
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
              'location': _location.text.trim(),
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
            TextField(
              controller: _location,
              decoration: InputDecoration(
                labelText: 'Ubicación',
                hintText: 'Ej: Casa, URL en Google Maps, etc',
                suffixIcon: IconButton(
                  icon: _loadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  tooltip: 'Usar mi ubicación',
                  onPressed: _loadingLocation ? null : _getCurrentLocation,
                ),
              ),
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
