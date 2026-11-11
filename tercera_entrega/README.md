# Entrega 3 — Docker + Docker Compose + Nginx

Contenedorización de la entrega 2: **3 contenedores Flask** (una sola imagen) y **1 contenedor
Nginx** como balanceador, en una red privada de Docker. Todo se despliega con
`docker compose up -d --build`.

- **vm1** = cliente (10.0.2.3): envía las solicitudes con `scripts/menu.sh`.
- **vm2** = anfitrión Docker (10.0.2.4): corre los 4 contenedores; se controla con `scripts/lab.sh`.

Usa **Tab** para autocompletar: `bash scr` + Tab escribe `scripts/`.

---

## Paso a paso en la universidad

### Paso 1 — Arrancar las dos VMs (en ambas)

Inicia sesión con `osboxes` y ejecuta:

```bash
sudo loadkeys es
```
```bash
ip -br addr
```

Debe aparecer `eth0  UP  10.0.2.3/24` en vm1 y `10.0.2.4/24` en vm2. Si la IP de vm2 cambió, escríbela al final de los comandos de vm1 (por ejemplo, `bash scripts/menu.sh 10.0.2.5`).

### Paso 2 — Instalar Docker (solo vm2, solo la primera vez)

```bash
cd ~/Ngnix_Flask && git pull && cd tercera_entrega
```
```bash
bash scripts/instalar_docker.sh
```

Tarda varios minutos, sobre todo por las descargas. Al final debe mostrar:
- `active`, que indica que el servicio Docker quedó encendido;
- `Docker 2x.x` y `Docker Compose version v2...`;
- `Puerto 8080 libre`, porque el script detiene NGINX y los Flask de la entrega 2;
- `LISTO`.

**Si dice que el kernel se actualizó:** ejecuta `sudo reboot`, vuelve a entrar y repite este paso.

Al terminar, **cierra sesión y vuelve a entrar** para usar `docker` sin `sudo`:

```bash
exit
```

### Paso 3 — Levantar la infraestructura (vm2)

```bash
cd ~/Ngnix_Flask/tercera_entrega && bash scripts/lab.sh subir
```

La primera vez construye la imagen, y tarda porque `pip` descarga Flask. Debe terminar así:

```
NAME     IMAGE               STATUS                   PORTS
flask1   lab-flask:1.0       Up ... (healthy)         5000/tcp
flask2   lab-flask:1.0       Up ... (healthy)         5000/tcp
flask3   lab-flask:1.0       Up ... (healthy)         5000/tcp
nginx    nginx:1.28-alpine   Up ...                   0.0.0.0:8080->80/tcp

3 solicitudes a localhost:8080:
flask1  HTTP 200  0.002 s
flask2  HTTP 200  0.002 s
flask3  HTTP 200  0.002 s
```

Si sale `(health: starting)`, espera 10 s y ejecuta `bash scripts/lab.sh estado`.

### Paso 4 — Preparar el cliente (vm1)

```bash
cd ~/Ngnix_Flask && git pull && cd tercera_entrega && bash scripts/menu.sh
```

Elige `1`. Debe mostrar flask1, flask2 y flask3 con 10 solicitudes cada una y 0 errores. **Si sale así, todo está listo para la demostración.**

### Paso 5 (opcional) — Vista en vivo en vm2

```bash
bash scripts/vista.sh
```

Arriba ves 3 paneles con las solicitudes que recibe cada Flask; abajo escribes los comandos. Para salir sin detener nada: `Ctrl+b` y luego `d`.

---

## Guion de la demostración

Cada fila es un paso: primero lo de vm2, después lo de vm1.

| # | Fase de la guía | vm2 (servidor) | vm1 (menú) | Qué se debe ver |
|---|---|---|---|---|
| 1 | 1-2 Flask + imagen | `bash scripts/lab.sh bajar` y luego `bash scripts/manual.sh imagen` | — | Build, `lab-flask:1.0`, JSON de `/` con `servidor`, `fecha_hora`, `mensaje` y `estado`, y los logs |
| 2 | 3 Red y 3 instancias | `bash scripts/manual.sh red` | — | 3 contenedores, sus IPs y "Respuesta atendida por flask2/flask3" por nombre |
| 3 | 4 Nginx | `bash scripts/manual.sh nginx` | `1` | 30 solicitudes: 10 / 10 / 10 |
| 4 | — limpieza | `bash scripts/manual.sh bajar` | — | Elimina la parte manual |
| 5 | 5 Compose | `bash scripts/lab.sh subir` | `1` | 4 servicios con un solo comando |
| 6 | 3 Red (con Compose) | `bash scripts/lab.sh red` | — | IPs, DNS interno; solo nginx con puerto; `localhost:5000 no accesible` |
| 7 | 6 Caída de flask2 | `bash scripts/lab.sh caer flask2` | `2` | Solo flask1 y flask3, **0 errores**; latencia máxima de ~2000 ms (transitorio) |
| 8 | 6 Reincorporación | En vm1 elige `3` **primero**; luego `bash scripts/lab.sh levantar flask2` | `3` | "flask2 volvió a recibir tráfico a los X s" y luego 10 / 10 / 10 |
| 9 | 6 Caída de Nginx | `bash scripts/lab.sh caer nginx` | `4` | 30 de 30 errores: Nginx es el **punto único de fallo** |
| 10 | 6 Reinicio de Nginx | `bash scripts/lab.sh levantar nginx` | `1` | Vuelve el acceso: 10 / 10 / 10 |
| 11 | 6 Logs | `bash scripts/lab.sh logs nginx` | — | Cada solicitud con `upstream=172.18.0.X:5000` |
| 12 | 6 Reconstrucción | `bash scripts/lab.sh reconstruir` | `1` | `down` + `up --build`; 4 servicios funcionales |
| 13 | Extra: reinicio automático | `bash scripts/lab.sh fallar flask2` | — | `reinicios=1`: Docker lo levantó solo |

En vivo, la forma más visual es la opción **`5`** del menú (envío continuo) mientras en vm2 ejecutas `caer flask2`, `levantar flask2`, `caer nginx` y `levantar nginx`. Pulsa `Ctrl+C` para volver al menú.

Sin vm1 también funciona: en vm2, `bash scripts/lab.sh probar 30` o `bash scripts/menu.sh 127.0.0.1`.

### Comandos de vm2 (`bash scripts/lab.sh ...`)

| Comando | Qué hace |
|---|---|
| `subir` | `docker compose up -d --build` y muestra el estado |
| `estado` | Contenedores, salud y 3 solicitudes de prueba |
| `probar 30` | 30 solicitudes desde vm2, con resumen |
| `red` | Red, IPs, DNS interno y puertos publicados |
| `caer flask2` / `levantar flask2` | Detiene o inicia un servicio (también `nginx`, `flask1`, `flask3`) |
| `fallar flask2` | Mata el proceso dentro del contenedor (prueba la política de reinicio) |
| `logs nginx` | Últimos 20 registros (también `flask1`, etc.) |
| `reconstruir` | `down` + `up --build` |
| `bajar` | `docker compose down` |

### Opciones del menú de vm1

| Opción | Experimento de la guía |
|---|---|
| `1` | 30 solicitudes con los tres Flask |
| `2` | 30 solicitudes con flask2 detenido |
| `3` | Reincorporación de flask2 (mide los segundos) |
| `4` | 30 solicitudes con Nginx detenido |
| `5` | Envío continuo en vivo (`Ctrl+C` para parar) |
| `6` | Carga pesada: 300 solicitudes, 20 hilos |
| `7` | Una respuesta completa (headers + JSON) |
| `0` | Salir |

---

## Problemas comunes

| Síntoma | Causa probable | Solución |
|---|---|---|
| `permission denied ... docker.sock` | No cerraste sesión después de instalar | Los scripts usan `sudo` solos; o `exit` y vuelve a entrar |
| `port is already allocated` (8080 ocupado) | NGINX de la entrega 2, Compose o la parte manual siguen arriba | `sudo systemctl disable --now nginx`, `bash scripts/lab.sh bajar` y `bash scripts/manual.sh bajar` |
| `Conflict ... "m_flask1"` o `network red_manual already exists` | Quedó la parte manual de antes | `bash scripts/manual.sh bajar` |
| `toomanyrequests` al descargar | Límite de Docker Hub (IP compartida) | Esperar o usar otra red; las imágenes ya descargadas no se vuelven a pedir |
| Falla el `pip install` en el build | Sin internet dentro de Docker | `ping -c 2 pypi.org` en vm2; reintentar `lab.sh subir` |
| vm1 no conecta a `10.0.2.4:8080` | Nginx caído o IP distinta | En vm2: `bash scripts/lab.sh estado` e `ip -br addr` |
| Un Flask en `(unhealthy)` | La aplicación no responde a `/health` | `bash scripts/lab.sh logs flask2` |

---

## Archivos y decisiones técnicas

| Archivo | Qué hace |
|---|---|
| `app.py` | Flask de la entrega 2 adaptado: escucha en `0.0.0.0:5000`, `SERVER_ID` por variable de entorno, `/` con identificador, fecha/hora, mensaje y estado, `/health` con HTTP 200. Portal HTML en `/portal`. |
| `requirements.txt` | `Flask>=3.0,<4` |
| `Dockerfile` | `python:3.13-slim`, dependencias en capa aparte, usuario sin privilegios, `CMD python app.py`. |
| `nginx/nginx.conf` | `upstream` con `flask1:5000`, `flask2:5000` y `flask3:5000`; DNS interno; registro con `upstream=`. |
| `compose.yaml` | 4 servicios, red `red_lab`, healthcheck, `restart: unless-stopped`, montaje de solo lectura de `nginx.conf`, único puerto publicado `8080:80`. |
| `scripts/` | `instalar_docker.sh`, `lab.sh`, `manual.sh`, `vista.sh` (vm2); `menu.sh`, `ensayos.py` (cliente). |

```
 vm1 (cliente 10.0.2.3)            vm2 (anfitrión Docker 10.0.2.4)
 ┌──────────────┐  HTTP :8080   ┌─────────────────────────── red_lab (bridge) ───┐
 │ menu.sh      │ ────────────▶ │  nginx :80 ──┬──▶ flask1:5000                    │
 │ ensayos.py   │               │  (8080->80)  ├──▶ flask2:5000                    │
 └──────────────┘               │              └──▶ flask3:5000                    │
                                │  Solo nginx publica puerto. Flask: solo expose.  │
                                └──────────────────────────────────────────────────┘
```

- **Una imagen, tres contenedores:** el identificador no está en la imagen; llega por `SERVER_ID`.
- **Mismo puerto interno 5000:** cada contenedor tiene su propia IP en `red_lab`.
- **Nombres de servicio y `resolve`:** Nginx vuelve a consultar el DNS interno (`127.0.0.11`) cada 5 s; si flask2 cae o vuelve con otra IP, Nginx se entera sin reiniciarse. Requiere Nginx ≥ 1.27.3 (`nginx:1.28-alpine`).
- **`proxy_connect_timeout 2s` + `proxy_next_upstream`:** si una instancia cae, la solicitud se reintenta en otra; el cliente ve una demora (~2 s) en vez de un error. Ese es el **error transitorio**.
- **`SIGTERM` en `app.py`:** Flask es el PID 1 del contenedor; sin manejarlo, `docker stop` esperaría 10 s.
- **Healthcheck:** distingue *contenedor encendido* de *aplicación respondiendo*.
- **`restart: unless-stopped`:** reinicia si el proceso falla (`lab.sh fallar`), no si se detiene a mano (`lab.sh caer`).

## Registro de experimentos

| Experimento | Resultado esperado | Resultado observado |
|---|---|---|
| 30 solicitudes con tres Flask | Respuestas de las tres instancias | |
| Detención de flask2 | Los otros siguen respondiendo; registrar transitorios | |
| Reinicio de flask2 | Se reincorpora a las respuestas | |
| Detención de Nginx | Acceso por 8080 interrumpido | |
| Reinicio de Nginx | Se restaura el acceso | |
| Reconstrucción con Compose | Cuatro servicios funcionales | |
