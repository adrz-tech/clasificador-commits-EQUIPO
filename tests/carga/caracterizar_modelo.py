"""Mide la latencia del motor ollama de forma secuencial."""
import statistics
import time

import requests

MENSAJES = [
    "agrega el endpoint de historial",
    "corrige el error de conexion a la base de datos",
    "actualiza el manual de instalacion",
    "agrega pruebas del clasificador",
    "renombra las variables del modulo de conexion",
    "actualiza las dependencias del proyecto",
    "implementa el healthcheck del contenedor",
    "arregla el calculo de la latencia",
    "documenta la politica de seguridad",
    "simplifica la funcion de registro",
]

tiempos = []
for i, texto in enumerate(MENSAJES, start=1):
    inicio = time.time()
    r = requests.post(
        "http://localhost:8000/clasificar",
        json={"texto": texto, "motor": "ollama"},
        timeout=300,
    )
    ms = (time.time() - inicio) * 1000
    tiempos.append(ms)
    print(f"{i:2d}. {ms:8.0f} ms -> {r.json()['tipo']:10s} | {texto[:40]}")

tiempos.sort()
print(f"\nPromedio: {statistics.mean(tiempos):.0f} ms")
print(f"Mediana:  {statistics.median(tiempos):.0f} ms")
print(f"p95:      {tiempos[int(len(tiempos) * 0.95) - 1]:.0f} ms")
