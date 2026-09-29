# Informe técnico del despliegue

> Los campos marcados **COMPLETAR** son mediciones de su propio equipo: no se pueden inventar. Ejecute los pasos de la guía y anote los valores reales.

## 1. Caracterización del modelo (semana 1)
| Dato | Cómo obtenerlo | Valor |
|---|---|---|
| Perfil de hardware | Sección 2 de la guía | COMPLETAR |
| RAM total del equipo | `free -h` | COMPLETAR |
| Modelo y etiqueta | `ollama list` | COMPLETAR |
| Tamaño en disco | `ollama list` | COMPLETAR |
| Latencia de 5 ejecuciones (ms) | `time curl ...` cinco veces | COMPLETAR |
| Latencia promedio | Promedio de las cinco | COMPLETAR |
| RAM usada durante la inferencia | `free -h` mientras responde | COMPLETAR |
| Calidad percibida (1 a 5) | Criterio + una frase | COMPLETAR |

## 2. Plan de pruebas (semana 4)
| ID | Tipo | Qué se verifica | Resultado esperado | Obtenido | Estado |
|---|---|---|---|---|---|
| P-01 | Funcional | GET /health responde | Código 200 y estado ok | COMPLETAR | |
| P-02 | Funcional | POST /clasificar con motor eco | Código 200 y tipo correcto | COMPLETAR | |
| P-03 | Funcional | Motor inválido | Código 400 | COMPLETAR | |
| P-04 | Acceso | Rol app_ia intenta DROP TABLE | Error de permisos | COMPLETAR | |
| P-05 | Conectividad | La API resuelve el host db | Devuelve una IP interna | COMPLETAR | |
| P-06 | Disponibilidad | Reinicio del contenedor de BD | La API se recupera sola | COMPLETAR | |
| P-07 | Persistencia | down y up conservan los datos | Los registros siguen existiendo | COMPLETAR | |
| P-08 | Carga | 10 usuarios sobre el motor eco | p95 < 800 ms y errores < 5 % | COMPLETAR | |
| P-09 | Caracterización | 10 inferencias con modelo | Promedio, mediana y p95 | COMPLETAR | |

### Análisis del cuello de botella
_COMPLETAR con sus datos._ Estructura sugerida: compare el p95 de P-08 (servicio con eco, normalmente decenas de ms) con el promedio de P-09 (segundos con modelo). Concluya en qué componente se pierde el tiempo (API, BD o inferencia) y por qué: cargar el modelo en memoria por `KEEP_ALIVE=0`, cómputo en CPU, tamaño del contexto (`num_ctx`), disco mecánico vs SSD.

### Propuestas de mejora (mínimo dos, justificadas)
1. **Mantener el modelo cargado** (`OLLAMA_KEEP_ALIVE=5m`) en equipos con memoria suficiente: elimina el costo de recarga en cada petición.
2. **Caché de mensajes repetidos** (p. ej., por hash del texto): evita inferencias redundantes.
3. **Limitar la concurrencia hacia el modelo** (cola / semáforo) para no saturar la RAM.
4. **Usar eco como filtro previo**: resolver con reglas los casos evidentes y enviar al modelo solo los ambiguos.

## 3. Evidencias de respaldo (semana 5)
Conteo antes: COMPLETAR · tras TRUNCATE: COMPLETAR · tras restaurar: COMPLETAR.

## 4. Propuesta de escalamiento (máx. 2 páginas)
**Diferencias local vs. remoto.** _COMPLETAR con lo que observaron (rutas, puerto asignado p. ej. 8010, `.env` creado en el servidor, permisos de Docker, disponibilidad de Ollama/modelo en el servidor)._

**Qué mover a la nube y qué mantener.** Sugerido: base de datos a un servicio gestionado (respaldos automáticos, alta disponibilidad); API en contenedores con balanceador; el modelo en una instancia dedicada. Mantener localmente el desarrollo y el motor eco para pruebas. Justificar según costo y control.

**Modelo con 1000 peticiones por minuto.** ≈17 peticiones/s. Con latencias de segundos por inferencia en CPU no basta un equipo pequeño: se requiere GPU o varias réplicas de inferencia, cola de peticiones, caché y eco como filtro. Implicación de costo: instancias con GPU facturadas por hora (costo fijo alto) frente a un API comercial por token (costo variable); estimar con la latencia medida en P-09.

**Disponibilidad y conservación de datos.** Réplicas de la API tras un balanceador, `restart: unless-stopped`, healthchecks, BD con réplica y respaldos automáticos probados, volúmenes persistentes, monitoreo y alertas.

**Protección de datos personales (Ley 1581 de 2012).** Los textos de commit pueden contener datos personales (nombres, correos, tokens). Aplicar: autorización previa e informada del titular y finalidad clara (principios de finalidad y libertad); minimización (guardar solo lo necesario, considerar anonimizar); seguridad (acceso restringido, cifrado, privilegios mínimos); política de tratamiento y canal para consultas, actualización y supresión; definir tiempo de retención; cuidar la transferencia a terceros/nube (país con nivel adecuado); y, si aplica, registro de la base de datos ante la SIC. _Valide con el área jurídica: esto no es asesoría legal._
