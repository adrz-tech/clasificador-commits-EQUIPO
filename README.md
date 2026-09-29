# Clasificador de mensajes de commit

Servicio de inferencia que recibe el texto de un commit y lo clasifica como `feat`, `fix`, `docs`, `test`, `chore` o `refactor`. Ofrece dos motores: **eco** (reglas, sin modelo) y **ollama** (LLM local). Cada petición se registra en PostgreSQL. Todo está contenerizado con Docker Compose y validado con GitHub Actions.

- **Integrantes:** _COMPLETAR (máximo 3)_
- **Perfil de hardware:** _COMPLETAR (A, B, C o D)_
- **Video de demostración:** _COMPLETAR enlace_

## Requisitos mínimos
- 4 GB de RAM, 15 GB libres en disco, virtualización habilitada.
- Windows 10 versión 2004 o superior (con WSL2 + Ubuntu 24.04) o cualquier Linux.
- Docker Engine + Docker Compose, Git. Ollama es opcional (solo para el motor `ollama`).

## Instalación paso a paso
```bash
# 1) Solo Windows (PowerShell como administrador): wsl --install -d Ubuntu-24.04
# 2) Dentro de Ubuntu:
git clone git@github.com:USUARIO/clasificador-commits-EQUIPO.git
cd clasificador-commits-EQUIPO
./setup.sh                 # instala utilidades, Docker y Ollama
# cierre y reabra la terminal, luego:
ollama pull gemma3:270m    # Perfil C. B: qwen2.5:0.5b  A: qwen2.5-coder:1.5b
cp .env.example .env       # ajuste MODELO_OLLAMA y las claves si desea
docker compose up -d --build
```

## Verificar que funciona
```bash
docker compose ps                       # db (healthy) y api (running)
curl http://localhost:8000/health       # {"estado":"ok","base_datos":"ok"}
curl -X POST http://localhost:8000/clasificar -H "Content-Type: application/json" \
     -d '{"texto":"corrige el error de login","motor":"eco"}'
curl "http://localhost:8000/inferencias?limite=5"
```
También puede usar la documentación interactiva en http://localhost:8000/docs.

## Pruebas
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -v          # requiere la BD en marcha: docker compose up -d db (usa DB_HOST=localhost del .env)
```

## Solución de problemas
_Complete con al menos 5 errores reales que les ocurrieron._ Ejemplos frecuentes (Anexo B de la guía):

| Error | Causa | Solución |
|---|---|---|
| `permission denied ... docker daemon socket` | No reabrió la terminal tras `usermod -aG docker` | Cerrar y reabrir la terminal |
| `port is already allocated` | Otro contenedor usa el puerto | `docker ps` y `docker rm -f <nombre>` |
| `FATAL: password authentication failed` | `.env` distinto de `db/init.sql` | Alinear claves; `docker compose down -v` |
| `connection refused` a la BD | Host incorrecto | Dentro de Compose el host es `db` |
| API 500 con motor ollama | Ollama detenido o modelo no descargado | `ollama list`, `sudo systemctl status ollama` |
