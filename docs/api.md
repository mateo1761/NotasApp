# Integración con API

## Visión General

El frontend se comunica con el backend REST mediante **Dio**, un cliente HTTP para Dart. El cliente está configurado con un interceptor que añade automáticamente el token de autenticación a todas las peticiones.

## Configuración del Cliente

El `DioClient` (en `lib/core/network/dio_client.dart`) se configura con:

- **Base URL**: Definida en `Env.apiBaseUrl`
- **Timeout**: 8 segundos para conexión y respuesta
- **Headers**: `Accept: application/json`
- **Interceptor**: Añade `Authorization: Bearer <token>` automáticamente

## Endpoints del Backend

### Autenticación

| Método | Endpoint         | Descripción             |
| ------ | ---------------- | ----------------------- |
| POST   | `/auth/register` | Registrar nuevo usuario |
| POST   | `/auth/login`    | Iniciar sesión          |

**Register** - Cuerpo de la petición:

```json
{
  "name": "string",
  "email": "string",
  "password": "string"
}
```

**Login** - Cuerpo de la petición:

```json
{
  "email": "string",
  "password": "string"
}
```

**Login** - Respuesta exitosa:

```json
{
  "accessToken": "jwt_token_string"
}
```

### Notas

| Método | Endpoint     | Descripción            |
| ------ | ------------ | ---------------------- |
| GET    | `/notes`     | Listar todas las notas |
| POST   | `/notes`     | Crear nueva nota       |
| PUT    | `/notes/:id` | Actualizar nota        |
| DELETE | `/notes/:id` | Eliminar nota          |

**Crear/Actualizar** - Cuerpo de la petición:

```json
{
  "title": "string",
  "content": "string"
}
```

**Listar** - Respuesta exitosa:

```json
[
  {
    "id": "string",
    "title": "string",
    "content": "string",
    "updatedAt": 1234567890
  }
]
```

## Modelo de Datos

### Nota

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final int updatedAt;  // Unix timestamp
}
```

## Autenticación

1. Al hacer login, el backend retorna un `accessToken`
2. El token se guarda en `FlutterSecureStorage` (cifrado)
3. El interceptor de Dio lee el token y lo añade a cada petición
4. Al hacer logout, se elimina el token del storage

## Manejo de Errores

El app lanza excepciones con mensajes descriptivos:

- **Errores de red**: Timeout o conexión fallida
- **Errores HTTP**: Código de estado no exitoso (201, 200, 204)
- **Errores del servidor**: Mensaje desde el campo `message` del JSON

El ViewModel captura errores y los almacena en `_error`, mostrando un SnackBar al usuario.

## Sincronización de Notas

El flujo de sync funciona así:

1. **Dirty rows**: Notas creadas/editadas localmente se marcan como `dirty = 1`
2. **Sync**: Se iteran las filas dirty y se envían al backend
3. **Fallback**: Si el PUT falla (nota no existe en servidor), se usa POST para crear
4. **Pull**: Después de subir cambios, se descargan todas las notas del servidor
5. **Limpiar**: Se reemplazan todas las notas locales con las del servidor

## Conectividad

El app verifica conectividad antes de sincronizar mediante `Net.isOnline()` que intenta conectarse al backend. Si no hay conexión, el sync se omite silenciosamente.
