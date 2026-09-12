"""Deriva o primeiro passe L1 da autoridade aprovada; não inventa resolução nativa."""
from pathlib import Path
from collections import deque
import json
import shutil
import hashlib
from PIL import Image, ImageFilter
from gerar_terreno_hd_regiao1 import costurar_x, costurar_y

RAIZ = Path(__file__).resolve().parents[1]
KIT = RAIZ / 'assets/art/regions/region_01_forest/production/l1_hybrid_9h12e'
WORK = RAIZ / 'work/production_art_gate/9H12E_astra_production'
FONTE = KIT / '_source/authority.png'
im = Image.open(FONTE).convert('RGBA')
registos = []

def recortar(caixa, alfa=False):
    p = im.crop(caixa)
    if not alfa:
        return p
    # Retira apenas o fundo carvão ligado à borda; preserva interiores escuros.
    w, h = p.size
    px = p.load()
    vistos = set()
    fila = deque([(x, y) for x in range(w) for y in (0, h-1)] +
                 [(x, y) for y in range(h) for x in (0, w-1)])
    while fila:
        x, y = fila.popleft()
        if (x, y) in vistos or not (0 <= x < w and 0 <= y < h):
            continue
        vistos.add((x, y))
        r, g, b, a = px[x, y]
        if max(abs(r-26), abs(g-29), abs(b-36)) > 18:
            continue
        px[x, y] = (r, g, b, 0)
        fila.extend(((x-1,y), (x+1,y), (x,y-1), (x,y+1)))
    return p

def guardar(p, pasta, nome, caixa=None):
    for base in (KIT, WORK):
        (base/pasta).mkdir(parents=True, exist_ok=True)
        p.save(base/pasta/(nome+'.png'))
    registos.append(dict(ficheiro=f'{pasta}/{nome}.png', tamanho=p.size, recorte=caixa))
    return p

props = {
    'arco': (578,389,712,569), 'arco_partido': (710,389,916,569),
    'arvore': (8,390,273,570), 'floresta': (275,390,575,570),
    'cascata': (900,389,1200,570), 'torres': (1205,389,1528,570),
    'vinhas': (9,584,98,710), 'raizes': (104,584,278,710),
    'lanterna': (399,584,448,710), 'cristais': (723,584,937,710),
    'ramos': (1130,584,1527,710),
}
pecas = {n: guardar(recortar(c, True), 'props_hd', n, c) for n,c in props.items()}
pan = recortar((780,5,1528,375))
guardar(pan, 'source_clean', 'panorama', (780,5,1528,375))
guardar(pan.resize((1920,950), Image.Resampling.LANCZOS), 'layers', '01_far_sky_castle')
for nome, itens in [
    ('02_mid_mountains_waterfalls', [('cascata',160,250,2.2),('torres',1070,270,2.0)]),
    ('03_forest_silhouette', [('floresta',0,230,2.7),('arvore',1250,210,2.5)]),
    ('04_ruins_arches', [('arco',190,160,2.5),('arco_partido',1230,180,2.4)]),
    ('05_foreground_branches_vines', [('vinhas',0,0,2.0),('ramos',1120,0,2.0)])]:
    tela = Image.new('RGBA',(1920,950))
    for p,x,y,e in itens:
        a = pecas[p]
        a = a.resize((int(a.width*e),int(a.height*e)),Image.Resampling.LANCZOS)
        tela.alpha_composite(a,(x,y))
    guardar(tela,'layers',nome)

for nome,c in {'plataforma':(10,727,300,1002),'rocha':(318,743,438,988),
               'raizes':(451,727,632,1004),'ruina':(644,727,827,1004),
               'corrupcao':(839,727,1046,1005)}.items():
    guardar(recortar(c,True),'terrain_hd',nome,c)
# Materiais contínuos para o renderizador atual: superfícies e volumes inalterados.
corpo = recortar((480,808,580,942)).resize((432,432),Image.Resampling.LANCZOS)
guardar(costurar_y(costurar_x(corpo,48),48),'terrain_hd','corpo')
topo = recortar((23,755,275,797)).resize((576,56),Image.Resampling.LANCZOS)
guardar(costurar_x(topo,64),'terrain_hd','topo')
guardar(recortar((1060,778,1310,872)),'props_hd','liquido')
folha = Image.new('RGB',(1200,900),(23,25,33))
for i,r in enumerate(registos):
    p = Image.open(KIT/r['ficheiro']).convert('RGBA')
    p.thumbnail((230,150),Image.Resampling.LANCZOS)
    folha.paste(p,((i%5)*240,(i//5)*150),p)
guardar(folha,'preview','contact_sheet')
manifesto = dict(execucao='9H.12D/E L1', origem=r'C:\Users\paulo\Pictures\Imagem Codex 12_09_2026, 20_36_00.png',
    sha256=hashlib.sha256(FONTE.read_bytes()).hexdigest(), fonte_px=im.size,
    direitos='Imagem original gerada por IA nesta tarefa e aprovada pelo utilizador; sem assets externos. Não se afirma licença CC0.',
    limites='Primeiro passe derivado: camadas ampliadas de recortes, não arte nativa 1920. Fundo base composto; máscaras por conectividade exigem revisão humana.',
    ativos=registos)
for base in (KIT,WORK):
    (base/'manifests').mkdir(exist_ok=True)
    (base/'manifests/manifest.json').write_text(json.dumps(manifesto,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Produzidos {len(registos)} assets; fonte {im.size}, original preservado.')
