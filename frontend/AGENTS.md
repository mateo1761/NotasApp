# AGENTS.md - Frontend Development Guide

Guidelines for agents working on the NotasApp Flutter frontend.

## Project Overview

| Aspect | Technology |
|--------|------------|
| Framework | Flutter + Dart |
| State Management | Provider |
| Architecture | Feature-based (domain/data/presentation) |
| Database | SQLite (sqflite) |
| API Client | Dio with JWT interceptor |

## Build, Lint, and Test Commands

**Important**: All Flutter commands must be run inside the nix shell:
```bash
nix-shell -p flutter
```

### Building
```bash
flutter build apk --debug   # Debug APK
flutter build apk --release # Release APK
flutter build ios        # iOS (macOS only)
flutter build web       # Web
```

### Linting
```bash
flutter analyze        # Run static analysis
flutter analyze --fix # Fix auto-fixable issues
```

### Testing
```bash
flutter test                      # Run all tests
flutter test test/file_test.dart   # Run single test file
flutter test --name "testName"   # Run tests matching pattern
```

## Code Style Guidelines

### Formatting
- Use `dart format` before committing
- 2-space indentation, max 80 chars/line
- Use trailing commas in collections

### Imports
```dart
// Package imports
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// Relative imports for internal code
import '../domain/note.dart';
import 'notes_api.dart';
```

### Types and Variables
- Use `final` by default; `var` only when mutation needed
- Prefer explicit types over `var`/`dynamic` for public APIs
- Use `late` sparingly

```dart
// Good
final String title = 'Hello';
final List<Note> notes = [];
final Note note = Note(id: '1', title: 'Test', content: '', updatedAt: 0);

// Avoid
var title = 'Hello';
dynamic something;
```

### Naming Conventions
| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `NotesRepository` |
| Files | snake_case | `notes_repository.dart` |
| Vars/Functions | camelCase | `getNotes()` |
| Constants | SCREAMING_SCREAM | `const int maxLength = 100` |
| Private members | prefix `_` | `_privateMethod()` |

### Architecture Structure
```
lib/
├── core/                    # Shared utilities
│   ├── env.dart            # Environment config
│   ├── network/            # HTTP client
│   ├── storage/            # Local storage
│   └── utils/              # Utilities
└── features/
    └── feature_name/
        ├── data/           # Repositories, APIs, DB
        ├── domain/         # Models/entities
        ├── presentation/  # UI (pages, widgets)
        └── viewmodel/      # State (Provider)
```

### Error Handling
- Use try-catch for async operations
- Prefer specific exception types
- Log errors appropriately (no sensitive data)
- Handle offline scenarios gracefully

```dart
try {
  await _api.delete(id);
} catch (e) {
  debugPrint('Delete failed: $e');
}

try {
  final result = await dio.get('/notes');
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    // Handle timeout
  }
}
```

### Widget Guidelines
- Use `const` constructors when possible
- Extract reusable widgets into separate files
- Prefer composition over inheritance
- Keep widgets focused

```dart
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(note.title),
        onTap: onTap,
      ),
    );
  }
}
```

### Provider Usage
- One provider per feature (AuthViewModel, NotesViewModel)
- Use `ChangeNotifier` for state
- Use `Consumer` or `context.watch` for reactive updates
- Keep view models lean; delegate to repositories

```dart
class NotesViewModel extends ChangeNotifier {
  final NotesRepository _repository;

  NotesViewModel(this._repository);

  Future<void> loadNotes() async {
    notifyListeners();
  }
}

// Usage
Consumer<NotesViewModel>(
  builder: (context, vm, child) {
    return ListView.builder(itemCount: vm.notes.length);
  },
)
```

### Async/Await
- Always use `async`/`await` over raw Futures
- Handle loading states in UI
- Cancel operations when widget disposes (use `mounted` check)

```dart
Future<void> _loadData() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  try {
    final data = await repository.fetch();
    if (!mounted) return;
    setState(() => _data = data);
  } catch (e) {
    if (!mounted) return;
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### Database (SQLite)
- Use transactions for batch operations
- Handle schema migrations
- Clean up resources in dispose
```dart
await db.markDirty(note);
final dirty = await db.dirtyRows();
```

### API Communication
- All endpoints require JWT in `Authorization` header
- Dio interceptor handles token injection
- Validate responses

### Linter Rules
Uses `flutter_lints` (in `analysis_options.yaml`):
- `prefer_single_quotes`: Single quotes for strings
- `avoid_print`: Use `debugPrint` in debug
- `prefer_const_constructors`: Use const when possible
- `use_key_in_widget_constructors`: Always provide key

```dart
// ignore: avoid_print
print('debug');
```

## Common Patterns

### Offline-First Sync
1. Write to local SQLite first (mark `dirty=1`)
2. On connectivity, push dirty records to server
3. Pull server state and replace local
4. Handle 404 on update by creating resource

### Auth Flow
1. Login/Register returns JWT token
2. Store in `FlutterSecureStorage`
3. Dio interceptor adds token to requests
4. Logout clears token