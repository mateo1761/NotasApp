# NotasApp

Aplicación de notas con sincronización offline-first. Permite a los usuarios crear, editar y eliminar notas que funcionan sin conexión a internet y se sincronizan automáticamente cuando hay conectividad disponible.

## Tecnologías

| Capa | Tecnología |
|------|-------------|
| Frontend | Flutter + Provider |
| Backend | Node.js + Express |
| Base de datos local | SQLite (sqflite) |
| Auth | JWT + bcrypt |

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         FRONTEND                             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │   UI (Pages) │───▶│  ViewModel   │───▶│  Repository  │   │
│  └──────────────┘    └──────────────┘    └──────┬───────┘   │
│                                                  │            │
│                              ┌───────────────────┼────────┐  │
│                              ▼                   ▼        ▼  │
│                        ┌──────────┐       ┌──────────┐      │
│                        │  NotesApi│       │Local DB  │      │
│                        └──────────┘       └──────────┘      │
├─────────────────────────────────────────────────────────────┤
│                         BACKEND                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │  Express API │◀───│ Auth (JWT)   │◀───│   lowdb      │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Flujo Offline-First

La aplicación implementa una estrategia **offline-first** que permite al usuario usar la app sin conexión a internet. Los cambios se guardan localmente primero y se sincronizan con el servidor cuando hay conectividad.

### Funcionamiento del Sistema

#### 1. Creación de Notas

Cuando el usuario crea o edita una nota:

```
Usuario guarda nota
        │
        ▼
┌───────────────────┐
│ Guardar en SQLite│  → Se almacena inmediatamente en la base de datos local
│ (dirty = 1)       │  → Se marca como "dirty" (pendiente de sincronizar)
└───────────────────┘
```

El registro en SQLite incluye las columnas:
- `id`, `title`, `content`, `updatedAt` - Datos de la nota
- `dirty` (0/1) - Indica si la nota necesita sincronizarse
- `deleted` (0/1) - Indica si la nota fue eliminada localmente

#### 2. Sincronización

Cuando la app detecta conectividad, se ejecuta el proceso de sync:

```
┌─────────────────────────────┐
│ 1. Verificar conectividad   │
│    (ping al backend)        │
└──────────────┬──────────────┘
               │ Si hay conexión
               ▼
┌─────────────────────────────┐
│ 2. Obtener notas "dirty"   │
│    (WHERE dirty = 1)       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 3. Procesar cada nota      │
│                            │
│  • Si deleted = 1: DELETE   │
│  • Si existe: PUT /notes   │
│  • Si no existe: POST      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 4. Pull notas del servidor │
│    GET /notes              │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 5. Limpiar base local      │
│    (borrar todo e insertar │
│     datos del servidor)    │
└─────────────────────────────┘
```

#### 3. Fallback Automático

Si al intentar actualizar una nota (PUT) el servidor responde con 404 (la nota no existe en el servidor), el sistema crea la nota con POST:

```
try {
  await api.update(id, title, content);  // PUT
} catch (e) {
  // Si error 404 → crear la nota
  await api.create(title, content);       // POST
}
```

### Beneficios del Offline-First

- **Sin esperas**: La UI responde instantáneamente
- **Sin pérdida de datos**: Los cambios siempre se guardan localmente
- **Transparente**: El usuario no necesita saber si hay o no conexión
- **Respetuoso**: Funciona en zonas con conectividad limitada

## Autenticación

### Flujo de Auth

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Registro   │───▶│   Login     │───▶│  JWT Token  │
└─────────────┘    └─────────────┘    └──────┬──────┘
                                              │
                                              ▼
                                    ┌─────────────────┐
                                    │SecureStorage    │
                                    │(cifrado local)  │
                                    └─────────────────┘
```

### Seguridad

- **Tokens JWT**: Almacenados en `FlutterSecureStorage` (cifrado AES en el dispositivo)
- **Interceptor Dio**: Añade automáticamente el token a cada petición HTTP
- **Protección de rutas**: El backend valida el token en todas las rutas de notas
- **Logout**: Elimina el token del storage seguro

## API

### Endpoints de Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/auth/register` | Registrar nuevo usuario |
| POST | `/auth/login` | Iniciar sesión |

#### Register
```http
POST /auth/register
Content-Type: application/json

{
  "name": "Juan Pérez",
  "email": "juan@ejemplo.com",
  "password": "contraseña123"
}
```

**Respuesta (201):**
```json
{
  "id": "1234567890",
  "name": "Juan Pérez",
  "email": "juan@ejemplo.com"
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "juan@ejemplo.com",
  "password": "contraseña123"
}
```

**Respuesta (200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Endpoints de Notas

Todas las notas requieren autenticación (JWT en header `Authorization: Bearer <token>`).

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/notes` | Listar todas las notas del usuario |
| POST | `/notes` | Crear nueva nota |
| PUT | `/notes/:id` | Actualizar nota |
| DELETE | `/notes/:id` | Eliminar nota |

#### Listar Notas
```http
GET /notes
Authorization: Bearer <token>
```

**Respuesta (200):**
```json
[
  {
    "id": "1234567890",
    "title": "Mi primera nota",
    "content": "Contenido de la nota...",
    "updatedAt": 1700000000000
  }
]
```

#### Crear Nota
```http
POST /notes
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Nueva nota",
  "content": "Contenido opcional"
}
```

**Respuesta (201):**
```json
{
  "id": "1234567890",
  "userId": "user_123",
  "title": "Nueva nota",
  "content": "Contenido opcional",
  "updatedAt": 1700000000000
}
```

#### Actualizar Nota
```http
PUT /notes/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Nota actualizada",
  "content": "Nuevo contenido"
}
```

**Respuesta (200):**
```json
{
  "id": "1234567890",
  "userId": "user_123",
  "title": "Nota actualizada",
  "content": "Nuevo contenido",
  "updatedAt": 1700000001000
}
```

#### Eliminar Nota
```http
DELETE /notes/:id
Authorization: Bearer <token>
```

**Respuesta (204):** Sin contenido

### Códigos de Error

| Código | Descripción |
|--------|-------------|
| 400 | Solicitud inválida (parámetros faltantes) |
| 401 | No autorizado (token inválido o ausente) |
| 404 | Recurso no encontrado |
| 409 | Conflicto (email ya registrado) |
| 500 | Error interno del servidor |
