# Arquitectura del Frontend

## Visión General

NotasApp es una aplicación Flutter que usa una arquitectura **feature-based** (basada en características) con **Provider** para gestión de estado. El app sigue el patrón **offline-first**, permitiendo al usuario crear y editar notas sin conexión y sincronizando con el backend cuando hay conectividad disponible.

## Estructura del Proyecto

```
lib/
├── core/                          # Funcionalidades compartidas
│   ├── env.dart                  # Configuración de entorno
│   ├── network/                  # Cliente HTTP (Dio)
│   ├── storage/                  # Almacenamiento seguro (tokens)
│   └── utils/                    # Utilidades (rutas, conectividad)
│
└── features/                     # Módulos por funcionalidad
    └── [feature_name]/
        ├── data/                 # API clients, repositorios, DB local
        ├── domain/               # Entidades/modelos
        ├── presentation/         # Páginas y widgets
        └── viewmodel/            # ChangeNotifiers (estado)
```

## Capas de la Aplicación

### Presentation (UI)
Contiene las páginas y widgets visuales. Cada feature tiene su propia carpeta de presentación donde se definen las pantallas principales.

- **Pages**: Widgets de pantalla completa (LoginPage, NotesListPage, NoteFormPage)
- **Widgets**: Componentes reutilizables dentro de las páginas

### ViewModel (Estado)
Usa **ChangeNotifier** de Provider para manejar el estado de cada feature. El patrón común incluye:

- `_busy`: Indica si hay una operación en progreso
- `_error`: Almacena el último error ocurrido
- `_setBusy()`: Método helper para cambiar estado y notificar

### Domain (Modelos)
Define las entidades del negocio. En este caso, la entidad `Note` contiene:
- id, title, content, updatedAt
- Métodos `fromJson()`, `toJson()`, `copyWith()`

### Data (Acceso a Datos)
Se divide en tres componentes:

1. **API Client**: Comunicación con el backend (Dio)
2. **Repository**: Abstracción que unifica fuentes de datos
3. **Local DB**: SQLite para almacenamiento offline

## Flujo de Datos

```
Usuario (UI)
    │
    ▼
ViewModel (ChangeNotifier)
    │
    ├──▶ Repository
    │       │
    │       ├──▶ API Client ──► Backend
    │       │
    │       └──▶ Local DB ──► SQLite
    │
    ▼
UI Actualizada (notifyListeners)
```

## Gestión de Estado

El app usa **Provider** con **MultiProvider** en el entry point. El flujo típico:

1. **lectura**: `context.watch<T>()` para observar cambios reactivos
2. **escritura**: `context.read<T>()` para acceder sin observar
3. **Check**: Siempre verificar `context.mounted` después de async operations

## Sincronización Offline-First

El sistema de notas implementa sincronización incremental:

1. **Crear/Editar localmente**: Se guarda en SQLite inmediatamente
2. **Marcar como "dirty"**: La fila se marca para sincronización
3. **Sync**: Cuando hay conexión, se envian los cambios al backend
4. **Limpiar**: Se descargan los datos más recientes del servidor

Esta arquitectura permite que el usuario use la app sin internet y sus cambios se sincronizan automáticamente cuando la conexión está disponible.

## Seguridad

- **Tokens JWT**: Almacenados en `FlutterSecureStorage` (cifrado en dispositivo)
- **Interceptor Dio**: Añade automáticamente el token a todas las peticiones
- **Limpieza**: El logout elimina el token del storage

## Rutas

Las rutas están centralizadas en `lib/core/utils/routes.dart` usando Navigator con nombre. Esto facilita:
- Navegación consistente
- Paso de argumentos entre pantallas
- Mantenimientocentralizado
