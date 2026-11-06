# Guía rápida — Laboratorio NGINX + Flask en Arch Linux

> vm1 = cliente (10.0.2.3) · vm2 = servidor (10.0.2.4). **Verifica siempre las IPs con `ip -br addr`**, porque pueden cambiar.
> Copia los archivos del docente (`app.py`, `laboratorio.conf`, `cliente_pruebas.py`, `requirements.txt`) en la raíz del repo antes de clonar.

## 0. Ambas VMs: teclado y clonado

```bash
sudo loadkeys es
```
```bash
sudo localectl set-keymap es
```
(La segunda línea deja el teclado en español de forma permanente.)
```bash
sudo pacman -Syu --needed git
```
```bash
git clone https://github.com/David34-bw/Ngnix_Flask.git && cd Ngnix_Flask
```
Si `pacman -Syu` actualiza el kernel, reinicia (`sudo reboot`) antes de seguir.

## Fase A — Preparación

**vm2:**
```bash
bash scripts/instalar_vm2.sh
```
Instala nginx, curl, tmux y Python; crea `venv/` con Flask; agrega `include /etc/nginx/conf.d/*.conf;` dentro de `http {}` si falta (guarda una copia en `nginx.conf.orig`); copia `laboratorio.conf`; ejecuta `nginx -t` y `systemctl enable --now nginx`.
Al final deberías ver `syntax is ok`, `test is successful`, `active` y las rutas de los logs.
Luego: `bash scripts/ajustes_nginx.sh` (crea `/var/log/nginx/error.log` y quita el aviso `types_hash`).

**vm1:**
```bash
bash scripts/instalar_vm1.sh --gui
```
(Sin `--gui` instala solo curl y Python.) Luego, `startx` para abrir XFCE. Activa el portapapeles compartido en VirtualBox: Dispositivos → Portapapeles compartido → Bidireccional.

**Evidencia A** (en las dos VMs):
```bash
ip -br addr
```
```bash
ping -c 4 10.0.2.4
```
(Desde vm1. Desde vm2, haz ping a 10.0.2.3.)

## Fase B — 3 instancias (vm2)

```bash
bash scripts/instancias.sh start
```
Abre la sesión tmux `lab` con las ventanas S1, S2 y S3 (puertos 5001, 5002 y 5003) e imprime el JSON de `/api/estado` de cada una. **Evidencia B:** 3 JSON con identificadores distintos.

| Acción | Comando |
|---|---|
| Ver estado | `bash scripts/instancias.sh status` |
| Ver consolas | `bash scripts/instancias.sh ver` (salir: `Ctrl+b` y luego `d`) |
| Detener solo S2 | `bash scripts/instancias.sh stop S2` |
| Reiniciar S2 | `bash scripts/instancias.sh restart S2` |

Los logs de cada instancia quedan en `logs/S1.log` (y equivalentes).

## Fase C — NGINX

vm2: `bash scripts/evidencias_vm2.sh faseC` guarda las IPs, `ss -ltnp`, `nginx -t`, la configuración y los logs en `evidencias/`.
vm1: `bash scripts/probar_vm1.sh` (portal y API por curl, guarda en `evidencias/`). Con interfaz: Firefox en `http://10.0.2.4:8080/`. **Evidencia C:** captura.

## Sesión 2 — Ensayos (cliente en vm1, control en vm2)

| # | vm2 (antes) | vm1 |
|---|---|---|
| 1 Round robin | `bash scripts/pesos.sh rr` | `python3 scripts/ensayos.py rr` |
| 2 Pesos 3:1:1 | `bash scripts/pesos.sh ponderado` | `python3 scripts/ensayos.py ponderado` |
| 3 Fallo | `bash scripts/pesos.sh rr` y `bash scripts/instancias.sh stop S2` | `python3 scripts/ensayos.py fallo` |
| 4 Recuperación | (primero arranca el comando de vm1) `bash scripts/instancias.sh restart S2` | `python3 scripts/ensayos.py recuperacion` |
| 5 Latencia | — | `... ligera` y `... pesada` |
| 6 Logs | `bash scripts/evidencias_vm2.sh final` | — |

- Los resultados se guardan en `evidencias/<ensayo>_<fecha>.csv` y `.txt`, con el conteo, el %, el % teórico, los errores, los códigos HTTP, la latencia media y máxima, y la secuencia de réplicas.
- Ejecuta también el `cliente_pruebas.py` del docente en cada ensayo, como indica la guía, y toma una captura o guarda la salida: `python3 cliente_pruebas.py ... | tee evidencias/cliente_rr.txt`.
- Durante el ensayo 3, ejecuta `evidencias_vm2.sh fallo_S2` en vm2 para que `error.log` muestre los `connect() failed`.
- Retos de diagnóstico, para reproducirlos: A (502) = `instancias.sh stop` (todas); B (no conecta a 8080) = `sudo systemctl stop nginx`; C (solo S1) = dejar activa solo S1; D = probar `/api/calcular` con datos inválidos. Guarda el comando y el resultado con `evidencias_vm2.sh retoX`.

## Sacar las evidencias de las VMs

Los ensayos ya quedan en `evidencias/` de vm1. Para traer los de vm2 por HTTP temporal en la red privada, primero en **vm2**:
```bash
cd ~/Ngnix_Flask/evidencias && python3 -m http.server 8000 --bind 10.0.2.4
```
Luego en **vm1** (después, detén el servidor de vm2 con `Ctrl+c`):
```bash
cd ~/Ngnix_Flask/evidencias && wget -r -np -nH -nd -A txt,csv http://10.0.2.4:8000/
```
(Si `wget` no está, instálalo con `sudo pacman -Syu wget`.) Después, desde Firefox en vm1, súbelos adonde decidas, o copia el texto con el portapapeles compartido.

## Checklist de entrega (rúbrica)

- [ ] Preparación (2): IPs, ping, `nginx -v`, `pip show flask` → `vm2_faseA*.txt` + capturas
- [ ] Instancias (2): 3 JSON distintos → captura de `instancias.sh status`
- [ ] NGINX (3): `nginx -t`, include conf.d, captura del portal en Firefox
- [ ] Ensayos (3): `rr`, `ponderado`, `fallo`, `recuperacion` (.txt/.csv)
- [ ] Mediciones (3): `ligera` y `pesada` + tabla de resultados
- [ ] Diagnóstico (2): al menos 2 retos con hipótesis, comando, resultado y solución
- [ ] ZIP: `app.py`, `laboratorio.conf`, `evidencias/`, informe PDF
