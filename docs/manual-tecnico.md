# Manual técnico

## 1. Arquitectura
```
 Cliente (navegador / Postman / k6)
        │  HTTP :8000
        ▼
 ┌──────────────────────┐   :11434   ┌───────────────┐
 │ API FastAPI          │──────────▶│ Ollama (host) │  motor "ollama"
 │ POST /clasificar     │            └───────────────┘
 │ GET /health          │  motor "eco": reglas regex en el propio proceso
 │ GET /inferencias     │
 └──────────┬───────────┘
            │ :5432 (red interna red-ia, usuario app_ia)
            ▼
     PostgreSQL 16-alpine  ──  volumen pgdata
```
- **API (api-ia):** contenedor Python 3.12-slim, usuario `appuser` sin privilegios. Puerto 8000.
- **Base de datos (db-ia):** PostgreSQL 16-alpine con `shared_buffers=32MB` y `max_connections=20`. Puerto 5432 publicado únicamente en `127.0.0.1` (para pruebas locales); no es accesible desde la red.
- **Ollama:** corre en el host (fuera de Docker); la API lo alcanza por `host.docker.internal:11434`.

## 2. Seguridad
- **Puertos expuestos:** solo 8000 (API) al host. PostgreSQL se publica solo en `127.0.0.1:5432` (no accesible desde otras máquinas); los demás servicios lo alcanzan por la red de Compose. En un servidor remoto se recomienda quitar esa línea. Ollama escucha en 11434 del host.
- **Roles en BD:** `postgres` (administrador; solo usado para inicialización, respaldo y restauración) y `app_ia` (LOGIN; CONNECT, USAGE sobre `public`, SELECT e INSERT sobre `inferencias`, USAGE/SELECT sobre su secuencia). `app_ia` no puede UPDATE, DELETE, TRUNCATE ni DROP.
- **Secretos:** en `.env` (ignorado por Git); se publica `.env.example` como plantilla. El contenedor recibe los valores por `env_file`; `.dockerignore` evita copiar `.env` a la imagen.
- **Si se filtra una contraseña:** rotarla de inmediato (`ALTER ROLE app_ia PASSWORD '...'`), actualizar `.env`, reiniciar la API, revisar la tabla `inferencias` en busca de actividad anómala y, si llegó a Git, purgar el historial y considerar la clave comprometida para siempre.

## 3. Endpoints
| Método | Ruta | Entrada | Respuesta | Errores |
|---|---|---|---|---|
| GET | `/health` | — | `{"estado":"ok","base_datos":"ok"}` | 503 BD no disponible |
| POST | `/clasificar` | JSON `{"texto": str, "motor": "eco"\|"ollama" (opcional)}` | `{motor, modelo, entrada, tipo, latencia_ms}` | 400 motor inválido; 422 cuerpo inválido; 500 Ollama caído |
| GET | `/inferencias` | query `limite` (int, def. 20) | lista de registros | 422 parámetro inválido |

## 4. Modelo de datos — tabla `inferencias`
| Campo | Tipo | Significado |
|---|---|---|
| id | SERIAL PK | Identificador |
| fecha | TIMESTAMP | Momento del registro (por defecto `NOW()`) |
| motor | VARCHAR(20) | `eco` u `ollama` |
| modelo | VARCHAR(120) | `reglas-v1` o nombre del modelo Ollama |
| entrada | TEXT | Mensaje de commit recibido |
| salida | TEXT | Categoría devuelta (o `desconocido`) |
| latencia_ms | INTEGER | Tiempo de clasificación en milisegundos |

## 5. Respaldo y restauración
- **Periodicidad propuesta:** diaria (03:00) y antes de cada despliegue. **Responsable:** _COMPLETAR (p. ej., integrante de operaciones)_. Los `.sql` nunca se suben a Git (`backups/` está en `.gitignore`).
```bash
mkdir -p backups
docker compose exec -T db pg_dump -a -U postgres iadb > backups/respaldo_$(date +%F).sql
# Restaurar (tras un desastre):
cat backups/respaldo_$(date +%F).sql | docker compose exec -T db psql -U postgres -d iadb
```
- **Nota:** `-a` (`--data-only`) respalda solo los datos, de modo que se restaura sobre la tabla existente tras un `TRUNCATE` sin errores de "ya existe". La estructura y los roles se recrean con `db/init.sql`.
- **Evidencia de prueba de restauración:** _COMPLETAR con conteos antes / después del desastre simulado._

## 6. Decisiones de diseño y limitaciones
- **Dockerfile multi-etapa:** la etapa de construcción instala dependencias y la final solo las ejecuta; imagen más pequeña y con menor superficie de ataque.
- **Usuario sin privilegios (`appuser`):** si el proceso es comprometido, no tiene acceso de administrador al contenedor.
- **Motor eco:** línea base sin consumo de memoria; permite desplegar, probar y documentar en cualquier equipo y comparar el costo real de la inferencia.
- **Privilegios mínimos en BD:** limita el daño de una inyección SQL o una credencial filtrada.
- **Limitaciones:** el motor eco es por palabras clave (baja precisión); los modelos pequeños pueden devolver `desconocido`; con `OLLAMA_KEEP_ALIVE=0` cada petición recarga el modelo; no hay autenticación de clientes ni HTTPS; no hay caché ni límite de tasa; se guardan textos de usuarios sin anonimizar; contraseñas del rol `app_ia` fijadas en `db/init.sql` (deben rotarse en producción).
