#!/usr/bin/env python3
"""Experimentos de la entrega 3 contra Nginx en Docker (corre en vm1 o vm2). Solo biblioteca estándar.

Cada petición abre una conexión nueva (urllib, Connection: close) y envía
Cache-Control: no-cache. Identifica la instancia por el header X-Servidor-Flask.
Guarda: evidencias/<ensayo>_<fecha>.csv (detalle) y .txt (resumen).

Uso:
  python3 scripts/ensayos.py tres_flask    # 30 GET con las tres instancias
  python3 scripts/ensayos.py sin_flask2    # 30 GET con flask2 detenido
  python3 scripts/ensayos.py recuperacion  # sondea hasta que flask2 vuelva a responder
  python3 scripts/ensayos.py sin_nginx     # 30 GET con Nginx detenido (se esperan errores)
  python3 scripts/ensayos.py pesada        # 300 GET, 20 hilos
  Opcionales: --ip 10.0.2.4 (127.0.0.1 en vm2)  -n N  -c HILOS  --puerto 8080  --ruta /
"""
import argparse, csv, ipaddress, json, os, statistics, sys, time, urllib.error, urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

PRESETS = {"tres_flask": (30, 1), "sin_flask2": (30, 1), "sin_nginx": (30, 1),
           "ligera": (20, 1), "pesada": (300, 20)}
TEORICO = {"tres_flask": {"flask1": 33.3, "flask2": 33.3, "flask3": 33.3},
           "sin_flask2": {"flask1": 50.0, "flask3": 50.0}}

def una(url, i):
    req = urllib.request.Request(url, headers={"Cache-Control": "no-cache", "Connection": "close"})
    t0 = time.perf_counter(); srv, cod, err = "", 0, ""
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            cod, cuerpo = r.status, r.read()
            srv = r.headers.get("X-Servidor-Flask", "")
            if not srv:
                try:
                    d = json.loads(cuerpo)
                    srv = str(next((d[k] for k in ("servidor", "id", "instancia", "server") if k in d), ""))
                except Exception:
                    pass
    except urllib.error.HTTPError as e:
        cod, err = e.code, f"HTTP {e.code}"
    except Exception as e:
        err = type(e).__name__ + ": " + str(e)[:80]
    ms = (time.perf_counter() - t0) * 1000
    return {"n": i + 1, "hora": datetime.now().strftime("%H:%M:%S.%f")[:-3],
            "servidor": srv or "-", "codigo": cod, "latencia_ms": round(ms, 2), "error": err}

def resumen(nombre, filas, extra=""):
    total = len(filas); ok = [f for f in filas if f["codigo"] == 200]
    cnt = Counter(f["servidor"] for f in ok); errores = total - len(ok)
    lat = [f["latencia_ms"] for f in filas]
    lin = [f"Ensayo: {nombre}   Fecha: {datetime.now():%Y-%m-%d %H:%M:%S}", extra,
           f"{'Instancia':<10}{'Atendidas':>10}{'%':>9}{'Teórico %':>11}"]
    teo = TEORICO.get(nombre, {})
    for s in sorted(set(cnt) | set(teo)):
        lin.append(f"{s:<10}{cnt.get(s, 0):>10}{cnt.get(s, 0) / total * 100:>8.1f}%{teo.get(s, 0):>10.1f}%")
    lin += [f"{'Errores':<10}{errores:>10}{errores / total * 100:>8.1f}%", f"{'Total':<10}{total:>10}",
            f"Códigos HTTP: {dict(Counter(f['codigo'] for f in filas))}",
            f"Latencia ms -> media {statistics.mean(lat):.2f} | mediana {statistics.median(lat):.2f} | "
            f"máx {max(lat):.2f} | mín {min(lat):.2f}",
            "Secuencia: " + " ".join(f["servidor"] for f in filas)]
    return "\n".join(l for l in lin if l is not None)

def guardar(nombre, filas, texto):
    d = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "evidencias")
    os.makedirs(d, exist_ok=True); base = os.path.join(d, f"{nombre}_{datetime.now():%Y%m%d_%H%M%S}")
    with open(base + ".csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0])); w.writeheader(); w.writerows(filas)
    with open(base + ".txt", "w") as f:
        f.write(texto + "\n")
    print(texto); print(f"\nGuardado: {os.path.normpath(base)}.csv / .txt")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ensayo", choices=list(PRESETS) + ["recuperacion"])
    ap.add_argument("--ip", default="10.0.2.4"); ap.add_argument("--puerto", type=int, default=8080)
    ap.add_argument("--ruta", default="/"); ap.add_argument("-n", type=int); ap.add_argument("-c", type=int)
    a = ap.parse_args()
    if not ipaddress.ip_address(a.ip).is_private:
        sys.exit("Seguridad: solo se permiten IPs privadas del laboratorio.")
    url = f"http://{a.ip}:{a.puerto}{a.ruta}"

    if a.ensayo == "recuperacion":
        print("Sondeando cada 0.5 s hasta que flask2 responda (máx. 120 s). Levanta flask2 en vm2 ahora.")
        filas, t0 = [], time.perf_counter()
        while time.perf_counter() - t0 < 120:
            f = una(url, len(filas)); f["t_s"] = round(time.perf_counter() - t0, 2); filas.append(f)
            if f["servidor"] == "flask2":
                break
            time.sleep(0.5)
        extra = (f"flask2 volvió a recibir tráfico a los {filas[-1]['t_s']} s ({len(filas)} sondeos)"
                 if filas[-1]["servidor"] == "flask2" else "flask2 NO volvió en 120 s")
        n2 = a.n or 30
        post = [una(url, i) for i in range(n2)]
        guardar("recuperacion_sondeo", filas, resumen("recuperacion_sondeo", filas, extra))
        guardar("recuperacion", post, resumen("recuperacion", post, extra + f" | luego {n2} GET"))
        return

    n, c = PRESETS[a.ensayo]; n, c = a.n or n, a.c or c
    t0 = time.perf_counter()
    if c == 1:
        filas = [una(url, i) for i in range(n)]
    else:
        with ThreadPoolExecutor(c) as ex:
            filas = list(ex.map(lambda i: una(url, i), range(n)))
    dur = time.perf_counter() - t0
    guardar(a.ensayo, filas, resumen(a.ensayo, filas, f"URL {url} | {n} peticiones | {c} hilo(s) | "
                                     f"duración {dur:.2f} s | {n / dur:.1f} req/s"))

if __name__ == "__main__":
    main()
