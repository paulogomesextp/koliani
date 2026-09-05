#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Escreve os textos do TUTORIAL DE MECANICA nos 6 `assets/i18n/*.json`.

O Paulo pediu (5 set 2026): "quando uma mecanica aparece pela primeira vez,
aparece uma mensagem a dizer como funciona, fica 5 segundos e desaparece".

Cada camara do `gerador_corredor.gd` tem duas chaves:

    mec.<cam>.nome   o nome da mecanica (2-3 palavras, cabe numa linha)
    mec.<cam>.txt    COMO funciona, numa frase -- le-se de relance, a jogar

A tabela vive AQUI e nao nos JSON porque sao 94 mecanicas x 6 idiomas: a
mao, num JSON de cada vez, uma entrada acabava sempre por faltar num
idioma (e ha' um teste que exige as mesmas chaves nos seis). Correr:

    python tools/gerar_textos_mecanicas.py

O `en.json` continua a ser a fonte de verdade: e' a primeira coluna.
"""

import json
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
I18N = os.path.join(RAIZ, "assets", "i18n")
IDIOMAS = ["en", "pt", "es", "fr", "de", "zh"]

# cam -> (nome, texto) por idioma, pela ordem de IDIOMAS.
MEC = {}


def m(cam, *seis):
    """Uma mecanica: seis pares (nome, texto), na ordem de IDIOMAS."""
    assert len(seis) == 6, cam
    MEC[cam] = dict(zip(IDIOMAS, seis))


# --- Regiao I-II: niveis 1-10 ----------------------------------------
m("saltos",
  ("Zigzag Leaps", "Platforms climb in tight zigzags. Chain the jumps and use the double jump to save a bad one."),
  ("Saltos em Ziguezague", "As plataformas sobem em ziguezague apertado. Encadeia os saltos e usa o duplo para salvar um mau."),
  ("Saltos en Zigzag", "Las plataformas suben en zigzag cerrado. Encadena los saltos y usa el doble para salvar uno malo."),
  ("Sauts en Zigzag", "Les plates-formes montent en zigzag serré. Enchaîne les sauts et garde le double pour te rattraper."),
  ("Zickzack-Sprünge", "Die Plattformen steigen im engen Zickzack. Verkette die Sprünge; der Doppelsprung rettet den schlechten."),
  ("之字跳跃", "平台以密集的之字形上升。连续起跳，用二段跳补救失误。"))

m("gruta",
  ("Low Cave", "The ceiling drops: go down into the tunnel and back up. Stalactites fall — keep moving."),
  ("Gruta Apertada", "O tecto baixa: desce ao túnel e volta a subir. Caem estalactites — não pares."),
  ("Cueva Baja", "El techo baja: desciende al túnel y vuelve a subir. Caen estalactitas: no te pares."),
  ("Grotte Basse", "Le plafond descend : passe par le tunnel et remonte. Des stalactites tombent — ne t'arrête pas."),
  ("Enge Höhle", "Die Decke sinkt: geh in den Tunnel hinab und wieder hoch. Stalaktiten fallen — bleib in Bewegung."),
  ("低矮洞窟", "顶板压低：下到隧道再爬上来。钟乳石会坠落——别停下。"))

m("trampolim",
  ("Springboards", "Bounce pads throw you about one and a half double jumps high. Aim before you land on them."),
  ("Trampolins", "Os trampolins atiram-te cerca de um salto duplo e meio. Aponta antes de lhes cair em cima."),
  ("Trampolines", "Los trampolines te lanzan un salto doble y medio. Apunta antes de caer sobre ellos."),
  ("Tremplins", "Les tremplins t'envoient à un saut double et demi. Vise avant d'atterrir dessus."),
  ("Sprungbretter", "Die Sprungbretter werfen dich anderthalb Doppelsprünge hoch. Ziele, bevor du landest."),
  ("弹跳板", "弹板把你抛起约一次半的二段跳高度。落上去之前先瞄准。"))

m("espinhos",
  ("Spikes Below", "The low lane is a spike bed you can pogo across; the high lane is the safe, tighter route."),
  ("Espinhos em Baixo", "A calha baixa é um tapete de espinhos que se atravessa aos ressaltos; a alta é o caminho seguro."),
  ("Pinchos Abajo", "El carril bajo es un lecho de pinchos que se cruza a rebotes; el alto es la ruta segura."),
  ("Piques en Bas", "La voie basse est un lit de piques à franchir en rebonds ; la haute est la route sûre."),
  ("Stacheln Unten", "Die untere Bahn ist ein Stachelbett zum Abprallen; die obere ist der sichere Weg."),
  ("下方尖刺", "低路是可踩踏弹跳的尖刺地；高路更窄但安全。"))

m("ritmo",
  ("Timed Platforms", "These platforms appear and vanish on a beat. Read the rhythm and cross without stopping."),
  ("Plataformas Rítmicas", "Estas plataformas aparecem e somem ao compasso. Lê o ritmo e atravessa sem parar."),
  ("Plataformas Rítmicas", "Estas plataformas aparecen y desaparecen a compás. Lee el ritmo y cruza sin pararte."),
  ("Plates-formes Rythmées", "Ces plates-formes apparaissent et disparaissent en mesure. Lis le rythme et traverse sans t'arrêter."),
  ("Taktplattformen", "Diese Plattformen erscheinen und verschwinden im Takt. Lies den Rhythmus und geh ohne Halt durch."),
  ("节奏平台", "这些平台按节拍出现又消失。读准节奏，不要停。"))

m("alavanca",
  ("Lever and Gate", "A gate blocks the hall. Hit the lever on the perch to open it — once open, it stays open."),
  ("Alavanca e Grade", "Uma grade tranca o átrio. Bate na alavanca do poleiro para a abrir — depois fica aberta."),
  ("Palanca y Reja", "Una reja cierra el atrio. Golpea la palanca del saliente para abrirla; luego queda abierta."),
  ("Levier et Grille", "Une grille barre la salle. Frappe le levier sur le perchoir — une fois ouverte, elle le reste."),
  ("Hebel und Gitter", "Ein Gitter sperrt die Halle. Schlag den Hebel auf dem Sims — einmal offen, bleibt es offen."),
  ("拉杆与闸门", "闸门封住通道。击打高台上的拉杆开启——开了就不会再关。"))

m("fogo",
  ("Fire Jets", "Jets burst from the floor on a fixed cycle. Cross in the gap, not on the flame."),
  ("Jactos de Fogo", "Os jactos irrompem do chão em ciclo fixo. Passa no intervalo, não em cima da chama."),
  ("Chorros de Fuego", "Los chorros brotan del suelo en ciclo fijo. Cruza en el hueco, no sobre la llama."),
  ("Jets de Feu", "Les jets jaillissent du sol à cycle fixe. Passe dans l'intervalle, pas sur la flamme."),
  ("Feuerdüsen", "Die Düsen brechen im festen Takt aus dem Boden. Geh in der Lücke, nicht auf der Flamme."),
  ("烈焰喷口", "火焰按固定周期从地面喷出。在间隙通过，别踩在火上。"))

m("guilhotinas",
  ("Guillotines", "Blades drop on a fixed beat and pull back slowly. Wait for the lift, then run under."),
  ("Guilhotinas", "As lâminas caem em compasso fixo e sobem devagar. Espera pela subida e passa por baixo."),
  ("Guillotinas", "Las hojas caen a compás fijo y suben despacio. Espera la subida y pasa por debajo."),
  ("Guillotines", "Les lames tombent à intervalle fixe et remontent lentement. Attends la remontée et passe."),
  ("Fallbeile", "Die Klingen fallen im festen Takt und heben sich langsam. Warte aufs Heben und lauf durch."),
  ("铡刀", "刀刃按固定节拍落下，缓慢回升。等它抬起再冲过去。"))

m("arena",
  ("Clear the Room", "Solid ground over the void and enemies on it. Nothing moves on until the room is clear."),
  ("Limpa a Sala", "Chão sólido por cima do vazio e inimigos em cima dele. Nada avança até a sala ficar limpa."),
  ("Limpia la Sala", "Suelo sólido sobre el vacío y enemigos encima. Nada avanza hasta limpiar la sala."),
  ("Nettoie la Salle", "Sol solide au-dessus du vide et des ennemis dessus. Rien n'avance tant que la salle n'est pas nette."),
  ("Räum den Raum", "Fester Boden über der Leere, Feinde darauf. Nichts geht weiter, bis der Raum leer ist."),
  ("清场", "深渊之上是坚实地面，敌人在上面。清空之前无法前进。"))

m("prensa",
  ("Sliding Presses", "Walls sweep the hall out of phase. There is no ceiling — wait for the gap or jump the wall."),
  ("Prensas", "Paredes varrem o salão desfasadas. Não há tecto — espera o buraco ou salta a parede."),
  ("Prensas", "Muros barren la sala desfasados. No hay techo: espera el hueco o salta el muro."),
  ("Presses Coulissantes", "Des murs balaient la salle en décalé. Pas de plafond — attends le trou ou saute le mur."),
  ("Schiebepressen", "Wände fegen versetzt durch den Saal. Es gibt keine Decke — warte auf die Lücke oder spring."),
  ("推压墙", "墙体错位地横扫大厅。没有天花板——等空隙或直接跳过去。"))


# --- Regiao III-IV: niveis 11-20 -------------------------------------
m("sinos",
  ("Ring the Bell", "The bridge is a ghost until you strike the bell. Hit it as often as you need."),
  ("Toca o Sino", "A ponte está fantasma até bateres no sino. Toca-lhe as vezes que forem precisas."),
  ("Toca la Campana", "El puente es fantasma hasta que golpeas la campana. Tócala las veces que haga falta."),
  ("Sonne la Cloche", "Le pont est fantôme tant que la cloche n'a pas sonné. Frappe-la autant que nécessaire."),
  ("Läute die Glocke", "Die Brücke ist ein Geist, bis du die Glocke schlägst. Schlag sie, so oft du willst."),
  ("敲钟", "桥是虚影，直到你敲响钟。需要几次就敲几次。"))

m("vento",
  ("Updraft", "A column of rising air lifts you far past a normal jump. Enter it and steer."),
  ("Corrente de Ar", "Uma coluna de ar a subir leva-te muito acima de um salto normal. Entra nela e conduz."),
  ("Corriente de Aire", "Una columna de aire ascendente te eleva mucho más que un salto. Entra y dirige."),
  ("Courant Ascendant", "Une colonne d'air t'élève bien au-delà d'un saut. Entre dedans et dirige-toi."),
  ("Aufwind", "Eine aufsteigende Luftsäule trägt dich weit über einen Sprung hinaus. Steig ein und steuere."),
  ("上升气流", "上升气柱能把你送得远高于普通跳跃。进入并控制方向。"))

m("serras",
  ("Saw Rails", "Saws run along rails above and below the platforms. Jump on their beat."),
  ("Serras em Calha", "As serras correm em calhas por cima e por baixo das plataformas. Salta no ritmo delas."),
  ("Sierras en Riel", "Las sierras corren por raíles arriba y abajo de las plataformas. Salta a su ritmo."),
  ("Scies sur Rails", "Les scies filent sur des rails au-dessus et en dessous. Saute à leur rythme."),
  ("Sägen auf Schienen", "Sägen laufen auf Schienen über und unter den Plattformen. Spring in ihrem Takt."),
  ("轨道锯", "锯片沿着平台上下的轨道往返。踩着它们的节奏跳。"))

m("gravidade",
  ("Gravity Zone", "Inside this field you weigh less: jumps go higher and falls take longer."),
  ("Zona de Gravidade", "Dentro deste campo pesas menos: os saltos vão mais alto e as quedas demoram mais."),
  ("Zona de Gravedad", "Dentro de este campo pesas menos: saltas más alto y caes más despacio."),
  ("Zone de Gravité", "Dans ce champ tu pèses moins : tu sautes plus haut et tu tombes plus lentement."),
  ("Gravitationszone", "In diesem Feld wiegst du weniger: höhere Sprünge, längere Fallzeit."),
  ("重力区", "在这个力场里你更轻：跳得更高，落得更慢。"))

m("torre",
  ("The Tower", "A tight zigzag climb that gains a lot of height. Every step is within one jump."),
  ("A Torre", "Uma subida em ziguezague apertado que ganha muita altura. Cada degrau cabe num salto."),
  ("La Torre", "Una subida en zigzag cerrado que gana mucha altura. Cada escalón cabe en un salto."),
  ("La Tour", "Une montée en zigzag serré qui prend beaucoup de hauteur. Chaque palier tient en un saut."),
  ("Der Turm", "Ein enger Zickzack-Aufstieg mit viel Höhengewinn. Jede Stufe liegt in Sprungweite."),
  ("高塔", "密集之字形的攀升，落差很大。每一级都在一跳之内。"))

m("elevador",
  ("Tomb Lifts", "Slabs ride up and down on their own. Board them and step off at the top."),
  ("Túmulos-Elevador", "As lajes sobem e descem sozinhas. Sobe para cima delas e sai lá em cima."),
  ("Tumbas-Ascensor", "Las losas suben y bajan solas. Súbete y baja arriba del todo."),
  ("Tombes-Ascenseurs", "Les dalles montent et descendent seules. Monte dessus et sors en haut."),
  ("Grab-Aufzüge", "Die Platten fahren von selbst auf und ab. Steig auf und oben wieder ab."),
  ("升降石棺", "石板自行上下往复。踏上去，到顶再下来。"))

m("quebra",
  ("Crumbling Floor", "These platforms fall a moment after you touch them. Never stand still."),
  ("Chão que Desaba", "Estas plataformas caem pouco depois de as pisares. Nunca fiques parada."),
  ("Suelo que Cede", "Estas plataformas caen poco después de pisarlas. Nunca te quedes quieta."),
  ("Sol qui S'effondre", "Ces plates-formes tombent peu après ton passage. Ne t'arrête jamais."),
  ("Bröckelnder Boden", "Diese Plattformen fallen kurz nach dem Betreten. Bleib niemals stehen."),
  ("崩塌地板", "踩上后不久平台就会坠落。绝对不要停留。"))

m("velas",
  ("Light the Candle", "The bridge is only solid while a candle burns near it. Touch a dead candle to light it."),
  ("Acende a Vela", "A ponte só é sólida enquanto houver uma vela acesa perto. Toca numa apagada para a acender."),
  ("Enciende la Vela", "El puente solo es sólido mientras arda una vela cerca. Toca una apagada para encenderla."),
  ("Allume la Bougie", "Le pont n'est solide que si une bougie brûle près. Touche une bougie éteinte pour l'allumer."),
  ("Zünde die Kerze an", "Die Brücke ist nur fest, solange eine Kerze brennt. Berühre eine erloschene, um sie zu entzünden."),
  ("点亮蜡烛", "只有附近有蜡烛燃烧，桥才是实体。触碰熄灭的烛把它点亮。"))

m("pedras",
  ("Falling Rocks", "Rocks drop from the ledge above — some when you get close, some on a cycle. Watch what shakes."),
  ("Pedras a Cair", "Caem pedras do beiral — umas por te aproximares, outras em ciclo. Repara nas que tremem."),
  ("Rocas que Caen", "Caen rocas desde arriba: unas al acercarte, otras en ciclo. Fíjate en las que tiemblan."),
  ("Chutes de Pierres", "Des pierres tombent d'en haut : certaines à ton approche, d'autres en cycle. Repère celles qui tremblent."),
  ("Steinschlag", "Steine fallen vom Sims — manche bei Annäherung, manche im Takt. Achte auf die, die zittern."),
  ("落石", "岩石从上方坠落——有的因你靠近，有的按周期。注意那些在颤动的。"))

m("poco",
  ("The Pit", "A funnel down to the deadly liquid and back up the far wall. Descend hugging the walls."),
  ("O Poço", "Um funil até rente ao líquido mortal e a subida pela parede oposta. Desce agarrada às paredes."),
  ("El Pozo", "Un embudo hasta el líquido mortal y subida por la pared opuesta. Baja pegada a los muros."),
  ("Le Puits", "Un entonnoir jusqu'au liquide mortel, puis remontée par la paroi opposée. Descends contre les murs."),
  ("Der Schacht", "Ein Trichter bis knapp über die tödliche Flüssigkeit und an der Gegenwand hinauf. Halte dich an den Wänden."),
  ("竖井", "漏斗状下降至致命液面，再从对面墙攀上。贴着墙壁下行。"))


# --- Regiao V-VI: niveis 21-30 ---------------------------------------
m("cripta",
  ("The Crypt", "A closed room with an inner wall to clear and rocks coming down. Short vertical work."),
  ("A Cripta", "Sala fechada com uma parede interior para transpor e pedras a cair. Navegação vertical curta."),
  ("La Cripta", "Sala cerrada con un muro interior que salvar y rocas cayendo. Navegación vertical corta."),
  ("La Crypte", "Salle close avec un mur intérieur à franchir et des pierres qui tombent. Verticalité brève."),
  ("Die Krypta", "Geschlossener Raum mit Innenmauer und fallenden Steinen. Kurze Vertikalarbeit."),
  ("地穴", "封闭房间，内墙需翻越，还有落石。短促的纵向机动。"))

m("pendulos",
  ("Blade Pendulums", "Hanging blades swing across the platforms, each out of phase. Cross one swing at a time."),
  ("Pêndulos de Lâmina", "Lâminas penduradas balançam sobre as plataformas, cada uma desfasada. Passa uma de cada vez."),
  ("Péndulos de Hoja", "Hojas colgantes oscilan sobre las plataformas, desfasadas. Pasa de una en una."),
  ("Pendules à Lame", "Des lames suspendues balaient les plates-formes, en décalé. Franchis-les une par une."),
  ("Klingenpendel", "Hängende Klingen schwingen versetzt über die Plattformen. Nimm eine nach der anderen."),
  ("摆刀", "悬挂的刀刃在平台上摆动，彼此错开。一次过一个。"))

m("ferry",
  ("The Ferry", "One platform crosses the gap back and forth. Ride it standing and dodge the hanging blades."),
  ("A Balsa", "Uma plataforma atravessa o fosso de um lado ao outro. Viaja em pé e desvia das lâminas."),
  ("La Balsa", "Una plataforma cruza el foso de lado a lado. Viaja de pie y esquiva las hojas colgantes."),
  ("Le Bac", "Une plate-forme fait la navette au-dessus du gouffre. Voyage debout et esquive les lames."),
  ("Die Fähre", "Eine Plattform pendelt über die Kluft. Fahr im Stehen und weiche den Klingen aus."),
  ("渡台", "一块平台在深沟上来回摆渡。站着通过，躲开悬刀。"))

m("segredo",
  ("Cracked Wall", "A sealed alcove holds essence. Only Wall Breaking opens it — it is reward, never the path."),
  ("Parede Rachada", "Uma alcova selada guarda essência. Só se abre a partir paredes — é prémio, nunca o caminho."),
  ("Muro Agrietado", "Una alcoba sellada guarda esencia. Solo se abre rompiendo muros: es premio, no el camino."),
  ("Mur Fissuré", "Une alcôve scellée cache de l'essence. Seul le brise-mur l'ouvre — c'est un bonus, pas la voie."),
  ("Rissige Wand", "Eine versiegelte Nische birgt Essenz. Nur Mauerbrechen öffnet sie — Belohnung, nie der Weg."),
  ("裂墙", "密封壁龛里藏着精华。只有破墙能打开——那是奖励，不是必经之路。"))

m("pilares",
  ("Pillar Tops", "Jump from pillar top to pillar top with the void below. Only the caps are solid."),
  ("Topos dos Pilares", "Salta de topo em topo com o vazio lá em baixo. Só os cimos são sólidos."),
  ("Cimas de Pilares", "Salta de cima en cima con el vacío debajo. Solo las cúspides son sólidas."),
  ("Sommets de Piliers", "Saute de sommet en sommet, le vide en dessous. Seules les cimes sont solides."),
  ("Säulenköpfe", "Spring von Säulenkopf zu Säulenkopf über der Leere. Nur die Kappen tragen."),
  ("柱顶", "在虚空之上从柱顶跳到柱顶。只有顶盖是实体。"))

m("crossfire",
  ("Crossfire", "Turrets on both sides fire straight through the path at alternating heights. Move between shots."),
  ("Fogo Cruzado", "Torretas dos dois lados cospem fogo através do caminho, a alturas alternadas. Passa no intervalo."),
  ("Fuego Cruzado", "Torretas a ambos lados disparan a través del camino, a alturas alternas. Pasa entre disparos."),
  ("Feu Croisé", "Des tourelles des deux côtés tirent en travers du chemin, à hauteurs alternées. Passe entre les tirs."),
  ("Kreuzfeuer", "Türme auf beiden Seiten feuern quer über den Weg, abwechselnd hoch und tief. Geh zwischen den Schüssen."),
  ("交叉火力", "两侧炮塔交替高低横穿路径开火。在射击间隙通过。"))

m("espelhos",
  ("Mirrors", "Tall mirrors block the way. One hit breaks each — and each releases a reflection to fight."),
  ("Espelhos", "Espelhos altos tapam o corredor. Um golpe parte cada um — e larga um reflexo para combater."),
  ("Espejos", "Espejos altos cierran el paso. Un golpe rompe cada uno y suelta un reflejo que combatir."),
  ("Miroirs", "De hauts miroirs bloquent le passage. Un coup les brise — et libère un reflet à combattre."),
  ("Spiegel", "Hohe Spiegel versperren den Gang. Ein Schlag zerbricht jeden — und lässt ein Spiegelbild frei."),
  ("镜墙", "高镜阻断走廊。一击即碎——每面都会放出一个倒影与你交手。"))

m("forquilha",
  ("The Fork", "The path splits and rejoins. The high route is short and dangerous, the low one long and safe."),
  ("A Forquilha", "O caminho abre em dois e volta a juntar-se. A rota alta é curta e perigosa; a baixa, longa e segura."),
  ("La Bifurcación", "El camino se abre y se junta. La ruta alta es corta y peligrosa; la baja, larga y segura."),
  ("La Fourche", "Le chemin se sépare puis se rejoint. La voie haute est courte et risquée, la basse longue et sûre."),
  ("Die Gabelung", "Der Weg teilt sich und trifft sich wieder. Oben kurz und gefährlich, unten lang und sicher."),
  ("岔路", "道路分叉后再合并。上路短而危险，下路长而安全。"))

m("impulso",
  ("Wind Blast", "A horizontal blast shoves you forward. Use the islets inside it to keep control."),
  ("Rajada", "Uma rajada horizontal empurra-te para a frente. Usa as ilhotas lá dentro para não perderes o controlo."),
  ("Ráfaga", "Una ráfaga horizontal te empuja hacia delante. Usa los islotes de dentro para no perder el control."),
  ("Bourrasque", "Une bourrasque horizontale te pousse en avant. Sers-toi des îlots pour garder le contrôle."),
  ("Windstoß", "Ein waagerechter Stoß schiebt dich vorwärts. Nutz die Inselchen darin für die Kontrolle."),
  ("疾风推力", "水平气流把你向前推。利用其中的小岛保持控制。"))

m("portal",
  ("Portals", "Step into one and come out the other. There is also a platform route — pick either."),
  ("Portais", "Entra num e sais no outro. Também há um caminho de plataformas — escolhe."),
  ("Portales", "Entra en uno y sales por el otro. También hay ruta de plataformas: elige."),
  ("Portails", "Entre dans l'un, ressors par l'autre. Une route de plates-formes existe aussi — au choix."),
  ("Portale", "Geh in eines hinein und komm aus dem anderen. Es gibt auch einen Plattformweg — wähle."),
  ("传送门", "从一端进入，从另一端出来。也有平台路线——任你选择。"))


# --- Regiao VII-VIII: niveis 31-40 -----------------------------------
m("correntes",
  ("Chained Platforms", "Platforms hang on chains: some swing, some ride up and down. Time your step."),
  ("Plataformas em Corrente", "Plataformas penduradas por correntes: umas balançam, outras sobem e descem. Mede o passo."),
  ("Plataformas Encadenadas", "Plataformas colgadas de cadenas: unas oscilan, otras suben y bajan. Mide el paso."),
  ("Plates-formes Enchaînées", "Des plates-formes pendent à des chaînes : les unes oscillent, les autres montent. Choisis ton instant."),
  ("Kettenplattformen", "Plattformen hängen an Ketten: manche schwingen, manche fahren auf und ab. Timing zählt."),
  ("锁链平台", "平台由锁链吊着：有的摆动，有的升降。算准落脚时机。"))

m("corredor",
  ("Tight Corridor", "The ceiling is low — a jump means a bumped head — and saws run the rails. Run or roll."),
  ("Corredor Apertado", "O tecto é baixo — saltar é bater com a cabeça — e há serras na calha. Corre ou rola."),
  ("Pasillo Estrecho", "El techo es bajo (saltar es golpearse) y hay sierras en el riel. Corre o rueda."),
  ("Couloir Étroit", "Le plafond est bas — sauter, c'est se cogner — et des scies filent. Cours ou roule."),
  ("Enger Gang", "Die Decke ist niedrig — Springen heißt Anstoßen — und Sägen laufen. Lauf oder rolle."),
  ("狭窄通道", "顶板很低——跳起来就撞头——轨道上还有锯片。用跑或翻滚通过。"))

m("martelos",
  ("Alternating Hammers", "Two rows of hammers strike off-beat: when one is down, the other is up. Walk the offbeat."),
  ("Martelos Alternados", "Duas filas de martelos batem em contratempo: quando um desce, o outro sobe. Anda no contratempo."),
  ("Martillos Alternos", "Dos filas de martillos golpean a contratiempo: cuando uno baja, el otro sube. Camina a contratiempo."),
  ("Marteaux Alternés", "Deux rangées de marteaux frappent à contretemps : l'un descend, l'autre monte. Marche à contretemps."),
  ("Wechselhämmer", "Zwei Hammerreihen schlagen versetzt: fällt einer, hebt sich der andere. Geh im Gegentakt."),
  ("交替铁锤", "两排铁锤错拍砸落：一排落下时另一排抬起。踩着反拍走。"))

m("bombas",
  ("Lava Bombs", "Bombs rain from above and mark the ground before they land. Read the marks and move."),
  ("Chuva de Bombas", "Caem bombas de cima e marcam o chão antes de aterrar. Lê as marcas e sai de lá."),
  ("Lluvia de Bombas", "Caen bombas y marcan el suelo antes de aterrizar. Lee las marcas y muévete."),
  ("Pluie de Bombes", "Des bombes tombent et marquent le sol avant l'impact. Lis les marques et bouge."),
  ("Bombenregen", "Bomben fallen und markieren den Boden vor dem Einschlag. Lies die Marken und geh weiter."),
  ("熔岩弹雨", "炸弹从天而降，落地前会在地面留下标记。看准标记再移动。"))

m("lava_sobe",
  ("Rising Lava", "The deadly liquid climbs behind you. There is no waiting on this climb."),
  ("Lava que Sobe", "O líquido mortal trepa atrás de ti. Nesta subida não há esperar."),
  ("Lava que Sube", "El líquido mortal trepa detrás de ti. En esta subida no se espera."),
  ("Lave Montante", "Le liquide mortel grimpe derrière toi. Sur cette montée, on n'attend pas."),
  ("Steigende Lava", "Die tödliche Flüssigkeit steigt hinter dir. Bei diesem Aufstieg wird nicht gewartet."),
  ("上涨的熔岩", "致命液体在身后爬升。这段攀爬没有等待的余地。"))

m("mare",
  ("The Tide", "The liquid rises and falls slowly over a low run of platforms. There is always a way — wait for it."),
  ("A Maré", "O líquido sobe e desce devagar sobre uma fiada baixa de plataformas. Há sempre caminho — espera por ele."),
  ("La Marea", "El líquido sube y baja despacio sobre una hilera baja de plataformas. Siempre hay paso: espéralo."),
  ("La Marée", "Le liquide monte et descend lentement au-dessus d'une rangée basse. Il y a toujours un passage — attends-le."),
  ("Die Gezeiten", "Die Flüssigkeit steigt und fällt langsam über einer niedrigen Reihe. Es gibt immer einen Weg — warte."),
  ("潮汐", "液面在低矮平台上缓慢涨落。总有路可走——等它。"))

m("grav_baixa",
  ("Low Gravity", "Everything weighs less here. Jumps go much higher and you fall much slower."),
  ("Gravidade Baixa", "Aqui pesa tudo menos. Os saltos vão muito mais alto e cais muito mais devagar."),
  ("Gravedad Baja", "Aquí todo pesa menos. Saltas mucho más alto y caes mucho más despacio."),
  ("Gravité Faible", "Ici tout pèse moins. Les sauts montent bien plus haut et la chute est bien plus lente."),
  ("Niedrige Schwerkraft", "Hier wiegt alles weniger. Sprünge gehen viel höher, der Fall dauert viel länger."),
  ("低重力", "这里一切都更轻。跳得高得多，落得也慢得多。"))

m("ar",
  ("Breath", "Underwater the clock is yours: air runs out. The bubble pockets refill it — they are few."),
  ("Ar", "Debaixo de água o relógio é teu: o ar acaba. As bolsas de ar enchem-no — e são poucas."),
  ("Aire", "Bajo el agua el reloj es tuyo: el aire se acaba. Las bolsas de aire lo llenan, y son pocas."),
  ("Souffle", "Sous l'eau, l'horloge c'est toi : l'air s'épuise. Les poches d'air le refont — elles sont rares."),
  ("Atem", "Unter Wasser tickt deine eigene Uhr: die Luft geht aus. Luftblasen füllen sie — es sind wenige."),
  ("氧气", "水下的计时器属于你：空气会耗尽。气泡能补充，但很少。"))

m("tapete",
  ("Currents", "The water drags you sideways. Swim across the pull, not against it."),
  ("Correntes de Água", "A água arrasta-te de lado. Atravessa a corrente, não lutes contra ela."),
  ("Corrientes de Agua", "El agua te arrastra de lado. Cruza la corriente, no luches contra ella."),
  ("Courants", "L'eau t'entraîne sur le côté. Traverse le courant, ne le combats pas."),
  ("Strömungen", "Das Wasser zieht dich zur Seite. Durchquere die Strömung, kämpf nicht dagegen."),
  ("水流", "水会把你横向拖走。横穿水流，别硬顶。"))

m("escuro",
  ("Darkness", "Night closes in with only a hole of light around you. You see the next step and nothing more."),
  ("Escuridão", "A noite fecha-se e só há um buraco de luz à tua volta. Vês o passo seguinte e mais nada."),
  ("Oscuridad", "La noche se cierra y solo hay un hueco de luz a tu alrededor. Ves el paso siguiente y nada más."),
  ("Obscurité", "La nuit se referme, il ne reste qu'un trou de lumière autour de toi. Tu vois le pas suivant, rien de plus."),
  ("Finsternis", "Die Nacht schließt sich; nur ein Lichtloch bleibt um dich. Du siehst den nächsten Schritt, sonst nichts."),
  ("黑暗", "夜色闭合，只剩你身边的一圈光。你只能看见下一步。"))


# --- Regiao IX-X: niveis 41-50 ---------------------------------------
m("gelo",
  ("Ice", "Slippery plates: the jump is the same, the braking is gone. The problem is stopping, not jumping."),
  ("Gelo", "Placas escorregadias: o salto é o mesmo, a travagem é que desaparece. O problema é parar, não saltar."),
  ("Hielo", "Placas resbaladizas: el salto es el mismo, lo que falta es el frenado. El problema es parar."),
  ("Glace", "Plaques glissantes : le saut ne change pas, c'est le freinage qui disparaît. Le souci, c'est s'arrêter."),
  ("Eis", "Rutschige Platten: der Sprung bleibt, das Bremsen fällt weg. Das Problem ist das Anhalten."),
  ("冰面", "光滑冰板：跳跃不变，刹车没了。难的是停住，不是跳。"))

m("chuva",
  ("Avalanche", "A wall of snow chases you down the run. It cannot be fought — only outrun."),
  ("Avalanche", "Uma parede de neve persegue-te pelo percurso. Não se combate — foge-se."),
  ("Avalancha", "Un muro de nieve te persigue por el recorrido. No se combate: se huye."),
  ("Avalanche", "Un mur de neige te poursuit sur tout le parcours. On ne le combat pas — on le fuit."),
  ("Lawine", "Eine Schneewand jagt dich den Weg hinab. Sie lässt sich nicht bekämpfen — nur überholen."),
  ("雪崩", "雪墙一路追赶。它无法被击退——只能跑赢。"))

m("vitral",
  ("Stained Glass", "A glass wall blocks the way and the bridge beyond is a ghost. Break the glass to let the light through."),
  ("Vitral", "Uma parede de vidro corta o caminho e a ponte do outro lado está fantasma. Parte o vitral e entra a luz."),
  ("Vidriera", "Un muro de vidrio corta el paso y el puente del otro lado es fantasma. Rómpelo y entra la luz."),
  ("Vitrail", "Un mur de verre barre la voie et le pont au-delà est fantôme. Brise-le pour laisser passer la lumière."),
  ("Buntglas", "Eine Glaswand sperrt den Weg, die Brücke dahinter ist ein Geist. Zerbrich sie, damit Licht einfällt."),
  ("彩窗", "玻璃墙挡路，对面的桥是虚影。打碎玻璃让光穿过。"))

m("espectral",
  ("Spectral Platforms", "They only turn solid a few seconds after you step on them. There is no going back."),
  ("Plataformas Espectrais", "Só ficam sólidas uns segundos depois de as pisares. Não há voltar atrás."),
  ("Plataformas Espectrales", "Solo se vuelven sólidas segundos después de pisarlas. No hay vuelta atrás."),
  ("Plates-formes Spectrales", "Elles ne deviennent solides que quelques secondes après ton passage. Pas de retour en arrière."),
  ("Spektralplattformen", "Sie werden erst Sekunden nach dem Betreten fest. Zurück geht es nicht."),
  ("幽灵平台", "踩过几秒后才会变实。没有回头路。"))

m("frio",
  ("Freezing", "Icy gusts leave you slowed for a few seconds after you leave them. It follows you out."),
  ("Frio", "Sopros gelados deixam-te lenta uns segundos depois de saíres deles. Vai contigo."),
  ("Frío", "Ráfagas heladas te dejan lenta unos segundos tras salir. El efecto te acompaña."),
  ("Froid", "Des souffles glacés te ralentissent quelques secondes après en être sortie. L'effet te suit."),
  ("Kälte", "Eisige Böen machen dich noch Sekunden nach dem Verlassen langsam. Es begleitet dich."),
  ("冰寒", "寒风会在你离开后仍让你迟缓数秒。效果跟着你走。"))

m("areia",
  ("Quicksand", "It pulls you down and holds. Jump repeatedly to get out — walking will not do it."),
  ("Areia Movediça", "Puxa-te para baixo e agarra. Sai-se a saltar — a andar não sais."),
  ("Arenas Movedizas", "Tiran de ti hacia abajo y te sujetan. Se sale saltando; andando, no."),
  ("Sables Mouvants", "Ça t'aspire vers le bas et te retient. On en sort en sautant, pas en marchant."),
  ("Treibsand", "Er zieht dich nach unten und hält fest. Nur Springen bringt dich raus, Gehen nicht."),
  ("流沙", "它把你往下拽并困住。要靠连续跳跃脱身，走是走不出去的。"))

m("placa",
  ("Pressure Plate", "Standing on the plate opens the gate — and releases it the moment you step off."),
  ("Placa de Pressão", "Estar em cima da placa abre a grade — e solta-a assim que sais de cima."),
  ("Placa de Presión", "Pisar la placa abre la reja, y la suelta en cuanto te bajas."),
  ("Plaque de Pression", "Rester sur la plaque ouvre la grille — et la relâche dès que tu descends."),
  ("Druckplatte", "Auf der Platte stehen öffnet das Gitter — und gibt es frei, sobald du heruntergehst."),
  ("压力板", "站在板上闸门开启——一离开就立刻关上。"))

m("veneno",
  ("Poison", "The clouds mark you and the damage comes after. Running through still costs — the clean route is above."),
  ("Veneno", "As nuvens marcam-te e o dano vem depois. Atravessar a correr custa na mesma — o caminho são é por cima."),
  ("Veneno", "Las nubes te marcan y el daño llega después. Cruzar corriendo también cuesta: la ruta sana va arriba."),
  ("Poison", "Les nuages te marquent et les dégâts viennent après. Traverser en courant coûte aussi — la voie saine est au-dessus."),
  ("Gift", "Die Wolken markieren dich, der Schaden kommt danach. Durchrennen kostet trotzdem — der saubere Weg liegt oben."),
  ("剧毒", "毒云会标记你，伤害稍后才到。跑过去照样吃伤——干净的路在上面。"))

m("areia_no_ar",
  ("Sandstorm", "The storm does not darken — it veils. You see everything, and everything badly."),
  ("Tempestade de Areia", "A tempestade não escurece — tapa. Vês tudo, e tudo mal."),
  ("Tormenta de Arena", "La tormenta no oscurece: vela. Lo ves todo, y todo mal."),
  ("Tempête de Sable", "La tempête n'assombrit pas — elle voile. Tu vois tout, et tout mal."),
  ("Sandsturm", "Der Sturm verdunkelt nicht — er verschleiert. Du siehst alles, und alles schlecht."),
  ("沙暴", "沙暴不是变黑，而是遮蔽。你什么都看得见，什么都看不清。"))

m("queda",
  ("Rolling Boulder", "A stone ball comes down the run behind you. Run forward — there is no dodging it."),
  ("Bola de Pedra", "Uma bola de pedra desce o percurso atrás de ti. Foge para a frente — não se desvia."),
  ("Bola de Piedra", "Una bola de piedra baja el recorrido tras de ti. Huye hacia delante: no se esquiva."),
  ("Rocher Roulant", "Une boule de pierre dévale derrière toi. Fuis en avant — on ne l'esquive pas."),
  ("Rollender Fels", "Eine Steinkugel rollt hinter dir den Weg hinab. Flieh nach vorn — ausweichen geht nicht."),
  ("滚石", "巨石从身后一路滚下。往前跑——躲不掉。"))


# --- Regiao XI-XII: niveis 51-60 -------------------------------------
m("rosas",
  ("Cycling Thorns", "Thorns grow and retract on a cycle. The floor is only floor for part of the beat."),
  ("Espinhos em Ciclo", "Os espinhos crescem e recolhem em ciclo. O chão só é chão numa parte do compasso."),
  ("Espinas Cíclicas", "Las espinas crecen y se retraen en ciclo. El suelo solo es suelo parte del compás."),
  ("Épines Cycliques", "Les épines poussent et se rétractent en cycle. Le sol n'est sol qu'une partie du temps."),
  ("Zyklische Dornen", "Dornen wachsen und ziehen sich im Takt zurück. Der Boden ist nur zeitweise Boden."),
  ("周期尖刺", "尖刺按周期升起又缩回。地面只在节拍的一部分才是地面。"))

m("bifurcacao",
  ("False Forks", "Several mouths, and only one goes on. The false ones show themselves — read before you commit."),
  ("Bifurcações Falsas", "Várias bocas, e só uma segue. As falsas dão-se a ver — lê antes de te comprometeres."),
  ("Bifurcaciones Falsas", "Varias bocas y solo una sigue. Las falsas se dejan ver: lee antes de decidir."),
  ("Fausses Fourches", "Plusieurs bouches, une seule continue. Les fausses se laissent voir — observe avant de t'engager."),
  ("Falsche Gabelungen", "Mehrere Öffnungen, nur eine führt weiter. Die falschen verraten sich — lies erst, dann geh."),
  ("假岔口", "多个出口，只有一个通向前方。假的会露出破绽——先看清再走。"))

m("gancho",
  ("The Hook", "Hook onto the vines in mid-air and swing. Press jump to let go at the top of the arc."),
  ("O Gancho", "Engata nas trepadeiras no ar e balança. Larga com o salto no ponto alto do arco."),
  ("El Gancho", "Engánchate a las lianas en el aire y balancéate. Suelta con el salto en lo alto del arco."),
  ("Le Grappin", "Accroche-toi aux lianes en plein vol et balance-toi. Lâche avec le saut en haut de l'arc."),
  ("Der Haken", "Hak dich in der Luft an den Ranken ein und schwing. Mit Sprung am Scheitelpunkt loslassen."),
  ("钩索", "在空中钩住藤蔓并摆荡。在弧线最高点按跳跃松手。"))

m("esporos",
  ("Spore Fields", "Light and heavy fields alternate. Every jump changes weight — read the field before you leap."),
  ("Campos de Esporos", "Campos leves e pesados alternam. Cada salto muda de peso — lê o campo antes de saltar."),
  ("Campos de Esporas", "Se alternan campos ligeros y pesados. Cada salto cambia de peso: lee el campo antes."),
  ("Champs de Spores", "Champs légers et lourds alternent. Chaque saut change de poids — lis le champ avant."),
  ("Sporenfelder", "Leichte und schwere Felder wechseln sich ab. Jeder Sprung wiegt anders — lies das Feld."),
  ("孢子力场", "轻重力场交替出现。每一跳重量都不同——起跳前先看清。"))

m("raizes",
  ("Bursting Roots", "Roots telegraph, then strike out of the ground. Watch the tell and be gone before it lands."),
  ("Raízes que Irrompem", "As raízes telegrafam e depois batem do chão. Vê o aviso e sai antes do golpe."),
  ("Raíces que Brotan", "Las raíces avisan y luego golpean desde el suelo. Ve la señal y sal antes."),
  ("Racines Jaillissantes", "Les racines annoncent puis frappent depuis le sol. Vois le signe et dégage avant."),
  ("Ausbrechende Wurzeln", "Wurzeln kündigen an und schlagen dann aus dem Boden. Sieh das Zeichen und geh."),
  ("暴起的根须", "根须先预警，再从地下击出。看到预兆就立刻走开。"))

m("engrenagens",
  ("Gear Arms", "Cross arms turn slowly. Ride an arm while it is low and step off before it rises."),
  ("Engrenagens", "Braços em cruz dão a volta devagar. Anda em cima do braço em baixo e sai antes de ele subir."),
  ("Engranajes", "Brazos en cruz giran despacio. Ve sobre el brazo bajo y sal antes de que suba."),
  ("Engrenages", "Des bras en croix tournent lentement. Monte sur le bras bas et descends avant qu'il monte."),
  ("Zahnradarme", "Kreuzarme drehen sich langsam. Fahr auf dem unteren Arm mit und geh, bevor er steigt."),
  ("齿轮臂", "十字臂缓慢旋转。趁臂在低处踩上去，升起前离开。"))

m("peso",
  ("Weighted Platforms", "They sink while you stand on them and rise when you leave. You lose height, not ground."),
  ("Plataformas com Peso", "Descem enquanto lá estás e sobem quando sais. Não perdes o chão, perdes ALTURA."),
  ("Plataformas con Peso", "Bajan mientras estás encima y suben al salir. No pierdes suelo: pierdes ALTURA."),
  ("Plates-formes Lestées", "Elles descendent sous ton poids et remontent quand tu pars. Tu perds de la hauteur, pas le sol."),
  ("Gewichtsplattformen", "Sie sinken unter dir und steigen, wenn du gehst. Du verlierst Höhe, nicht Boden."),
  ("承重平台", "你站上去它就下沉，离开后回升。失去的是高度，不是落脚点。"))

m("replicantes",
  ("Splitters", "Kill one and it splits into smaller ones. Space is the resource — do not get surrounded."),
  ("Replicantes", "Matas um e ele parte-se em mais pequenos. O espaço é o recurso — não te deixes cercar."),
  ("Replicantes", "Matas a uno y se divide en otros menores. El recurso es el espacio: que no te rodeen."),
  ("Réplicants", "Tue-en un et il se scinde en plus petits. La ressource, c'est l'espace — ne te fais pas encercler."),
  ("Teiler", "Tötest du einen, teilt er sich in kleinere. Die Ressource ist Platz — lass dich nicht einkreisen."),
  ("分裂体", "杀死一个会分裂成更小的。空间才是资源——别被围住。"))

m("circuito",
  ("The Circuit", "Switches must be lit in the right order. Get one wrong and the run resets."),
  ("Circuito", "Os interruptores têm de acender pela ordem certa. Erras um e a sequência recomeça."),
  ("Circuito", "Los interruptores deben encenderse en orden. Si fallas uno, la secuencia se reinicia."),
  ("Circuit", "Les interrupteurs doivent s'allumer dans l'ordre. Une erreur et la séquence repart."),
  ("Schaltkreis", "Die Schalter müssen in der richtigen Reihenfolge leuchten. Ein Fehler setzt alles zurück."),
  ("电路", "开关必须按正确顺序点亮。错一个就要重来。"))

m("imanes",
  ("Magnets", "They pull you in mid-air. Your jump is no longer entirely yours — aim off the pull."),
  ("Ímanes", "Puxam-te no ar. O salto deixa de ser todo teu — aponta a contar com o puxão."),
  ("Imanes", "Tiran de ti en el aire. El salto ya no es del todo tuyo: apunta contando con el tirón."),
  ("Aimants", "Ils t'attirent en plein vol. Ton saut n'est plus tout à fait le tien — vise en tenant compte."),
  ("Magnete", "Sie ziehen dich in der Luft. Der Sprung gehört dir nicht mehr allein — ziel mit Vorhalt."),
  ("磁石", "它们在空中吸扯你。跳跃不再完全由你决定——瞄准时把拉力算进去。"))


# --- Regiao XIII-XIV: niveis 61-70 -----------------------------------
m("orbita",
  ("Orbiting Islands", "The platform travels in a circle and you ride it. Get on early, get off on the near side."),
  ("Ilhas em Órbita", "A plataforma anda em círculo e tu vais a bordo. Entra cedo e sai do lado de cá."),
  ("Islas en Órbita", "La plataforma gira en círculo y tú vas a bordo. Sube pronto y baja del lado cercano."),
  ("Îles en Orbite", "La plate-forme décrit un cercle et tu montes dessus. Monte tôt, descends du côté proche."),
  ("Umlaufende Inseln", "Die Plattform zieht einen Kreis und du fährst mit. Früh aufsteigen, auf der nahen Seite runter."),
  ("环轨浮岛", "平台沿圆周运行，你随它移动。尽早上去，在近侧下来。"))

m("para_raios",
  ("Lightning Rod", "Lightning falls in columns. Draw it onto the metal rod to open the way."),
  ("Para-Raios", "Os raios caem em coluna. Chama-os para a haste de metal para abrir caminho."),
  ("Pararrayos", "Los rayos caen en columna. Atráelos a la vara de metal para abrir camino."),
  ("Paratonnerre", "La foudre tombe en colonnes. Attire-la sur la tige de métal pour ouvrir la voie."),
  ("Blitzableiter", "Blitze schlagen in Säulen ein. Lenk sie auf die Metallstange, um den Weg zu öffnen."),
  ("避雷针", "闪电成柱落下。把它引到金属杆上以打开通路。"))

m("asas",
  ("Glide", "Hold jump while falling to glide. It is not flight — it is falling slowly, and only downward."),
  ("Planar", "Segura o salto na descida para planar. Não é voar — é cair devagar, e só para baixo."),
  ("Planear", "Mantén el salto al caer para planear. No es volar: es caer despacio, y solo hacia abajo."),
  ("Planer", "Maintiens le saut en descente pour planer. Ce n'est pas voler — c'est tomber lentement."),
  ("Gleiten", "Halt Sprung im Fallen für den Gleitflug. Kein Fliegen — langsames Fallen, nur abwärts."),
  ("滑翔", "下落时按住跳跃即可滑翔。这不是飞行——是缓慢下坠，且只能向下。"))

m("ameaca",
  ("The Advancing Wall", "A wall of death crosses the room at a steady pace. It cannot be fought — keep moving."),
  ("A Ameaça que Avança", "Uma parede de morte atravessa a sala a passo constante. Não se combate — anda."),
  ("La Amenaza que Avanza", "Un muro de muerte cruza la sala a paso constante. No se combate: muévete."),
  ("La Menace qui Avance", "Un mur de mort traverse la salle à pas constant. On ne le combat pas — avance."),
  ("Die Vorrückende Wand", "Eine Todeswand zieht gleichmäßig durch den Raum. Nicht bekämpfbar — beweg dich."),
  ("推进的死墙", "死亡之墙以恒定速度横穿房间。无法对抗——只能不停前进。"))

m("invertido",
  ("Inverted World", "Floor plates flip your gravity: you fall upward and walk the ceilings. You choose when to step on one."),
  ("Mundo Invertido", "Placas no chão viram-te a gravidade: cais para cima e andas nos tectos. Tu escolhes quando as pisas."),
  ("Mundo Invertido", "Las placas del suelo invierten tu gravedad: caes hacia arriba y andas por los techos. Tú eliges cuándo."),
  ("Monde Inversé", "Des plaques inversent ta gravité : tu tombes vers le haut et marches au plafond. À toi de choisir quand."),
  ("Verkehrte Welt", "Bodenplatten drehen deine Schwerkraft: du fällst nach oben und läufst an Decken. Du wählst wann."),
  ("倒置世界", "地面压板会反转重力：你向上坠落，在天花板行走。何时踩上由你决定。"))

m("estatuas",
  ("They Move Unseen", "These figures only move while you are not looking at them. Turning away is the risk."),
  ("Só se Mexem sem Olhares", "Estas figuras só andam enquanto não olhas para elas. Virar costas é que é o risco."),
  ("Solo se Mueven sin Mirar", "Estas figuras solo se mueven mientras no las miras. El riesgo es darles la espalda."),
  ("Elles Bougent Sans Regard", "Ces figures ne bougent que quand tu ne les regardes pas. Le risque, c'est de te détourner."),
  ("Sie Bewegen sich Unbeobachtet", "Diese Gestalten bewegen sich nur, wenn du nicht hinsiehst. Wegsehen ist das Risiko."),
  ("背身即动", "这些身影只在你不看它们时移动。转身才是危险。"))

m("sombra",
  ("Your Shadow", "It walks your path three seconds late. It cannot be fought or shaken — just never double back."),
  ("A Tua Sombra", "Anda pelo teu caminho três segundos depois. Não se combate nem se despista — não voltes atrás."),
  ("Tu Sombra", "Recorre tu camino tres segundos después. No se combate ni se despista: no vuelvas atrás."),
  ("Ton Ombre", "Elle suit ton chemin trois secondes plus tard. Ni combat ni semis — ne reviens jamais sur tes pas."),
  ("Dein Schatten", "Er geht deinen Weg drei Sekunden später. Nicht bekämpfbar, nicht abzuhängen — geh nie zurück."),
  ("你的影子", "它沿你的路径延迟三秒行走。打不掉也甩不脱——千万别折返。"))

m("mente",
  ("The Shifting Scene", "The scenery rewrites itself behind you. The critical path never changes — the way back does."),
  ("O Cenário que se Reescreve", "O cenário reescreve-se atrás de ti. O caminho crítico nunca muda — o de volta é que sim."),
  ("El Escenario que se Reescribe", "El escenario se reescribe a tus espaldas. El camino crítico no cambia; el de vuelta sí."),
  ("Le Décor qui se Réécrit", "Le décor se réécrit derrière toi. Le chemin critique ne change jamais — le retour, si."),
  ("Die Kulisse Schreibt sich um", "Die Kulisse schreibt sich hinter dir um. Der kritische Weg bleibt — der Rückweg nicht."),
  ("重写的场景", "场景在你身后重写。关键路径永远不变——变的是回头路。"))

m("caixas",
  ("Push the Crate", "The plate opens the gate only while weighted. Push the crate onto it — there is no other way."),
  ("Empurra a Caixa", "A placa só abre a grade enquanto tiver peso em cima. Empurra a caixa para lá — não há outra maneira."),
  ("Empuja la Caja", "La placa abre la reja solo con peso encima. Empuja la caja hasta ella: no hay otra forma."),
  ("Pousse la Caisse", "La plaque n'ouvre la grille que sous un poids. Pousse la caisse dessus — pas d'autre solution."),
  ("Schieb die Kiste", "Die Platte öffnet das Gitter nur unter Last. Schieb die Kiste darauf — anders geht es nicht."),
  ("推箱子", "压板需要持续受重才开门。把箱子推上去——没有别的办法。"))

m("ciclo",
  ("The Loop", "Three identical mouths and only one leads on. The others send you back to the start."),
  ("O Ciclo", "Três bocas iguais e só uma sai. As outras devolvem-te à entrada."),
  ("El Ciclo", "Tres bocas iguales y solo una sale. Las otras te devuelven a la entrada."),
  ("La Boucle", "Trois bouches identiques, une seule mène ailleurs. Les autres te ramènent au départ."),
  ("Die Schleife", "Drei gleiche Öffnungen, nur eine führt weiter. Die anderen bringen dich zum Anfang."),
  ("循环", "三个一模一样的出口，只有一个通向前方。其余把你送回起点。"))


# --- Regiao XV-XVI: niveis 73-80 -------------------------------------
m("incorporeo",
  ("Incorporeal", "Your blade passes through it. Only the projectile lands — keep your distance."),
  ("Incorpóreo", "A espada atravessa-o. Só o tiro lhe toca — mantém a distância."),
  ("Incorpóreo", "La espada lo atraviesa. Solo el disparo le alcanza: mantén la distancia."),
  ("Incorporel", "La lame le traverse. Seul le tir l'atteint — garde tes distances."),
  ("Körperlos", "Die Klinge geht hindurch. Nur der Schuss trifft — halt Abstand."),
  ("无形之敌", "剑会直接穿过它。只有射击能伤到它——保持距离。"))

m("mausoleu",
  ("Mausoleum", "Statues that move unseen, inside darkness that hides them. Looking back is no longer free."),
  ("Mausoléu", "Estátuas que andam sem olhares, dentro de uma escuridão que as esconde. Olhar para trás deixou de ser grátis."),
  ("Mausoleo", "Estatuas que se mueven sin miradas, dentro de una oscuridad que las esconde. Mirar atrás ya cuesta."),
  ("Mausolée", "Des statues qui bougent sans regard, dans une obscurité qui les cache. Regarder derrière n'est plus gratuit."),
  ("Mausoleum", "Statuen, die sich unbeobachtet bewegen, in einer Finsternis, die sie verbirgt. Zurückblicken kostet jetzt."),
  ("陵墓", "会在无人注视时移动的石像，藏在遮蔽它们的黑暗里。回头不再是免费的。"))

m("ceifa",
  ("The Reaper Line", "A single line sweeps the whole arena. There is no corner to hide in — only timing."),
  ("A Ceifa", "Uma linha varre a arena inteira. Não há canto onde te esconder — só o momento certo."),
  ("La Siega", "Una línea barre toda la arena. No hay rincón donde esconderse: solo el momento justo."),
  ("La Faux", "Une ligne balaie toute l'arène. Aucun coin où se cacher — seulement le bon instant."),
  ("Die Sense", "Eine Linie fegt die ganze Arena. Keine Ecke zum Verstecken — nur das Timing."),
  ("横扫之镰", "一道横线扫过整个竞技场。无处躲藏——只能靠时机。"))

m("serpente",
  ("The Serpent", "A long body in continuous motion crossing the room. You do not memorise it — you read it."),
  ("A Serpente", "Um corpo comprido em movimento contínuo a atravessar a sala. Não se decora — lê-se."),
  ("La Serpiente", "Un cuerpo largo en movimiento continuo que cruza la sala. No se memoriza: se lee."),
  ("Le Serpent", "Un long corps en mouvement continu traverse la salle. Ça ne se mémorise pas — ça se lit."),
  ("Die Schlange", "Ein langer Körper in stetiger Bewegung quert den Raum. Nicht auswendig lernen — lesen."),
  ("巨蛇", "一条长躯持续移动横贯房间。它不能靠背——只能靠读。"))

m("conves",
  ("Tilting Deck", "The floor stays under your feet but stops being level. You slide to the low side, and it changes."),
  ("Convés que Inclina", "O chão continua lá, só deixa de ser horizontal. Escorregas para o lado baixo — e ele muda."),
  ("Cubierta que se Inclina", "El suelo sigue ahí, pero deja de ser horizontal. Resbalas al lado bajo, y ese lado cambia."),
  ("Pont qui Penche", "Le sol reste sous tes pieds mais n'est plus horizontal. Tu glisses vers le bas — et le bas change."),
  ("Kippendes Deck", "Der Boden bleibt, wird aber schief. Du rutschst zur tiefen Seite — und die wechselt."),
  ("倾斜甲板", "地板还在脚下，只是不再水平。你会滑向低的一侧，而低侧会变。"))

m("varredura",
  ("The Sweep", "A beam sweeps the corridor end to end. Move with it, never against it."),
  ("A Varredura", "Um feixe varre o corredor de ponta a ponta. Anda com ele, nunca contra ele."),
  ("El Barrido", "Un haz barre el pasillo de punta a punta. Muévete con él, nunca contra él."),
  ("Le Balayage", "Un faisceau balaie le couloir d'un bout à l'autre. Va avec lui, jamais contre."),
  ("Der Sweep", "Ein Strahl fegt den Gang von Ende zu Ende. Geh mit ihm, nie dagegen."),
  ("扫掠", "一道光束从头扫到尾。顺着它走，别逆着它。"))

m("pulsacao",
  ("One Pulse", "Every hazard in this room shares a single beat. Find it once and the room is solved."),
  ("Pulsação", "Todos os perigos desta sala partilham um só compasso. Encontra-o uma vez e a sala resolve-se."),
  ("Pulsación", "Todos los peligros de la sala comparten un único compás. Encuéntralo y la sala se resuelve."),
  ("Pulsation", "Tous les dangers de la salle partagent une seule mesure. Trouve-la et la salle est résolue."),
  ("Pulsschlag", "Alle Gefahren dieses Raums teilen einen Takt. Finde ihn einmal, und der Raum ist gelöst."),
  ("同一脉动", "房间里所有危险共用一个节拍。找到它，这间房就解开了。"))


# --- Regiao XVII-XVIII: niveis 81-90 ---------------------------------
m("prensa_fogo",
  ("Burning Presses", "Presses that also burn. The gap is still there — it is just shorter than you want."),
  ("Prensas de Fogo", "Prensas que também queimam. O buraco continua lá — só é mais curto do que gostavas."),
  ("Prensas de Fuego", "Prensas que además queman. El hueco sigue ahí, solo que más corto de lo que quisieras."),
  ("Presses de Feu", "Des presses qui brûlent aussi. Le trou est toujours là — juste plus court que tu ne voudrais."),
  ("Feuerpressen", "Pressen, die auch brennen. Die Lücke bleibt — nur kürzer, als dir lieb ist."),
  ("烈焰压墙", "既压又烧的压墙。空隙依然存在——只是比你想要的更短。"))

m("brasas",
  ("Embers", "The floor lights up under anything that stands still. Keep walking and it never catches."),
  ("Brasas", "O chão acende debaixo de quem fica parada. Continua a andar e nunca pega."),
  ("Brasas", "El suelo se enciende bajo quien se queda quieta. Sigue andando y nunca prende."),
  ("Braises", "Le sol s'embrase sous qui reste immobile. Continue à marcher et rien ne prend."),
  ("Glut", "Der Boden entzündet sich unter allem, was stillsteht. Bleib in Bewegung, dann brennt nichts."),
  ("余烬", "任何静止不动的东西下方地面都会燃起。一直走动就不会着火。"))

m("correnteza",
  ("The Rapids", "The blood flows one way and takes you with it. Cross the current at an angle."),
  ("Correnteza", "O sangue corre num sentido e leva-te com ele. Atravessa a corrente de través."),
  ("Corriente", "La sangre corre en un sentido y te lleva. Cruza la corriente en diagonal."),
  ("Le Courant", "Le sang coule dans un sens et t'emporte. Traverse le courant en biais."),
  ("Die Strömung", "Das Blut fließt in eine Richtung und nimmt dich mit. Quer die Strömung schräg."),
  ("激流", "血流朝一个方向奔涌，把你一起带走。斜着横渡水流。"))

m("reflexo",
  ("Hostile Reflection", "The mirror does not break — it fights. It mirrors your moves and meets you in the middle."),
  ("Reflexo Hostil", "O espelho não parte — ataca. Espelha os teus movimentos e encontram-se sempre a meio."),
  ("Reflejo Hostil", "El espejo no se rompe: ataca. Refleja tus movimientos y os encontráis a mitad."),
  ("Reflet Hostile", "Le miroir ne se brise pas — il attaque. Il copie tes gestes et vous vous croisez au milieu."),
  ("Feindliches Spiegelbild", "Der Spiegel bricht nicht — er kämpft. Er spiegelt dich und trifft dich in der Mitte."),
  ("敌意倒影", "镜子不会碎——它会反击。它镜像你的动作，总在中间与你相遇。"))

m("anel",
  ("Ring Arena", "A ring of ground over lava. There are no corners — you can always be flanked."),
  ("Arena em Anel", "Um anel de chão sobre lava. Não há cantos — podem sempre apanhar-te por trás."),
  ("Arena en Anillo", "Un anillo de suelo sobre lava. No hay esquinas: siempre pueden flanquearte."),
  ("Arène en Anneau", "Un anneau de sol au-dessus de la lave. Aucun coin — on peut toujours te contourner."),
  ("Ringarena", "Ein Ring aus Boden über Lava. Keine Ecken — du kannst immer umgangen werden."),
  ("环形竞技场", "熔岩之上的一圈地面。没有角落——随时可能被包抄。"))

m("olhar",
  ("Only While You Look", "The middle platforms exist only while you face them. Walking forward lights the way."),
  ("Só Enquanto Olhas", "As plataformas do meio só existem enquanto olhas para elas. Andar em frente acende o caminho."),
  ("Solo Mientras Miras", "Las plataformas del medio solo existen mientras las miras. Avanzar enciende el camino."),
  ("Tant que Tu Regardes", "Les plates-formes du milieu n'existent que tant que tu les regardes. Avancer allume la voie."),
  ("Nur im Blick", "Die mittleren Plattformen existieren nur, solange du hinsiehst. Vorwärtsgehen erhellt den Weg."),
  ("凝视方存", "中段的平台只在你朝向它们时存在。向前走就能点亮道路。"))

m("sem_chao",
  ("No Ground", "There is no floor here — only what the blasters give you. Ride them and never stall."),
  ("Sem Chão", "Aqui não há chão — só o que os impulsores te derem. Anda neles e não pares no ar."),
  ("Sin Suelo", "Aquí no hay suelo: solo lo que te den los impulsores. Móntalos y no te pares en el aire."),
  ("Sans Sol", "Ici il n'y a pas de sol — seulement ce que les propulseurs offrent. Reste porté, ne cale jamais."),
  ("Kein Boden", "Hier gibt es keinen Boden — nur was die Bläser dir geben. Bleib getragen, stocke nie."),
  ("无地之境", "这里没有地面——只有推进器给你的托举。乘着它们，别在空中停滞。"))

m("gemea",
  ("The Twin Room", "The same room twice, and the second time one thing is different. Find it before it finds you."),
  ("A Sala Gémea", "A mesma sala duas vezes, e na segunda há uma coisa diferente. Encontra-a antes que ela te encontre."),
  ("La Sala Gemela", "La misma sala dos veces, y en la segunda algo cambia. Encuéntralo antes de que te encuentre."),
  ("La Salle Jumelle", "La même salle deux fois, et la seconde fois une chose diffère. Trouve-la avant qu'elle te trouve."),
  ("Der Zwillingsraum", "Derselbe Raum zweimal, beim zweiten Mal ist eine Sache anders. Finde sie zuerst."),
  ("孪生房间", "同一个房间走两遍，第二遍有一处不同。在它找到你之前先找到它。"))

m("atoleiro",
  ("The Mire", "The ground sinks while you are on it and steals your speed. Standing still is going down."),
  ("Atoleiro", "O chão afunda enquanto lá estás e rouba-te aceleração. Parar é descer."),
  ("Lodazal", "El suelo se hunde mientras estás encima y te roba aceleración. Pararse es bajar."),
  ("Le Bourbier", "Le sol s'enfonce sous toi et te vole ton élan. S'arrêter, c'est descendre."),
  ("Der Morast", "Der Boden sinkt unter dir und raubt dir Schwung. Stehenbleiben heißt sinken."),
  ("泥沼", "你踩上去地面就下陷，还会夺走你的加速。停下就是下沉。"))


# --- Regiao XIX-XX: niveis 91-100 ------------------------------------
m("catapulta",
  ("Catapults", "Stones fall from the sky and mark the ground first. The marks are your only warning."),
  ("Catapultas", "Caem pedras do céu e marcam o chão primeiro. As marcas são o único aviso."),
  ("Catapultas", "Caen piedras del cielo y marcan el suelo antes. Las marcas son el único aviso."),
  ("Catapultes", "Des pierres tombent du ciel et marquent d'abord le sol. Les marques sont ton seul avertissement."),
  ("Katapulte", "Steine fallen vom Himmel und markieren zuerst den Boden. Die Marken sind die einzige Warnung."),
  ("投石机", "巨石从天而降，落地前先在地面标记。标记是唯一的预警。"))

m("salvas",
  ("Arrow Volleys", "Arrows come in waves, all at once, and every wave is telegraphed. Move between volleys."),
  ("Salvas de Flechas", "As flechas vêm em vagas, todas ao mesmo tempo, e cada vaga é telegrafada. Anda entre salvas."),
  ("Andanadas de Flechas", "Las flechas llegan en oleadas, todas a la vez, y cada una se avisa. Muévete entre andanadas."),
  ("Salves de Flèches", "Les flèches arrivent par vagues, toutes ensemble, chacune annoncée. Bouge entre les salves."),
  ("Pfeilsalven", "Pfeile kommen in Wellen, alle zugleich, jede angekündigt. Beweg dich zwischen den Salven."),
  ("箭雨齐射", "箭矢成波齐发，每一波都有预警。在两轮齐射之间移动。"))

m("ariete",
  ("The Ram", "The door only opens if you push the ram to it — and the ram is your only cover."),
  ("O Aríete", "A porta só abre se empurrares a máquina até lá — e a máquina é a tua única cobertura."),
  ("El Ariete", "La puerta solo abre si empujas la máquina hasta ella, y la máquina es tu única cobertura."),
  ("Le Bélier", "La porte ne s'ouvre qu'en poussant la machine jusqu'à elle — et elle est ton seul abri."),
  ("Der Ramme", "Die Tür öffnet sich nur, wenn du die Maschine hinschiebst — und sie ist deine einzige Deckung."),
  ("攻城槌", "只有把攻城槌推到门前，门才会开——而它也是你唯一的掩体。"))

m("assalto",
  ("The Siege Ladder", "Climb while they shoot at you. Height is the goal, cover is what you steal on the way."),
  ("Escada de Assalto", "Sobe enquanto te atiram. A altura é o objectivo; a cobertura é o que roubas pelo caminho."),
  ("Escala de Asalto", "Sube mientras te disparan. La altura es el objetivo; la cobertura, lo que robes de camino."),
  ("L'Échelle d'Assaut", "Grimpe pendant qu'on te tire dessus. La hauteur est le but ; l'abri, ce que tu voles en chemin."),
  ("Die Sturmleiter", "Steig, während sie auf dich schießen. Höhe ist das Ziel, Deckung stiehlst du unterwegs."),
  ("攻城云梯", "在箭矢中向上攀爬。高度是目标，掩护是你沿途抢来的。"))

m("horda",
  ("The Horde", "Waves of enemies with the count in plain sight. Hold the ground until the counter runs out."),
  ("A Horda", "Vagas de inimigos com o contador à vista. Aguenta o terreno até o contador acabar."),
  ("La Horda", "Oleadas de enemigos con el contador a la vista. Aguanta el terreno hasta que se agote."),
  ("La Horde", "Des vagues d'ennemis, le compteur bien visible. Tiens le terrain jusqu'au bout."),
  ("Die Horde", "Feindwellen mit sichtbarem Zähler. Halte den Boden, bis der Zähler leer ist."),
  ("敌潮", "一波波敌人，计数就在眼前。守住阵地直到计数归零。"))

m("memoria",
  ("Memory", "No danger here. This is the realm as it was, before Zeriko — walk it."),
  ("Memória", "Aqui não há perigo. É o reino como era, antes do Zeriko — atravessa-o."),
  ("Memoria", "Aquí no hay peligro. Es el reino como era, antes de Zeriko: recórrelo."),
  ("Mémoire", "Ici, aucun danger. C'est le royaume tel qu'il était, avant Zeriko — traverse-le."),
  ("Erinnerung", "Hier droht nichts. Das ist das Reich, wie es war, vor Zeriko — durchquere es."),
  ("记忆", "此处没有危险。这是泽里科之前的王国原貌——走过它。"))

m("revisao",
  ("The Review", "Four chambers from four regions, back to back, with nothing between them."),
  ("Revisão", "Quatro câmaras de quatro regiões, seguidas, sem nada entre elas."),
  ("Repaso", "Cuatro cámaras de cuatro regiones, seguidas, sin nada entre medias."),
  ("La Révision", "Quatre salles de quatre régions, à la suite, sans rien entre elles."),
  ("Die Wiederholung", "Vier Kammern aus vier Regionen, hintereinander, ohne Pause dazwischen."),
  ("回顾", "来自四个区域的四间密室，接连出现，中间毫无停顿。"))

m("provacao",
  ("The Trial", "Three rooms, and in each one something of yours is missing. The room is not harder — you are less."),
  ("Provação", "Três salas, e em cada uma falta-te uma coisa. A sala não fica mais difícil — tu é que ficas menos."),
  ("La Prueba", "Tres salas, y en cada una te falta algo. La sala no es más difícil: tú eres menos."),
  ("L'Épreuve", "Trois salles, et dans chacune il te manque quelque chose. La salle n'est pas plus dure — c'est toi qui es moins."),
  ("Die Prüfung", "Drei Räume, in jedem fehlt dir etwas. Der Raum wird nicht schwerer — du wirst weniger."),
  ("试炼", "三个房间，每一间都会剥夺你的一样东西。房间没有变难——是你变少了。"))


def cams_que_estreiam():
    """As camaras que ESTREIAM em algum nivel -- e' so' para essas que ha'
    tutorial. Le a tabela do `gerador_corredor.gd` para nao haver duas
    verdades: se la' entrar uma mecanica nova, isto acusa-a a faltar."""
    gd = os.path.join(RAIZ, "scripts", "gerador_corredor.gd")
    txt = open(gd, encoding="utf-8").read()
    bloco = txt.split("const MECANICA_DO_NIVEL := [")[1].split("\n]")[0]
    vistas = []
    for cam in re.findall(r'"cam": "(\w+)"', bloco):
        if cam not in vistas:
            vistas.append(cam)
    return vistas


def main():
    cams = cams_que_estreiam()
    faltam = [c for c in cams if c not in MEC]
    se_mais = [c for c in MEC if c not in cams]
    if faltam:
        print("FALTA texto para: " + ", ".join(faltam), file=sys.stderr)
        return 1
    if se_mais:
        print("a mais (nao estreiam): " + ", ".join(se_mais), file=sys.stderr)

    for lang in IDIOMAS:
        caminho = os.path.join(I18N, lang + ".json")
        with open(caminho, encoding="utf-8") as f:
            dados = json.load(f)
        for cam in cams:
            nome, txt = MEC[cam][lang]
            dados["mec.%s.nome" % cam] = nome
            dados["mec.%s.txt" % cam] = txt
        corpo = json.dumps(dados, ensure_ascii=False, indent="\t")
        with open(caminho, "w", encoding="utf-8", newline="\n") as f:
            f.write(corpo + "\n")
        print("%s: %d chaves (+%d de mecanicas)"
              % (lang, len(dados), len(cams) * 2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
