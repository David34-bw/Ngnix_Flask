import argparse, collections, json, time, urllib.request
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8080');p.add_argument('-n',type=int,default=30);a=p.parse_args()
counts=collections.Counter(); times=[]; errors=[]
for i in range(a.n):
    start=time.perf_counter()
    try:
        with urllib.request.urlopen(a.url.rstrip('/')+'/api/estado?i='+str(i),timeout=5) as r:
            data=json.load(r)
        counts[data['servidor']]+=1;times.append((time.perf_counter()-start)*1000)
    except Exception as exc: errors.append(str(exc))
print('Respuestas por servidor:',dict(counts))
print('Errores:',len(errors))
if times:print('Latencia media (ms):',round(sum(times)/len(times),2),'máxima:',round(max(times),2))
if errors:print('Ejemplos de errores:',errors[:3])
