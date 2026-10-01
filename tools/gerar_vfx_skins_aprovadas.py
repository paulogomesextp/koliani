#!/usr/bin/env python3
"""Efeitos nativos por tema aprovado; camadas separadas dos 84 frames.

Anjo: penas e selo alado. Demonio: brasas e fendas. Abadia: gotas/ondas.
Celestial: estrelas e constelacoes. Nao muda canvases, slots ou duracoes.
"""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFilter

RAIZ = Path(__file__).resolve().parents[1]
GOLD = RAIZ / 'assets/sprites/koliani_golden_set/vfx/vfx_slash_basic'
DEST = RAIZ / 'assets/sprites/koliani_skins'
PERFIS = {
    'anjo': ((244,201,93), (214,245,255), 'penas'),
    'demonio': ((244,91,40), (255,227,160), 'brasas'),
    'abadia_afogada': ((37,186,169), (188,255,244), 'agua'),
    'celestial': ((220,179,80), (255,242,188), 'estrelas'),
}

def motivo(d, x, y, r, alfa, tema, cor, luz):
    c, l = cor+(alfa,), luz+(alfa,)
    if tema == 'penas':
        d.polygon([(x-r,y+r),(x-1,y-r),(x+r,y-r),(x+1,y+1)],fill=c)
        d.line([(x-r,y+r),(x+r,y-r)],fill=l,width=1)
    elif tema == 'brasas':
        d.polygon([(x-r,y+r),(x,y-r-2),(x+r,y+r)],fill=c)
        d.line([(x,y+r),(x,y)],fill=l,width=1)
    elif tema == 'agua':
        d.ellipse([x-r,y-r,x+r,y+r],outline=c,width=1)
        d.arc([x-r,y-r,x+r,y+r],190,290,fill=l,width=1)
    else:
        d.line([(x-r,y),(x+r,y)],fill=c,width=1)
        d.line([(x,y-r),(x,y+r)],fill=l,width=1)
        d.point((x,y),fill=(255,255,240,alfa))

def grava(nome, slot, imagens):
    pasta = DEST/nome/'vfx'/slot
    pasta.mkdir(parents=True,exist_ok=True)
    for i, im in enumerate(imagens,1):
        halo=im.filter(ImageFilter.GaussianBlur(1.2))
        halo.putalpha(halo.getchannel('A').point(lambda a: round(a*0.45)))
        Image.alpha_composite(halo,im).save(pasta/f'{slot}_{i:03d}.png',optimize=True)

def gerar(nome, cor, luz, tema):
    arcos=[]
    for i in range(6):
        im=Image.open(GOLD/f'vfx_slash_basic_{i+1:03d}.png').convert('RGBA')
        px=im.load()
        for y in range(im.height):
            for x in range(im.width):
                r,g,b,a=px[x,y]
                if a:
                    f=min(1.0,(max(r,g,b)+min(r,g,b))/300)
                    px[x,y]=tuple(round(cor[j]*(1-f)+luz[j]*f) for j in range(3))+(a,)
        d=ImageDraw.Draw(im)
        pontos=[]
        for k in range(7):
            ang=-1.2+k*0.38+i*0.14
            raio=min(im.size)*(0.27+i*0.035)
            x,y=round(im.width/2+math.cos(ang)*raio),round(im.height/2+math.sin(ang)*raio)
            pontos.append((x,y))
            motivo(d,x,y,2+k%2,round(230*(1-i/7)),tema,cor,luz)
        if tema in ('estrelas','agua'):
            d.line(pontos,fill=cor+(round(120*(1-i/7)),),width=1)
        arcos.append(im)
    grava(nome,'vfx_slash_basic',arcos)
    for slot,tamanho in [('double_jump_ring',(64,32)),('land_impact',(96,48)),('pogo_impact',(64,64))]:
        imagens=[]
        for i in range(6):
            t=i/5
            im=Image.new('RGBA',tamanho)
            if i==5:
                imagens.append(im)
                continue
            d=ImageDraw.Draw(im)
            w,h=tamanho
            cx,cy=w/2,(h-5 if slot=='land_impact' else h/2)
            rx=6+(w/2-10)*t
            ry=(3+8*t if slot=='double_jump_ring' else (2+3*t if slot=='land_impact' else rx))
            a=round(255*(1-t)**0.8)
            d.ellipse([cx-rx,cy-ry,cx+rx,cy+ry],outline=cor+(a,),width=2)
            d.arc([cx-rx+2,cy-ry+1,cx+rx-2,cy+ry-1],180,350,fill=luz+(a,),width=1)
            pontos=[]
            for k in range(6):
                ang=k*math.tau/6
                x=round(cx+math.cos(ang)*rx)
                y=round(cy+math.sin(ang)*ry-(t*18 if slot=='land_impact' else 0))
                pontos.append((x,y))
                motivo(d,x,y,3,a,tema,cor,luz)
            if tema=='estrelas':
                d.line(pontos,fill=cor+(a//2,),width=1)
            elif tema=='brasas' and slot=='land_impact':
                for k in range(5):
                    x=round(cx+(k-2)*(6+t*8))
                    d.line([(x,cy),(x+2,cy-4-t*18)],fill=cor+(a,),width=2)
            imagens.append(im)
        grava(nome,slot,imagens)
    imagens=[]
    for i in range(4):
        im=Image.new('RGBA',(12,12))
        motivo(ImageDraw.Draw(im),6,6,4-i,255-i*40,tema,cor,luz)
        imagens.append(im)
    grava(nome,'particulas',imagens)
    # Preview e um frame real do traje, com efeito separado na mesma posicao.
    corpo=Image.open(DEST/nome/'frames/attack_basic/attack_basic_003.png').convert('RGBA')
    tela=Image.new('RGBA',(160,160))
    tela.alpha_composite(arcos[4],(32,-14))
    tela.alpha_composite(corpo,(16,16))
    bb=tela.getbbox()
    lado=max(bb[2]-bb[0],bb[3]-bb[1])+16
    cx,cy=(bb[0]+bb[2])//2,(bb[1]+bb[3])//2
    tela.crop((cx-lado//2,cy-lado//2,cx-lado//2+lado,cy-lado//2+lado)).save(DEST/nome/'preview.png',optimize=True)
    print(nome, ': 28 frames VFX + preview gerados')

if __name__=='__main__':
    for nome,(cor,luz,tema) in PERFIS.items():
        gerar(nome,cor,luz,tema)
