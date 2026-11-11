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

## Qué se hizo y cómo funciona el código

### Resumen: de la entrega 2 a la entrega 3

| | Entrega 2 | Entrega 3 |
|---|---|---|
| Flask | 3 procesos Python en vm2, cada uno en su terminal tmux | 3 **contenedores** creados desde una sola **imagen** |
| Puertos Flask | 5001, 5002, 5003 en `127.0.0.1` | Los tres en el **5000 interno**, sin publicar |
| Nginx | Instalado con `pacman`, configurado en `/etc/nginx/conf.d` | Contenedor `nginx:1.28-alpine` con la configuración montada |
| Cómo se encuentran | Por IP y puerto (`127.0.0.1:5001`) | Por **nombre** (`flask1:5000`), con el DNS interno de Docker |
| Despliegue | Varios comandos a mano | `docker compose up -d --build` |
| Dependencias en vm2 | Python + venv + Flask + nginx | Solo Docker (Flask vive dentro de la imagen) |

```
 vm1 (cliente 10.0.2.3)            vm2 (anfitrión Docker 10.0.2.4)
 ┌──────────────┐  HTTP :8080   ┌─────────────────────────── red_lab (bridge) ───┐
 │ menu.sh      │ ────────────▶ │  nginx :80 ──┬──▶ flask1:5000                    │
 │ ensayos.py   │               │  (8080->80)  ├──▶ flask2:5000                    │
 └──────────────┘               │              └──▶ flask3:5000                    │
                                │  Solo nginx publica puerto. Flask: solo expose.  │
                                └──────────────────────────────────────────────────┘
```

### Recorrido de una solicitud

1. vm1 pide `http://10.0.2.4:8080/`.
2. Docker, en vm2, reenvía el puerto 8080 del anfitrión al puerto 80 del contenedor `nginx`.
3. Nginx elige la siguiente instancia del `upstream` por **round robin** (flask1 → flask2 → flask3 → …).
4. Nginx resuelve el nombre (`flask2`) con el DNS interno de Docker (`127.0.0.11`) y obtiene su IP en `red_lab`, por ejemplo `172.18.0.3`.
5. Flask responde el JSON y agrega el header `X-Servidor-Flask: flask2`.
6. Nginx agrega `X-Upstream: 172.18.0.3:5000`, registra la solicitud y devuelve la respuesta a vm1.
7. `ensayos.py` y `menu.sh` leen `X-Servidor-Flask` para contar qué instancia respondió.

### `app.py` — la aplicación

Es la de la entrega 2 con cuatro cambios:

```python
parser.add_argument('--id',   default=os.getenv('SERVER_ID', 'flask1'))
parser.add_argument('--host', default=os.getenv('HOST', '0.0.0.0'))
parser.add_argument('--port', type=int, default=int(os.getenv('PORT', '5000')))
```

- **`0.0.0.0` en vez de `127.0.0.1`:** dentro de un contenedor, `127.0.0.1` es el propio contenedor. Si Flask escuchara solo ahí, Nginx (otro contenedor) no podría conectarse.
- **`SERVER_ID` por variable de entorno:** el mismo código y la misma imagen sirven para las tres instancias; Compose le da a cada una su nombre.
- **Ruta `/`:** devuelve `servidor`, `fecha_hora`, `mensaje` y `estado`, como pide la fase 1. El portal HTML de la entrega 2 pasó a `/portal`.
- **Manejo de `SIGTERM`:** el proceso Python es el PID 1 del contenedor, y Linux no le aplica la acción por defecto de las señales. Sin `signal.signal(SIGTERM, ...)`, `docker stop` esperaría 10 s y lo mataría con `SIGKILL`. Con el manejador, se detiene en menos de 1 s.

`/health` responde HTTP 200 mientras la aplicación atiende solicitudes; lo usa el healthcheck de Compose. El contador `solicitudes_locales` es propio de cada contenedor: no comparten memoria.

### `Dockerfile` — la imagen

```dockerfile
FROM python:3.13-slim                 # imagen oficial, Debian mínima
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=5000
WORKDIR /app
COPY requirements.txt .               # capa 1: dependencias
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .                         # capa 2: código
RUN useradd --system --uid 10001 appuser
USER appuser                          # no corre como root
EXPOSE 5000
CMD ["python", "app.py"]
```

- **Orden de las capas:** primero `requirements.txt` y `pip install`, después `app.py`. Si solo cambia el código, Docker reutiliza la capa de dependencias en caché y el build tarda segundos.
- **`slim`:** más liviana que la imagen completa y, a diferencia de `alpine`, compatible con los paquetes precompilados de PyPI.
- **`PYTHONUNBUFFERED=1`:** los `print` y los registros salen al instante en `docker logs`.
- **`.dockerignore`:** solo entran `app.py` y `requirements.txt` a la imagen.

### `nginx/nginx.conf` — el balanceador

Es el `laboratorio.conf` de la entrega 2, cambiando `127.0.0.1:500X` por nombres de servicio:

```nginx
resolver 127.0.0.11 valid=5s ipv6=off;      # DNS interno de Docker
upstream servidores_flask {
    zone servidores_flask 64k;               # memoria compartida (requisito de resolve)
    server flask1:5000 resolve;
    server flask2:5000 resolve;
    server flask3:5000 resolve;
}
server {
    listen 80;
    location / {
        proxy_pass http://servidores_flask;
        proxy_connect_timeout 2s;
        proxy_next_upstream error timeout http_502 http_503;
        add_header X-Upstream $upstream_addr always;
    }
}
```

- **`resolve` + `resolver`:** sin esto, Nginx resolvería los nombres una sola vez al arrancar. Si flask2 se detiene y vuelve con otra IP, Nginx seguiría usando la vieja. Con `resolve`, consulta el DNS cada 5 s.
- **`proxy_next_upstream`:** si la conexión a una instancia falla, Nginx reintenta la **misma** solicitud en la siguiente. Por eso, con flask2 caído, el cliente ve 0 errores.
- **`proxy_connect_timeout 2s`:** cuando flask2 acaba de caer, su IP ya no existe y la conexión no se rechaza: espera. Este límite corta la espera en 2 s. Esa demora puntual es el **error transitorio** que aparece como latencia máxima de ~2000 ms.
- **`log_format balanceo`:** cada línea del registro incluye `upstream=IP:5000`, para ver a qué instancia fue cada solicitud.

**Limitación:** Nginx Open Source no consulta `/health` por su cuenta. Solo detecta fallos cuando una solicitud real falla (comprobación pasiva).

### `compose.yaml` — los cuatro servicios

```yaml
x-flask: &flask                 # bloque común (ancla YAML)
  build: .                      # imagen desde el Dockerfile
  image: lab-flask:1.0          # las 3 instancias usan la misma
  expose: ["5000"]              # solo dentro de la red
  networks: [red_lab]
  restart: unless-stopped
  healthcheck: { test: [python ... /health], interval: 10s, ... }

services:
  flask1: { <<: *flask, container_name: flask1, environment: { SERVER_ID: flask1 } }
  flask2: { ... SERVER_ID: flask2 }
  flask3: { ... SERVER_ID: flask3 }
  nginx:
    image: nginx:1.28-alpine
    ports: ["8080:80"]          # único puerto publicado
    volumes: ["./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro"]
    depends_on: [flask1, flask2, flask3]

networks:
  red_lab: { name: red_lab, driver: bridge }
```

- **Ancla `x-flask`:** evita repetir la misma configuración tres veces; cada servicio solo cambia su nombre y su `SERVER_ID`.
- **`expose` vs `ports`:** `expose` documenta el puerto dentro de la red; `ports` lo publica en el anfitrión. Por eso `localhost:5000` no es accesible desde vm2 y `localhost:8080` sí.
- **Red `bridge` propia:** da aislamiento y DNS por nombre de servicio (la red `bridge` por defecto de Docker no tiene DNS).
- **Montaje `:ro`:** Nginx lee la configuración del repositorio sin copiarla a una imagen; si cambia, basta con reiniciar el contenedor.
- **`healthcheck`:** `(healthy)` en `docker compose ps` indica que **la aplicación** responde, no solo que el contenedor está encendido.
- **`restart: unless-stopped`:** si el proceso muere solo (`lab.sh fallar`), Docker lo reinicia. Si lo detienes a mano (`lab.sh caer`), no. **No es alta disponibilidad:** no levanta otra máquina ni evita el tiempo sin servicio mientras reinicia.

### Scripts

| Script | Dónde | Qué hace por dentro |
|---|---|---|
| `instalar_docker.sh` | vm2 | `pacman -Syu docker docker-compose`, `systemctl enable --now docker`, agrega el usuario al grupo `docker`, detiene la entrega 2 (tmux y NGINX) para liberar el 8080 y descarga las imágenes base. |
| `lab.sh` | vm2 | Atajos de `docker compose`: `up -d --build`, `stop`/`start`, `logs`, `down`; `red` usa `docker network inspect`, `getent hosts` y `docker port`; `fallar` envía `SIGTERM` al PID 1 del contenedor. |
| `manual.sh` | vm2 | Las fases 2 a 4 sin Compose: `docker build`, `docker network create`, 3 × `docker run --network-alias flaskN` y `docker run` de Nginx con `-p 8080:80`. Los alias permiten usar el mismo `nginx.conf`. |
| `vista.sh` | vm2 | tmux con 4 paneles; cada uno sigue `docker logs -f` de un Flask, filtra los `/health` y espera si el contenedor se detiene. |
| `menu.sh` | vm1 | Menú que llama a `ensayos.py` o, en la opción 5, hace un `curl` cada 0,5 s y muestra la instancia que respondió. |
| `ensayos.py` | vm1 | N solicitudes con `urllib` (conexión nueva cada vez, sin caché); cuenta por `X-Servidor-Flask`, calcula %, errores y latencia, y guarda CSV y TXT en `evidencias/`. |

## Registro de experimentos

| Experimento | Resultado esperado | Resultado observado |
|---|---|---|
| 30 solicitudes con tres Flask | Respuestas de las tres instancias | |
| Detención de flask2 | Los otros siguen respondiendo; registrar transitorios | |
| Reinicio de flask2 | Se reincorpora a las respuestas | |
| Detención de Nginx | Acceso por 8080 interrumpido | |
| Reinicio de Nginx | Se restaura el acceso | |
| Reconstrucción con Compose | Cuatro servicios funcionales | |
