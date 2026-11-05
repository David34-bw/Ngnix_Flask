# Laboratorio NGINX + Flask

## Objetivo
Ejecutar tres réplicas Flask de una misma aplicación web y distribuir solicitudes HTTP mediante NGINX.

## Requisitos (VM servidor Linux)
```bash
sudo apt update
sudo apt install -y nginx python3 python3-venv curl
cd lab_nginx_flask
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Ejecutar las tres instancias
En tres terminales (activar `.venv` si es necesario):
```bash
.venv/bin/python app.py --id S1 --port 5001
.venv/bin/python app.py --id S2 --port 5002
.venv/bin/python app.py --id S3 --port 5003
```
Comprobar desde la VM servidor:
```bash
curl http://127.0.0.1:5001/api/estado
curl http://127.0.0.1:5002/api/estado
curl http://127.0.0.1:5003/api/estado
```

## NGINX
```bash
sudo cp laboratorio.conf /etc/nginx/conf.d/laboratorio.conf
sudo nginx -t
sudo systemctl reload nginx
```
Consultar desde el cliente `http://IP_DE_LA_VM_SERVIDOR:8080/`. El puerto 8080 debe ser accesible entre ambas VM. Si se utiliza UFW, habilitar únicamente desde la red privada del laboratorio.

## Páginas
- `/` Inicio
- `/calculadora` Calculadora web
- `/pruebas` Generador de solicitudes
- `/monitor` Monitor de una respuesta de `/health` a través del balanceador

## API
- `/api/estado`
- `/api/calcular?a=8&b=2&op=dividir` (también acepta POST JSON)
- `/health`

## Pruebas
```bash
python3 cliente_pruebas.py --url http://127.0.0.1:8080 -n 30
```
Para balanceo ponderado, editar `laboratorio.conf` y agregar `weight=3` a S1 y `weight=1` a S2/S3; copiarlo de nuevo y recargar NGINX. Para fallo, detener una instancia con Ctrl+C y repetir el ensayo. Los primeros intentos pueden fallar mientras NGINX detecta el problema. Reiniciar la instancia al finalizar.

## Limitaciones didácticas
El servidor integrado de Flask es solo para laboratorio, no producción. Las tres réplicas comparten código pero no memoria ni contadores. `/monitor` consulta el servicio a través de NGINX y no ofrece supervisión individual de todas las instancias. No exponer el laboratorio a Internet.
