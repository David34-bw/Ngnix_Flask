# Imagen única para las tres instancias Flask (flask1, flask2, flask3).
# El identificador NO va en la imagen: se entrega al ejecutar con la variable SERVER_ID.

# Imagen oficial de Python, variante slim (Debian mínima): más liviana que la completa
# y, a diferencia de alpine, compatible con las ruedas (wheels) precompiladas de PyPI.
FROM python:3.13-slim

# Sin archivos .pyc y salida sin búfer, para que "docker logs" muestre las líneas al instante
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

WORKDIR /app

# 1) Dependencias primero: esta capa solo se reconstruye si cambia requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2) Código de la aplicación (capa que cambia con más frecuencia)
COPY app.py .

# Usuario sin privilegios: el proceso no corre como root dentro del contenedor
RUN useradd --system --uid 10001 appuser
USER appuser

# Puerto interno (documentación; no lo publica en el anfitrión)
EXPOSE 5000

CMD ["python", "app.py"]
