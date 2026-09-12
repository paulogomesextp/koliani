# Execution 9H.12B — Região I: plano de remaster (investigação + rota)

Base: `origin/master` = `bd2aa418`. **Execução de PLANO — nenhum asset final
produzido, nenhuma cena de nível alterada.**

---

## 0. As quatro causas medidas (não opiniões)

O Game Master disse "os fundos parecem desfocados", "os níveis parecem
pobres" e "estamos a cair demasiado para pixel art". As três queixas têm
causas separadas e mensuráveis.

### 0.1 O desfoque do fundo é aritmética, não filtro

| facto | valor |
|---|---|
| fonte real do panorama | `region1_panorama_heart_tree.png` = **952 x 247 px** |
| escala no mundo | **3,0x** (`_montar_background`, `e := 3.0 / PANORAMA_HD`) |
| zoom da câmara | **1,4x** (`ZOOM_CAMARA`) |
| ampliação efectiva no ecrã | **4,2x** |
| detalhe real por pixel de ecrã | **0,24 px de fonte** |

Os ficheiros `_x2` e `_hd_x4` (até 3808 x 988) **não acrescentam informação**:
são reamostragens do mesmo recorte de 247 px de altura. A 9H.7 tratou o
*filtro* (desenhar a ~1:1) e ganhou nitidez real, mas **não pode inventar os
3/4 de informação que a fonte não tem**. Enquanto a autoridade do fundo for
um recorte de 247 px de altura, 720p vai ser sempre suave.

> **Conclusão:** o fundo da Região I não se corrige com shaders nem com
> reexportação. Tem de ser **re-obtido em resolução nativa** (>= 1080 px de
> altura de detalhe verdadeiro).

### 0.2 O "mosaico pobre" é o tamanho do tijolo

| peça do kit 9C | tamanho |
|---|---|
| `terreno_corpo.png` | **30 x 75** |
| `terreno_topo.png` | 62 x 32 |
| `terreno_lado.png` | 16 x 57 |
| `terreno_base.png` | 62 x 24 |

Uma plataforma de 1050 px repete o mesmo corpo de 30 px **~35 vezes**, sem
variantes. Nenhum passe de valor resolve isso (a 9H.11 pôs gradiente +
rim-light e melhorou, mas o padrão continua a ler-se). **A leitura de "pixel
art pobre" vem daqui, não do fundo** — o fundo é pintado, o chão é mosaico.
É essa discordância que parece amadora.

### 0.3 O material híbrido JÁ EXISTE no repo e está a ser deitado fora

`assets/art/regions/region_01_forest/production/_source/imagegen_v1/`
guarda **12 PNGs de 1254 x 1254 a 2172 x 724**:

```
terrain_fill 1254x1254     terrain_top 1254x1254    terrain_edge_l/r ~1250x1260
terrain_corner_inner/outer 1254x1254                ruin_block 1254x1254
platform_large_segment 2172x724                     platform_small 1774x887
moss_overlay / root_overlay 2172x724                corruption_overlay 1254x1254
```

`tools/build_region_01_sprite_kit.py` pega neles e **reduz a "logical 32/64/96
px runtime sprites"**. O contrato de prompt guardado no `README.md` dessa
pasta pede literalmente *"pixel-art asset ... hard pixel clusters; no
antialiasing"*.

> **Conclusão:** a rota para o híbrido 2D não começa do zero. Começa por
> **mudar o contrato e parar de reduzir**: promover estas fontes a tiles de
> runtime de 256-512 px com variantes. É a alavanca mais barata que temos.

### 0.4 Armadilha de licença — o repo é PÚBLICO

`github.com/paulogomesextp/koliani` é público. **Commitar um asset =
redistribuí-lo.** Quase todos os packs "free" de itch.io proíbem
redistribuição (PitiIT: *"you can't redistribute, sell or claim authorship"*;
Pixsol: idem **e proíbe uso em criações de IA**). Já perdemos o portal da
Frostwindz por isto.

> **Regra desta remodelação:** só entra no repo o que for **CC0** ou **arte
> nossa derivada**. Packs "free-but-no-redistribute" servem apenas como
> *referência visual*, e **nunca** os que proíbem IA.

---

## A) Region I Remaster Direction

**Uma frase:** *floresta gótica pintada ao luar, vista por entre raízes —
fundo ilustrado, chão legível, VFX por cima.*

| eixo | agora | alvo |
|---|---|---|
| fundo | recorte 952x247 ampliado 4,2x | camadas ilustradas de 1080-1440 px de altura, repetidas na horizontal |
| chão | tile de 30 px x35 | tiles de 256-512 px com 3-4 variantes + remates pintados |
| silhueta | tudo à mesma distância | 5 planos: BG longe / BG perto / landmark / jogo / FG moldura |
| luz | luz de lanterna local | luz volumétrica por plano + rim-light de luar (já feito na 9H.11) |
| cor | magenta da corrupção em toda a parte | azul-meia-noite domina; o magenta é **evento**, não ambiente |
| detalhe | props isolados | aglomerados (raízes + musgo + cristal juntos), nunca um prop sozinho |

Regras duras, para não recair:

1. **Nada abaixo de 128 px** de fonte para peças que ocupem meia plataforma.
2. **Nenhuma textura tile sem >=3 variantes** sorteadas.
3. **FG framing obrigatório** em L1-L5 (vinhas/raízes a emoldurar) — é o que
   dá a profundidade que a pixel art plana não tem.
4. **VFX é runtime**, nunca cozido no PNG (névoa, raios, faíscas, poeira).

---

## B) L1-L5 — blueprints dos mapas

O layout jogável (colisões, checkpoints, progressão) **fica como está**.
Isto é blueprint de *apresentação e dressing*.

### L1 — Floresta Putrefacta · *"a orla"*
- **Mood:** entrada quase calma; a corrupção vê-se ao longe, não se pisa.
- **Landmark:** a Heart Tree no horizonte, pequena, ao centro-direita.
- **Layout:** corredor largo, saltos curtos, chão contínuo. **Tutorial
  honesto** (hoje promete salto duplo que o jogador não tem — ver §F).
- **Planos:** céu+névoa / árvores escuras / Heart Tree distante / plataformas
  de pedra musgosa / FG: dois ramos a emoldurar os cantos superiores.
- **Dressing:** musgo dominante, 2-3 lanternas quentes (única cor quente da
  região), cristal de corrupção **raro e pequeno**.
- **Pobre hoje:** plataformas longas e lisas; céu parado.
- **Depois:** variantes de tile + 2 clareiras com raios de luz volumétrica.

### L2 — Pântano dos Sussurros · *"o nevoeiro"* (referência de qualidade)
- Já é o melhor vestido. **Não mexer na densidade** — passa a ser o alvo (1,0).
- Só recebe: tiles grandes + névoa em **2 profundidades** (hoje é uma só) e
  reflexo na água.

### L3 — Ninho da Viúva Negra · *"as ruínas"*
- **Mood:** arquitectura morta engolida pela floresta.
- **Landmark:** arco de pedra partido, a meio do nível, que se atravessa.
- **Layout:** vertical; colunas quebradas como plataformas.
- **Planos:** ruínas em silhueta / colunas / arco / alvenaria / FG: teias e
  raízes pendentes.
- **Dressing:** `ruin_block` (já existe em 1254x1254), lanternas altas, teia.
- **Pobre hoje:** poço escuro enorme no fundo do ecrã, sem nada.
- **Depois:** o poço ganha ruínas submersas em silhueta e névoa que sobe.

### L4 — A Árvore que Chora · *"as cascatas"*
- **Mood:** água por toda a parte, som e movimento.
- **Landmark:** a queda de água principal, atravessável.
- **Layout:** já tem a assinatura das cascatas; manter.
- **Planos:** desfiladeiro / quedas distantes / queda principal / plataformas
  molhadas (linha de água já feita na 9H.7) / FG: salpicos.
- **Dressing:** pedra escura, musgo encharcado, névoa baixa.

### L5 — Coração da Floresta · *"o clímax"*
- **Mood:** a corrupção venceu. Não é o L1 com outro céu.
- **Landmark:** **a Heart Tree em cima do jogador**, a encher meio ecrã.
- **Layout:** aproximação em rampa até à arena do chefe — o landmark cresce.
- **Planos:** céu doente / raízes gigantes / Heart Tree dominante /
  plataformas tomadas por cristal / FG: raízes pulsantes.
- **Dressing:** cristal domina (a 9H.11 já pôs `corrupcao` 1,8 e a rocha
  tingida de violeta — **isto fica e serve de base**); zero lanternas quentes.
- **Depois:** o chão deixa de ser "pedra com cristais em cima" e passa a ter
  **tile próprio de rocha corrompida** (variante de `terrain_fill`).

**Progressão real L1->L5:** musgo -> água -> pedra morta -> água negra ->
cristal; lanternas 3 -> 2 -> 2 -> 1 -> 0; cor quente-fria -> fria -> fria-roxa.

---

## C) Asset sourcing strategy

| categoria | rota | porquê |
|---|---|---|
| **fundos ilustrados** | **gerar** (>=1920x1080 por camada, 4-5 camadas/nível) | nenhum pack free tem a Heart Tree nem o gótico do `key_art`; e os que há não se podem commitar |
| **tiles de terreno** | **promover** `_source/imagegen_v1` (já no repo, 1254 px) a 256-512 px + 3 variantes | o material já existe; só se está a deitar fora |
| **props / ruínas** | **derivar** de `ruin_block`, `root_overlay`, `moss_overlay` (já em HD) | idem |
| **silhuetas de fundo distante** | **OpenGameArt DARK PLATFORMER (CC0)** | única fonte externa commitável sem risco |
| **UI** | **nada** — a 9H.10/9H.11 fechou a direcção | não é o gargalo; não gastar aqui |
| **VFX** | **runtime**, reaproveitar `vfx_9g` + `scripts/vfx_regiao1.gd` | já feito e aprovado |
| **mobs/bosses** | **não tocar** | o GM diz que estão bons |

---

## D) Hybrid 2D VFX recovery — como se faz na prática

1. **Separar o que é pintura do que é código.** Pintura: fundo, landmark,
   tile, remate. Código: névoa, raios, partículas, luz, rim-light, água.
   Hoje há névoa cozida no fundo — sai.
2. **O fundo passa a camadas de altura de ecrã**, repetidas na horizontal,
   em vez de um panorama único esticado. Resolve o §0.1 de vez e permite
   parallax a sério.
3. **O tile passa a "pintura em placa"**: 256-512 px, bordos pintados, 3-4
   variantes sorteadas por `rng`. O `plataforma.gd` já sorteia o topo
   (`Kit.topo(rng)`) — a infra existe, faltam as peças.
4. **O landmark é uma peça própria**, não parte do panorama: posicionada por
   nível, com a sua própria luz.
5. **VFX por cima de tudo**: raios volumétricos e névoa em 2 profundidades
   são o que "cola" pintura e mosaico. É o passo que separa *ilustração com
   sprites em cima* de *jogo ilustrado*.
6. **Como NÃO recair no mosaico:** regra dos 128 px + proibição de tile sem
   variantes + revisão com `tools/folha_de_contacto.gd`.

---

## E) Execution split (curtas, por ordem)

| # | objectivo | tamanho | depende de |
|---|---|---|---|
| **9H.12C** | **BUGS do GM primeiro.** Reproduzir e corrigir o crash ao sair do L1; alinhar a promessa do salto duplo com a realidade. Nada de arte. | ~20 min | nada |
| **9H.12D** | **Tiles grandes.** `build_region_01_sprite_kit.py` passa a produzir 256-512 px com 3 variantes das fontes que já lá estão; ligar no `regiao1_kit.gd`. Só L1 como piloto. | ~30 min | contrato (§F) |
| **9H.12E** | **Fundo nativo, piloto L1.** Gerar 4-5 camadas de 1920x1080 e trocar o panorama esticado por camadas de altura de ecrã. Medir px-fonte/px-ecrã antes e depois. | ~40 min | 12D |
| **9H.12F** | Alargar 12D+12E a L2-L5 com a progressão da §B. | ~40 min | 12E aprovado |
| **9H.12G** | Landmarks próprios (arco L3, queda L4, Heart Tree L5) + VFX de cola. | ~30 min | 12F |
| **9H.12H** | Passe final: folha de contacto dos 5, EXE, medição de desempenho. | ~20 min | 12G |

---

## F) Stop conditions

**Bloqueiam e precisam do Paulo:**

- **Contrato de geração.** O contrato actual pede *"pixel-art, hard pixel
  clusters, no antialiasing"*. O híbrido 2D exige o oposto. **Mudar isto é
  mudar a direcção de arte da região** — precisa de "sim" explícito.
- **Assets externos não-CC0 num repo público.** Para usar
  PitiIT/Digital Moons/Craftpix é preciso decidir: (a) repo privado,
  (b) ficheiros fora do git, ou (c) só como referência. **Pixsol fica fora de
  qualquer hipótese** (proíbe uso em IA).
- **Custo de disco.** Tiles de 512 px com variantes multiplicam o peso do
  repo e o tempo de import.

**Segue sem aprovação:**

- 9H.12C (bugs) — é correcção, não direcção.
- Medições, provas e reorganização de ferramentas.
- Reaproveitamento das fontes `imagegen_v1` **já aceites** no repo.

---

## Bugs do Game Master — estado da investigação

| queixa | estado | achado |
|---|---|---|
| crash ao entrar no portal no fim do L1 | **por reproduzir** | não há `Portal` no L1 — é a `Porta` (`scripts/porta.gd:69`), que faz `change_scene_to_file("res://scenes/Main.tscn")` dentro do `body_entered`. O L2 carrega **limpo** em headless (240 frames, zero erros), por isso o crash está na **transição**, não na cena de destino. Reproduzir no EXE. |
| L1 fala em double jump mas está desativado | **confirmado** | `EstadoJogo.HABILIDADES_INICIAIS` está **vazio**, mas a legenda do HUD mostra `hud.controls.jump` = "Jump x2" (`en.json:325`), fixo. `koliani.gd:1433` dá 2 saltos só com `tem_habilidade("salto_duplo")`. Ou se dá a habilidade no L1, ou a legenda passa a ser dinâmica. |
| backgrounds com blur | **causa provada** | §0.1 |
| níveis pobres / pixel art a mais | **causa provada** | §0.2 e §0.3 |
| bosses e mobs bons | — | não tocar |

---

## TOP 10 NEXT ACTIONS

1. Reproduzir o crash na saída do L1 no EXE de Windows (9H.12C).
2. Decidir salto duplo: dar no L1 ou legenda dinâmica (9H.12C).
3. Obter o "sim" do Paulo ao **novo contrato de geração** (pintura com
   anti-aliasing, sem "hard pixel clusters").
4. Decidir a política de assets externos num repo público.
5. Reescrever `build_region_01_sprite_kit.py` para 256-512 px + variantes.
6. Ligar os tiles novos no `regiao1_kit.gd` e provar no L1.
7. Gerar as camadas de fundo do L1 a 1920x1080 nativas.
8. Trocar o panorama esticado por camadas de altura de ecrã.
9. Medir px-fonte/px-ecrã antes/depois e registar.
10. Folha de contacto L1-L5 para o GM aprovar antes de alargar.

## BEST FREE ASSET CANDIDATES

| pack | autor | link | licença | serve para | commitável? | IA? |
|---|---|---|---|---|---|---|
| DARK PLATFORMER | OpenGameArt | https://opengameart.org/content/dark-platformer | **CC0** | silhuetas de fundo, espinhos, caixotes. BGs só 1024x768 — **baixo demais** para panorama | **SIM** | sem restrição |
| Free Parallax Forest Background (Seamless) | Digital Moons | https://digitalmoons.itch.io/parallax-forest-background | free comercial, **crédito pedido** | **referência de formato**: pintado à mão, 1920x1080, camadas — é exactamente o alvo | **não sem decisão** | autor declara "no generative AI was used" -> tratar como *não usar como input de IA* |
| FREE 2d Fantasy Platformer Asset Pack | PitiIT | https://pitiit.itch.io/free-2d-fantasy-platformer-asset-pack | free comercial, **proíbe redistribuir** | props/tiles — mas é **pixel art**, contra a direcção | **NÃO** (repo público) | sem restrição explícita |
| Fantasy Platformer Adventure Pack | Pixsol | https://pixsol-ok.itch.io/fantasy-platformer-adventure-pack | free comercial, proíbe redistribuir | **REJEITADO**: 16x16 px, o pior estilo possível para o que queremos | **NÃO** | **PROÍBE uso em criações de IA** |
| Free Parallax 2D Backgrounds | Free Game Assets (Craftpix) | https://free-game-assets.itch.io/free-parallax-2d-backgrounds | comercial sim; redistribuição **por confirmar** | camadas 1920x1080 ilustradas | **verificar antes** | "no generative AI was used" |
| Soulslike Pixel Art UI Kit | KRYN STUDIO | itch.io | CC0 | UI — **não é o gargalo**, a 9H.10/11 fechou a direcção | sim | — |

## WHAT SHOULD BE AI-GENERATED

- As **4-5 camadas de fundo por nível**, a >=1920x1080 **nativos** (nunca upscale).
- As **variantes** dos tiles de terreno (3-4 por peça) a 256-512 px.
- Os **landmarks** próprios: arco do L3, queda do L4, Heart Tree do L5.
- Tiles de **rocha corrompida** do L5.
- **Nunca** a partir de packs que proíbem IA (Pixsol) nem de arte de terceiros.

## WHAT SHOULD STAY RUNTIME/VFX

- Névoa (em **2 profundidades**), raios de luz volumétrica, poeira, faíscas.
- Rim-light de luar e gradiente de valor nos blocos (**já feito, 9H.11**).
- Luz das lanternas (halo aditivo, `Kit._brilho_quente`) e luz do chefe.
- Linha de água e reflexos.
- Tinta de mood por perfil e o violeta da corrupção do L5 (**já feito**).
- Pulsar da Heart Tree e das raízes.

## READY FOR EXECUTION

- **YES** para **9H.12C** (bugs do GM) — sem dependências, arranca já.
- **NO** para **9H.12D em diante** até o Paulo responder aos pontos 3 e 4
  do TOP 10 (contrato de geração e política de assets externos).
