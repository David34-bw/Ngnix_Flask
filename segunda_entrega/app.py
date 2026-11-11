import argparse, os, time, threading
from flask import Flask, jsonify, request, render_template_string

parser=argparse.ArgumentParser()
parser.add_argument('--id',default=os.getenv('SERVER_ID','S1'))
parser.add_argument('--port',type=int,default=5001)
args=parser.parse_args()
app=Flask(__name__)
started=time.time(); count=0; lock=threading.Lock()
HTML='''<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Laboratorio NGINX + Flask</title><style>body{font-family:system-ui,sans-serif;max-width:950px;margin:35px auto;padding:0 16px;background:#f5f7fb;color:#172334}nav a{margin-right:18px}main{background:white;padding:24px;border-radius:12px;box-shadow:0 2px 10px #0001}input,select,button{padding:9px;margin:5px}button{background:#1261a0;color:white;border:0;border-radius:5px;cursor:pointer}pre{background:#eef2f8;padding:12px;overflow:auto}table{border-collapse:collapse;width:100%}td,th{padding:8px;border:1px solid #ddd}small{color:#566}</style></head><body><h1>Laboratorio de infraestructura web</h1><nav><a href="/">Inicio</a><a href="/calculadora">Calculadora</a><a href="/pruebas">Generador de solicitudes</a><a href="/monitor">Monitor</a></nav><main><h2>{{ title }}</h2>{{ content|safe }}</main><p><small>La interfaz puede llegar desde cualquier réplica; cada consulta API informa cuál la atendió.</small></p><script>{{ js|safe }}</script></body></html>'''

def page(title,content,js=''):
    return render_template_string(HTML,title=title,content=content,js=js)

def info():
    global count
    with lock:
        count+=1; n=count
    return {'servidor':args.id,'puerto':args.port,'solicitudes_locales':n,'uptime_segundos':round(time.time()-started,2),'timestamp':round(time.time(),3)}

@app.after_request
def headers(resp):
    resp.headers['Cache-Control']='no-store'
    resp.headers['X-Servidor-Flask']=args.id
    return resp

@app.get('/')
def index():
    return page('Inicio','<p>Esta aplicación se ejecuta en tres instancias Flask detrás de NGINX.</p><button onclick="estado()">Consultar instancia</button><pre id="out">Pulsa el botón.</pre>', '''async function estado(){let r=await fetch('/api/estado',{cache:'no-store'});document.getElementById('out').textContent=JSON.stringify(await r.json(),null,2)} estado();''')

@app.get('/api/estado')
def estado():return jsonify(info())

@app.get('/health')
def health():return jsonify({'status':'ok',**info()})

@app.route('/api/calcular',methods=['GET','POST'])
def calcular():
    data=request.get_json(silent=True) if request.method=='POST' else request.args
    data=data or {}
    try:
        a=float(data.get('a')); b=float(data.get('b')); op=data.get('op','sumar')
        ops={'sumar':lambda:a+b,'restar':lambda:a-b,'multiplicar':lambda:a*b,'dividir':lambda:a/b}
        if op not in ops: return jsonify(error='Operación desconocida'),400
        if op=='dividir' and b==0:return jsonify(error='División por cero'),400
        return jsonify({'resultado':ops[op](),'operacion':op,**info()})
    except (ValueError,TypeError):return jsonify(error='Se requieren números válidos'),400

@app.get('/calculadora')
def calculadora():
    html='''<input id="a" type="number" value="8" step="any"><select id="op"><option value="sumar">+</option><option value="restar">−</option><option value="multiplicar">×</option><option value="dividir">÷</option></select><input id="b" type="number" value="2" step="any"><button onclick="calc()">Calcular</button><pre id="out"></pre>'''
    js='''async function calc(){let p=new URLSearchParams({a:document.getElementById('a').value,b:document.getElementById('b').value,op:document.getElementById('op').value});let r=await fetch('/api/calcular?'+p,{cache:'no-store'});document.getElementById('out').textContent=JSON.stringify(await r.json(),null,2)}'''
    return page('Calculadora distribuida',html,js)

@app.get('/pruebas')
def pruebas():
    html='''<p>Envía solicitudes secuenciales y observa la distribución real entre instancias.</p><label>Cantidad <input id="n" type="number" min="1" max="300" value="30"></label><button id="run" onclick="probar()">Ejecutar prueba</button><pre id="out">Sin resultados</pre>'''
    js='''async function probar(){let n=Math.max(1,Math.min(300,Number(document.getElementById('n').value)||30));let btn=document.getElementById('run');btn.disabled=true;let conteo={},errores=0,latencias=[];for(let i=0;i<n;i++){let t=performance.now();try{let r=await fetch('/api/estado?test='+i+'&nonce='+Date.now(),{cache:'no-store'});if(!r.ok)throw Error(r.status);let j=await r.json();conteo[j.servidor]=(conteo[j.servidor]||0)+1;latencias.push(performance.now()-t)}catch(e){errores++}document.getElementById('out').textContent=JSON.stringify({progreso:i+1,total:n,conteo,errores},null,2)}document.getElementById('out').textContent=JSON.stringify({total:n,conteo,errores,latencia_media_ms:latencias.length?Math.round(latencias.reduce((a,b)=>a+b,0)/latencias.length*100)/100:null,latencia_maxima_ms:latencias.length?Math.round(Math.max(...latencias)*100)/100:null},null,2);btn.disabled=false}'''
    return page('Generador de solicitudes',html,js)

@app.get('/monitor')
def monitor():
    html='''<p>Este monitor consulta el balanceador, <strong>no</strong> comprueba individualmente las tres réplicas.</p><button onclick="check()">Consultar /health</button><pre id="out"></pre>'''
    js='''async function check(){let t=performance.now();try{let r=await fetch('/health',{cache:'no-store'});document.getElementById('out').textContent=JSON.stringify({http:r.status,latencia_ms:Math.round((performance.now()-t)*100)/100,respuesta:await r.json()},null,2)}catch(e){document.getElementById('out').textContent='Error: '+e}} check();'''
    return page('Monitor de disponibilidad',html,js)

if __name__=='__main__':
    app.run(host='127.0.0.1',port=args.port,debug=False,threaded=True)
