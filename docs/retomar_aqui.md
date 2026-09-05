# Retomar aqui — 5 de setembro de 2026 (sessão da madrugada)

> **LEIA PRIMEIRO.** O topo é a **fila de pedidos do Paulo por fazer**.
> A ordem é a do painel, que é dele:
> <https://claude.ai/code/artifact/875b9e60-ef1b-4866-ad8f-d273169da411>

---

# ⇢ COMEÇA AQUI

O pedido **"uma mecânica nova por nível"** está **implementado**: as 100
linhas da `MECANICA_DO_NIVEL` têm dona, **zero provisórias** (eram 52 no
início da sessão). Os sete "grandes" ficaram todos feitos, incluindo o
gancho e a gravidade invertida.

**O que falta é JOGAR.** Nada disto foi playtestado -- as três bancadas
garantem que se constrói e que as regras mordem, não que sabe bem:

```bash
"...Godot..._console.exe" --headless --script res://tests/run_tests.gd
"...Godot..._console.exe" --headless --script res://tools/verifica_actores_novos.gd
"...Godot..._console.exe" --headless --script res://tools/verifica_jornada.gd
```

Por ordem, o que eu faria a seguir:

1. **Jogar os níveis das mecânicas novas** e afinar números. Os que mais
   podem estar mal: `gancho` (53) -- a força do balanço e o empurrão ao
   largar; `invertido` (67) -- o pé-direito da sala e o sítio das placas;
   `conves` (78) e `engrenagens` (56) -- é a peça mais nova e a única que
   depende de a Koliani se aguentar num chão a rodar.
2. **O `tools/bot_gauntlet.gd` continua avariado** (acusa softlock no
   Nível 1, a 150 px do spawn). Enquanto assim estiver, nenhuma câmara
   pode ser dada como verificada sem ser à mão. Está no painel como
   crítico, e agora custa mais: são 26 câmaras novas por verificar.
3. **Arte própria dos 100 chefes** -- o pedido que estava a seguir na fila
   (ver mais abaixo).

Duas coisas ficaram de fora **de propósito** e estão escritas: escalar
paredes e agarrar bordas continuam a assumir a gravidade normal (não
aparecem na sala do N67), e o `PontoGancho` só engata no ar.

---

# A sessão da madrugada de 5 set 2026 — 26 mecânicas novas

**52 provisórias → 0.** Sobreposição média de câmaras entre níveis
seguidos: **0.275 → 0.224** (menos 19%). Detalhe nível a nível em
[`mecanicas_por_nivel.md`](mecanicas_por_nivel.md), que ficou com uma
secção por leva.

## O que entrou

**Câmaras de composição** (actores que já existiam, regra da sala nova):
`martelos` (33) · `escuro` (40) · `bifurcacao` (52) · `raizes` (55) ·
`varredura` (79) · `prensa_fogo` (81) · `correnteza` (83) · `sem_chao` (87) ·
`gemea` (88) · `catapulta` (91) · `salvas` (92) · `assalto` (94) ·
`memoria` (96) · `revisao` (97) · `pulsacao` (80) · `ciclo` (72) ·
`mausoleu` (74) · `rosas` (51).

**Actores novos** (todos só script, constroem o próprio corpo):
`Iman` (60) · `ChaoQuente` (82) · `Ceifa` (75) · `PlataformaOlhar` (86) ·
`Ariete` (93) · `ZonaGelo` (41) · `ZonaEstado` (45/48) ·
`ZonaEscuridao` (40/49) · `ZonaSemAr` (38) · `Serpente` (77) ·
`SombraAtrasada` (69, e o reflexo do 84) · `AmeacaQueAvanca` (65) ·
`ZonaSemPoder` (98).

**Regras novas de bicho** (`DemonioBase`): `divide_em` (58),
`so_tiro` (73), `so_mexe_sem_olhar` (68).

**Coisas dela**: `veneno` e `frio` (os primeiros ESTADOS que a apanham a
ela — os inimigos já tinham), atrito de chão (`acel_escala`, o gelo) e a
habilidade **planar** (N63), que era um dos "grandes" e afinal são oito
linhas.

**Quatro dos sete grandes fechados**: planar (63), sombra com atraso (69),
ameaça que avança (65 — a máquina que funde 29/42/65) e perder uma
habilidade por sala (98).

## Três bugs a sério que a bancada apanhou

1. **As áreas construídas em código nunca lhe tocavam.** Todas ficavam com
   a máscara de omissão (layer 1, o mundo) e a Koliani vive na **layer 2**.
   `Iman`, `ChaoQuente`, `Ceifa`, `ZonaGelo`, `ZonaEstado`, a zona do
   `Ariete` — e a `CorrenteLateral`, assim desde que nasceu. A verificação
   das jornadas dizia "TUDO OK" na mesma: os níveis construíam-se, as
   mecânicas é que não existiriam a jogar. A `Armadilha` já fazia isto
   certo (`collision_layer = 0`, `collision_mask = 2`) e é o molde.
2. **`PlataformaOlhar._aplicar(bool)` colidia com o `_aplicar()` da
   `Plataforma`.** O script não compilava e, outra vez, "TUDO OK".
3. **As 16 estreias de 5 set não estavam em pool nenhuma** — apareciam uma
   vez em 100 níveis e nunca mais. As pools das regiões VII-XX eram as
   mesmas 12 câmaras de sempre, e era isso que fazia o 2.º acto saber ao
   1.º.

## Armadilhas de bancada (não voltar a descobrir)

- **Medir FRAMES em headless não mede nada.** Os frames correm o mais
  depressa que conseguem: 30 frames podem ser 30 ms. Esperar TEMPO
  (`create_timer`), e com folga — a física anda ~10% atrás do relógio.
- **`await physics_frame` num `SceneTree` em `--script` fica pendurado.**
  O `process_frame` é que anda.
- **A Koliani não fica onde a põem**: no `_ready` salta para o checkpoint
  do save. Sem limpar isso e sem chão por baixo, a bancada mediu a **queda
  no vazio** e "provou" um veneno que tirava 158 de vida em 1.2 s. Pousada,
  tira 4.
- **Um actor que toque num autoload pelo IDENTIFICADOR não se consegue
  testar** em `--script`. O `ariete.gd` e a `zona_sem_poder.gd` passaram a
  falar com eles por `/root/<Nome>` e por `get`/`set`/`has_signal` — é o
  que deixou provar o que mais interessa nesses dois.

## O CI corre mais duas bancadas

`.github/workflows/ci.yml`: a suite, `verifica_regras_bicho.gd`,
`verifica_actores_novos.gd` (42 asserções) e `verifica_jornada.gd`.

---

# ⚠ Continua por fazer: arte própria dos 100 chefes

Estava a ser o próximo pedido quando o Paulo mandou seguir antes com as
mecânicas. **Não se lhe tocou nesta sessão.** O passo imediato continua a
ser ligar os 10 chefes das Regiões II e III à tabela `CHEFES` de
`tools/gerar_chefes_anim.py` (as funções `extras` já estão escritas; falta
a entrada no dicionário com plano de corpo, proporções e paleta). Planos de
corpo já medidos: `_carcereiro`, `_ignivar` e `_primeiro_prisioneiro` são
**humanoide**; `_dama_guilhotina`, `_irmaos_condenados`, `_voltaris` e
`_sacerdotisa_lunar` são **flutuante**; `_sino_vivo` é **objeto**;
`_aerion` é **alado**; `_vyrak` é **quadrupede**. Detalhe na secção "EM
CURSO — arte própria dos 100 chefes", mais abaixo.

---

# Os três pedidos de 5 set 2026 — **FECHADOS**

### A. Botão de ação na página de prioridades — FEITO

Os blocos saíram. O painel é uma lista só, numerada 1, 2, 3…, e esse número
**é** a ordem de desenvolvimento: por linha há um botão de pôr em primeiro,
setas de um degrau e um campo onde se escreve a posição. O que fica *feito*
ou *fora* desce para o fim e deixa de gastar número.

### B. Todo o pedido singular entra na lista — FEITO, e é regra

Regra permanente, ver [[pagina-prioridades-koliani]]. E **actualizar o
painel a cada pedido que se fecha**, não no fim da sessão.

### C. Música do chefe no último checkpoint — FEITO (`9ea1576`)

A fogueira mais perto da arena marca-se como a do chefe e chama
`Musica.boss()` ao ser acesa; antes a cama de combate só entrava ao 1.º
golpe (`ChefeBase.provocar`). Se a cena recarregar com essa fogueira **já**
acesa (morreu no chefe), a música volta logo.

Duas coisas que custaram e não vale a pena redescobrir:

- a decisão corre no **fim do frame** (`call_deferred`). O chefe só entra no
  grupo `chefes` no `_ready` dele, e o `main.gd` só põe a cama de ambiente
  depois dos filhos — tocar mais cedo era pisado por ela.
- a escolha da fogueira vive em **`scripts/fogueiras.gd`**, lógica pura sem
  autoloads. Dentro do `checkpoint.gd` o corredor de testes não a conseguia
  carregar (em `--script` não há `EstadoJogo`) e o teste **passava em
  silêncio sem verificar nada** — só se deu por isso ao partir a asserção
  de propósito.

Medido na Floresta Putrefata: das 4 fogueiras só a que está a 220 px da
arena se marca (a seguinte está a 1861 px) e acendê-la troca para
`boss_05.ogg`. O gerador põe sempre um checkpoint mesmo antes do chefe e
espaça os outros 3000 px, portanto "a mais perto" é de confiança.

---

---

# Uma mecânica de estreia por nível — **BASE FEITA** (5 set 2026, `9e844ee`)

O Paulo: *"o meu objetivo é tornar o jogo mais variado e menos repetitivo,
100 níveis a fazer a mesma coisa e o mesmo padrão cansa o player"*, e deu
luz verde para avançar como eu achasse.

O que fazia os 100 níveis saberem ao mesmo **não era só faltarem
mecânicas** — eram três coisas, e as três estão medidas:

1. o **sorteio**: cada nível tirava câmaras à sorte da pool da sua região, e
   os 5 níveis de uma região partilham a pool. Do nível 30 em diante todos
   viam o mesmo saco;
2. **todos** os níveis tinham torres E poços E pilares (o ramo vertical
   dispara de 2 em 2 e sorteava entre as três);
3. **todos** tinham um pouco de arena, corredor, cripta e forquilha.

Agora: `MECANICA_DO_NIVEL` (100 entradas) — cada nível estreia uma mecânica
que entra garantidamente, nada aparece antes do nível onde estreia (isto
substituiu o `TIER_FLAVOUR`), as estreias recentes pesam a dobrar, e cada
nível tem **uma** família vertical e **uma** sala especial, em ciclos de 3 e
4 desfasados (o padrão só volta de 24 em 24).

## Medido, não opinado

O `verifica_jornada.gd` calcula agora a sobreposição de Jaccard das câmaras
entre níveis **seguidos**:

| | |
|---|---|
| gerador antigo | **0.372** |
| + estreia garantida | 0.344 |
| + uma vertical por nível | **0.288** — 23% menos |

**Duas tentativas que PIORARAM** (não repetir): dar a cada nível um "menu"
de 5 câmaras da pool da região (0.357) e limitar o forçador de variedade à
sala especial do nível (0.337). As duas cortam tipos DENTRO do nível, e um
nível mais pobre não é um nível mais distinto.

## Segunda passagem: +16 câmaras (`94e997d`)

Passaram a ser **48 dos 100** com estreia própria. Nenhuma precisou de arte
nova, e três actores que estavam no repo **sem nenhuma câmara os usar**
ganharam sala: `Vitral`, `ParaRaios` e `PlataformaEspectral`. Actor novo (só
script, constrói a própria área como o `Checkpoint`):
`scripts/corrente_lateral.gd` — a `CorrenteAr` só soprava para cima.

`lava_sobe` · `mare` · `espectral` · `vitral` · `para_raios` · `bombas` ·
`queda` · `tapete` · `orbita` · `areia` · `grav_baixa` · `placa` ·
`circuito` · `anel` · `horda` · `chuva`. Sobreposição: **0.276**.

### Dois softlocks meus, apanhados antes de sair

1. O nó de colisão da `ZonaGravidade` chama-se **`CollisionShape2D`**, não
   "Col". O redimensionamento nunca corria e a bolsa ficava com os 300x300
   de omissão — na `grav_baixa` isso era fatal, porque os vãos só se
   atravessam com a gravidade baixa. Há agora um `_esticar_zona()`.
2. Na `areia` a escada de saída ficava **dentro** da bolsa de 1.5x, onde um
   salto sobe ~53 px em vez de 79. Passou para fora, com degraus de 60 px.

### ⚠ NÃO verificado: softlocks nas câmaras novas

Um crivo estático de vãos acusou **91 dos 100** níveis — as plataformas
móveis não se modelam assim, e é a mesma razão pela qual o
`verifica_alcance.gd` desliga a jornada de propósito. E o
**`tools/bot_gauntlet.gd` está avariado**: acusa softlock no Nível 1, a
150 px do spawn. Enquanto assim estiver, nenhuma câmara nova pode ser dada
como verificada — está no painel como item crítico.

### Armadilha de ferramenta

O `shot_plataforma.gd` não punha o `indice_nivel` a partir da cena, portanto
fotografava sempre a jornada do nível onde o save tinha ficado. **Uma
bateria inteira de smoke-tests desta sessão não testou nada por causa
disso.** Corrigido; o `MAPA_CAMARAS=1` foi o que o denunciou.

## Os 14 "grandes" ficaram em 7 (decidido a 5 set 2026)

O Paulo cortou **Nadar (N37)**, **Gravidade a rodar 90° (N90)** e
**Perseguidor invisível (N89)**, e aceitou as duas fusões. Detalhe e razões
em `docs/mecanicas_por_nivel.md`. Sobram, por ordem de tamanho:

1. **Gancho (N53)** — o único grande. **Não se corta**: é a única que muda
   os 100 níveis e não só o dela.
2. Inverter a gravidade à vontade (N67) · 3. Ameaça que avança
   (N29/N42/N65, uma máquina com três caras) · 4. Cenário reescreve-se
   (N70) · 5. Sombra com atraso (N69) · 6. Planar+Asas (N15/N63, pequeno) ·
   7. Perder uma habilidade por sala (N98, pequeno).

Se for preciso cortar mais um, o candidato é o **N70** — é o que menos se
nota a jogar, porque acontece onde já não se está a olhar.

## O que falta

52 entradas continuam marcadas `# ~` — **provisórias**: repetem uma câmara
porque o actor próprio ainda não existe. São a lista de trabalho: trocar uma por uma
mecânica nova não mexe em mais nada. Decisões tomadas com ele: não se corta
nenhum dos 14 "grandes" (agrupa-se Planar+Asas, e Torre-a-desabar/Avalanche/
Queda numa máquina só); estreia **mansa até ao 30, dura no 2.º acto**;
jornada procedural fica. A proposta completa está em
`docs/mecanicas_por_nivel.md`.

> ⚠ **Número errado que estava na proposta:** ela dizia que 99 níveis eram
> salas à mão (`corredor = false`). Medido: é **1** (`O_Trono_de_Zeriko`).
> Por isso a tabela não custou trabalho manual nenhum.

## GOTCHA que custou duas vezes no mesmo dia

Em `--script` **os autoloads não existem como identificador**. Tocar numa
classe que os use (`GeradorCorredor`, `Checkpoint`) faz o script de teste
**falhar a compilar EM SILÊNCIO** — o `verifica_jornada` chegou a dizer
"TUDO OK" tendo verificado 2 níveis em 100, e um teste da suite passou sem
medir nada. A regra: nas ferramentas `--script` e nos testes, ler do **nó**
(`ger.get("_estreia_cam")`) ou do **código-fonte** (`_fonte(...)`), nunca da
classe. E provar sempre que a asserção morde, partindo-a de propósito.

---

# Seletor de níveis — **FEITO** (5 set 2026, `5909970`)

Era o último ecrã todo desenhado por código. Passa a vestir as peças da
HUD (`scripts/ui.gd`, pack anokolisa recolorido): cartão em moldura de
pedra tingida pela região com **interior escuro** por dentro, selo do
número igual ao do cabeçalho, fitas e pastilhas em `selo`, setas com
`ico_seta_*`, rodapé de madeira com o JOGAR em placa magenta, e a barra de
progresso na calha + enchimento das barras.

Bancada nova: `tools/shot_seletor.gd` (precisa de janela, `--screen 1`).

## Duas armadilhas da nine-patch (não voltar a descobrir)

1. **`painel_madeira.png` não era um painel — eram quatro.** Na folha do
   kit os painéis vêm colados uns aos outros e o quadrado da madeira é
   **48x48**, não 64x64 como o do pergaminho; o recorte levava meia coluna
   e meia faixa do lado, e no Godot desenhava-se **aos bocados** (os botões
   do rodapé saíam como três blocos soltos). Divisórias medidas na folha:
   `x = 16 | 64 | 79`, `y = 224 | 272 | 287`. Corrigido em
   `tools/gerar_ui.py`; guardado por `teste_paineis_nao_trazem_o_vizinho`.
2. **Abaixo de 60 px de altura a nine-patch dos painéis grandes colapsa** —
   são 30 px de moldura de cada lado (`UI.MARGEM_PAINEL`). Peças mais
   baixas usam o `selo` (15 px de moldura, aguenta até 30 px).

E uma de desenho: o brilho de selecção teve de sair para um **nó separado
por baixo** do cartão — uma `StyleBoxTexture` não tem sombra, e era a
sombra que fazia o cartão do meio saltar à frente dos vizinhos.

---

# ⚠ EM CURSO — arte própria dos 100 chefes

**O Paulo aprovou o conceito e alargou o pedido a TODOS os níveis:**

> "Adorei o conceito destes bosses, quero que faça todos assim desde nível
> 1 a 100!" · "Baseia-se no guia até nível 100 para nomes dos bosses e lore
> story."

Fontes de lore: [`niveis.md`](niveis.md) (1–30) e
[`plano_niveis_31_100.md`](plano_niveis_31_100.md) (31–100). São **100
identidades distintas** (47 `boss.*` + 53 `guard.*` em
`scripts/catalogo_campanha.gd`) — o guia dá um chefe com nome a cada nível.

## Estado

| | |
|---|---|
| **Feitos e afinados** | Região I (5): `ghorak`, `morvanna`, `rainha_aracnidea`, `entrevane`, `coracao_putrefacto` |
| **Escritos, por ligar à tabela `CHEFES`** | Região II e III (10): `_carcereiro`, `_ignivar`, `_dama_guilhotina`, `_irmaos_condenados`, `_primeiro_prisioneiro`, `_sino_vivo`, `_aerion`, `_voltaris`, `_sacerdotisa_lunar`, `_vyrak` — as funções `extras` já estão em `tools/gerar_chefes_anim.py`, **falta a entrada no dicionário `CHEFES`** (plano de corpo, proporções, paleta) |
| **Por desenhar** | 85 (regiões IV a XX) |

> ⚠ **As cenas ainda NÃO apontam para os rigs novos.** O jogo está
> exactamente como estava. A troca do `rig = ` nas 29
> `scenes/actors/Chefe*.tscn` é só quando estiver tudo pronto — meio
> caminho seria uma regressão visível.

## As ferramentas

| ficheiro | o que é |
|---|---|
| `tools/chefes_desenho.py` | motor. Tudo é **polígono** (até as elipses) — roda de graça e o PIL preenche sem antialiasing, portanto sai pixel-art limpa. Contorno de 1 px, **risco interno por peça**, luz de topo. Desenha pequeno (~56 px) e sobe **x2 NEAREST** |
| `tools/chefes_corpos.py` | os **7 planos de corpo**: humanoide, flutuante, aracnídeo, serpente, alado, quadrúpede, objeto. Cada peça leva uma `tag` |
| `tools/chefes_gaits.py` | o "andar" de cada plano. O ataque reparte-se em **recuo (telegrafo) · golpe · recuperar** |
| `tools/gerar_chefes_anim.py` | os chefes + as ajudas de adereço: `nucleo`, `cranio`, `capuz`, `elmo`, `mitra`, `chifres`, `asas`, `corrente`, `disco`, `tentaculos`, `foice`, `martelo`, `espada`, `cutelo`, `lanca`, `escudo`, `cajado`, `coroa`, `chapeu_alto`, `cristais`, `engrenagem`, `chama`, `veios` |

```bash
python tools/gerar_chefes_anim.py --preview   # + folha de contacto
python tools/gerar_chefes_anim.py ghorak      # só um, para iterar
"...Godot..._console.exe" --headless --import
```

## Lições que custaram tempo (não voltar a descobrir)

- **Sem risco interno por peça o boneco cola-se numa mancha só.** O
  `desenhar()` faz `outline=escurecer(cor, 0.45)` em cada polígono.
- **A cabeça genérica tem `z` alto e fica por cima do capuz** → as peças
  têm `tag` e há `tirar(pecas, "cabeca", "pescoco")` / `pintar(...)`.
- **Um ângulo de repouso tem de ir para a JUNTA, não só para o desenho.**
  Foi o bug das patas da aranha: o joelho nascia por baixo da barriga.
- **O núcleo roxo tem de ser PEQUENO** — à primeira o chefe lia-se como
  "boneco com uma bola roxa".
- **O osso nunca vai no tom cheio** (`escurecer(osso, ~0.4)`): era a coisa
  mais clara do sprite e roubava o olho ao núcleo.
- Não apagar peças que SÃO o lore (o rosto humano da Rainha Aracnídea).
- O jogo normaliza o chefe pela **caixa útil do frame `idle`**, não pela
  célula — logo o ar à volta na tira não faz mal nenhum.

## Ordem de trabalho

1. Os três pedidos novos aí em cima (A, B, C).
2. Ligar os 10 da Região II/III à tabela `CHEFES` e ver a folha de contacto.
3. Desenhar as regiões IV a XX (85 chefes), a comitar por região.
4. Só no fim: trocar o `rig = ` das cenas, apontar os arquétipos dos níveis
   31-100 e creditar em `assets/sprites/pixel/CREDITS.md` como **arte
   própria (CC0 nossa)**.

---

# BLOCO 5 (b) — UI e indicador de nível — **FEITO** (4 set 2026, `20d3d38`)

Não foi preciso descarregar nada: o kit certo já estava no repo, do mesmo
pack **anokolisa** que dá o terreno da floresta (`HUD/Base-01.png`).

- **`tools/gerar_ui.py`** — recorta e **RECOLORE** as peças para a paleta
  gótica: mede a luminância de cada pixel e mapeia-a numa rampa de 5 tons.
  Um `modulate` não servia (multiplica; sobre bege claro dá sempre pastel).
  Sai tudo a **3x NEAREST** porque uma `NinePatchRect` não escala os cantos.
  O **coração** e o **enchimento das barras** são arte própria — o kit não
  traz coração e os enchimentos dele têm 2-4 px de altura.
- **`scripts/ui.gd`** (`class_name UI`) — fábrica de painéis, calhas, barras
  e ícones.
- **Cabeçalho de nível** (é o "indicador de nível"): placa de pedra tingida
  com a cor da região, selo com o número, região + passo (3/5), nome do
  nível, caveira + chefe, e pastilhas de progresso na região.
- Barra do chefe numa placa de sangue com caveira, contador de essência com
  losango, botões WEAPONS/ARMOR e o aviso do topo na mesma pedra.
- Bancada: **`tools/shot_hud.gd`** (precisa de janela; `-- <nivel> <png>
  [chefe]`). Limpa o checkpoint de propósito — sem isso a Koliani nascia
  dentro do líquido mortal do save anterior e o PNG saía com a vida a zero.

> ⚠ **GOTCHA que custou uma tarde.** O enchimento das barras **não pode ser
> a stylebox "fill"**: com uma `StyleBoxTexture` ali, a barra ficava EM
> BRANCO conforme a altura — a de Energia (18 px) desenhava, a de Vida
> (26 px) não desenhava nada, nem em `STRETCH` nem em `TILE`, e uma
> `StyleBoxFlat` no mesmo sítio desenhava sempre. É um `NinePatchRect`
> FILHO, que o `UI.ajustar_barra()` redimensiona.

## O buraco que apareceu pelo caminho: 14 regiões sem nome

As tabelas de região do `seletor_niveis.gd` (`WORLD_KEY`, `COR_REGIAO`,
`FUNDO_REGIAO`) tinham ficado com **6 entradas** quando a campanha passou a
**20 regiões** — da 7.ª em diante o carrossel dizia **"?"** e pintava tudo
de cinzento. O nome (chave i18n) e a cor passam a viver em
`EstadoJogo.REGIOES` (campos `chave` e `cor`, tirados do `cor_luz` do 1.º
nível de cada região), +14 nomes nos 6 idiomas, e `FUNDO_REGIAO` tem agora
uma arte por região. Testes novos: `teste_regioes_tem_nome_e_cor` e
`teste_pecas_de_ui_existem`.

---

# BLOCO 6 (assets e licenças) — **FECHADO** (4 set 2026, `41f9f85`)

O equivalente grátis do portal da Frostwindz já estava em disco: o **"Pixel
FX Pack" do CodeManu/DavitMasia é DOMÍNIO PÚBLICO** ("no credit required",
diz o `README.txt` do pack) e traz um vórtice de partículas de 64 frames.
`tools/gerar_fx_portal_balas.py` recolore-o para o magenta da casa
(`props/portal.png`, 32 frames de 64x64) e o `scripts/portal.gd` corre-o a
18 fps — o miolo era um oval `Polygon2D` a rodar dentro de um `Line2D`, que
se lia como feito por código. O portal de **saída** anda ao contrário e mais
devagar, para se distinguir do de entrada sem legenda. Se a tira faltar, o
desenho por código volta.

> No painel de prioridades os itens do **bloco 3** (aura, candeeiros,
> escudo) ainda aparecem como POR FAZER, embora estejam feitos desde a
> sessão anterior — são os interruptores dele, não lhes toquei.

---

# BLOCO 3 (projécteis, aura, luz e escudo) — **FECHADO** (4 set 2026)

Os quatro pedidos dele deste bloco estão feitos.

## Laser roxo do Wenrexa — `2b3dae9`

`tools/gerar_fx_laser.py` recorta o pack **Wenrexa "Laser2020"** (CC0, uso
comercial, sem crédito obrigatório). O tiro dela é o cometa magenta
(`13.png` -> `fx/laser_roxo.png`) e o Kamehameha é o raio aos ziguezagues
(`22.png` -> `fx/laser_raio_roxo.png`), que substituiu os três `Polygon2D`
desenhados à mão — eram a parte que se lia como feita por código.

> ⚠ **A escolha dele não bate certo com os nomes dos ficheiros.** Ficou
> registado que escolheu "o último da primeira fila da capa" e que era um
> "cometa magenta de cauda comprida". A capa mostra 10 por linha e os
> ficheiros também andam de 10 em 10 — mas o **10.º é uma bola AMARELA**.
> Foi-se pelo conteúdo e pelo pedido escrito ("roxo com brilho"). **Se ele
> disser que não é este, é uma linha na tabela `LASERS` da ferramenta** —
> há 66 no pack, e a folha de contacto tira-se com
> `tools/gerar_fx_laser.py` + um mosaico.

São glows de alta resolução, **não pixel-art**: os nós desenham-nos com
`texture_filter = 2` (LINEAR). A Nearest sairiam aos degraus. O tiro deixou
de ter tira de frames — o "vivo" é o pulsar da escala.

## Aura roxa — `2b3dae9`

Duas metades no `Koliani.tscn`: o **`Sprite/Halo`** (degradé radial aditivo,
por trás do corpo) que se vê, e a **`LuzAura`** que já lá estava — agora
roxa a sério e com força — que ilumina o cenário. Respiram em conjunto e
**acendem** quando ela golpeia, dá dash ou lança (`_acender_aura`); o 4.º
golpe do combo e o Kamehameha são os que mais a fazem estoirar.

## Escudo de energia — `2b3dae9`

O bloco do escudo estava atrás de `RIG == "codigo"`. Com o **Shadowblade**
activo — que nem tem pose de defesa no atlas — ao carregar em defender **não
aparecia escudo nenhum**. Passou a `RIG != "cavaleiro"` (esse traz o escudo
desenhado nos frames). Por cima da placa entra a **cúpula de energia roxa**:
cresce ao levantar o escudo, respira, e dá um clarão a cada bloqueio.

Bancada: `tools/shot_aura_escudo.gd` (modo `escudo` / `tiro`; **precisa de
janela**). Gotcha guardado lá dentro: **`_defendendo` é recalculado do input
todos os frames** — pôr-lhe a bandeira à mão não serve de nada, tem de se
premir a acção (`Input.action_press("defender")`).

## Candeeiros e tochas — `8bf1898`

Dois props do **Ansimuz**, dos mesmos packs de onde já vêm fundos do jogo,
recortados por `tools/gerar_luzes.py`: o **poste gótico de três lanternas**
(GothicVania Town) e a **tocha de parede animada** (Cold Corridors).

A distribuição é feita em **código** (`nivel_com_chefe.gd::_iluminar`) e não
nos 100 `.tscn`: a maior parte do percurso é a JORNADA, gerada em cada
arranque — luzes postas na cena não apanhavam nada dela. Varre-se o percurso
em **colunas de 760 px** e escolhe-se, para cada uma, a plataforma mais
próxima que sirva.

Só plataformas **estáticas** (o script tem de ser mesmo o `plataforma.gd`):
numa flutuante ou quebradiça a luz ficava para trás. As **tochas** escolhem-se
pela grossura **visual** (`altura_visual`) — medidas pela colisão (22-70 px)
nenhuma plataforma chegava ao limiar e nunca saía nenhuma.

`tools/verifica_luzes.gd` conta as luzes por nível e mede o maior vão sem
luz. **Medição actual: 100/100 com luz; 98/100 com o maior vão < 3000 px.**

## Vidas — `9b8a78e`

`VIDAS_INICIAIS` 3 -> **5**, e **+1 por nível** passado. No **hardcore não
cresce** (lá as vidas são o limite do run) e o `reiniciar_run` repõe as
vidas do ponto onde ele vai (`vidas_de_partida`), não as 5 secas. Tecto de
99 só para o `x%d` do HUD. **A campanha inteira dá ~105 vidas** — se isso
amolecer de mais o fim, o sítio para afinar é `VIDAS_POR_NIVEL`.

---

# BLOCO 4 (infra) — **O APK ANDROID PASSA**, falta o switch do Pages

**O job do Android NUNCA passou — nem no run 1.** A nota "falha desde o run
264" estava errada: conferido pela API do GitHub, com amostras de 25 em 25
desde o run 1, todas dão `failure`. Não é uma regressão, é uma coisa que
nunca chegou a funcionar.

**Os logs deste repo pedem sessão iniciada** — de fora só se vê "Process
completed with exit code 1". As **anotações**, essas, são públicas: o CI
passou a despejar as últimas 25 linhas do export como `::error::` e o
ambiente (ANDROID_HOME, java, build-tools, apksigner, templates) como
`::warning::`. **É por aí que se lê o que se passa, em**
<https://github.com/paulogomesextp/koliani/actions>.

## O que era, afinal — duas coisas, e nenhuma era o que se suspeitava

Assim que a anotação passou a levar o log inteiro, o Godot disse-o por
palavras dele, uma de cada vez:

1. **`A valid Java SDK path is required in Editor Settings`.** A imagem
   `godot-ci` traz o OpenJDK 17 mas com o **`JAVA_HOME` vazio**, e o Godot 4
   não procura o `javac` no PATH — lê `export/android/java_sdk_path` das
   editor settings. O job passa a derivar a raiz do JDK do `javac` real e a
   escrever lá **as duas** definições (Android SDK e Java SDK).
2. **`ETC2/ASTC texture compression is required for Android export`.**
   `textures/vram_compression/import_etc2_astc=true` no `project.godot`.
   Custa uma variante comprimida a mais por textura no `.godot` (que não vai
   para o git) e um `--import` mais demorado.

**Nada disto era o que se suspeitava.** Os templates de Android estavam
todos instalados, o `apksigner` estava em `build-tools/33.0.2` e o
"Could not find version of build tools that matches Target SDK" é só um
aviso. **A parte difícil foi conseguir LER o erro**, não corrigi-lo.

**Resultado (run #332): APK de 100 MB, no Release
[`android-latest`](https://github.com/paulogomesextp/koliani/releases/tag/android-latest).**
Link fixo, a par do `win-latest` — o Paulo descarrega no telemóvel e
instala.

Ao mesmo tempo entraram as duas saídas públicas que faltavam:
- Release de tag rolante **`android-latest`** com o APK (a par do
  `win-latest`);
- **GitHub Pages** com o build Web (`enablement: true` liga o Pages sozinho
  na primeira vez). É a única via grátis para o iPhone.

### ⚠ UMA COISA QUE SÓ O PAULO PODE FAZER

O `GITHUB_TOKEN` **não consegue criar** o site de Pages (limitação conhecida
do `configure-pages`; o erro é `Resource not accessible by integration`).
Basta ir uma vez a **Settings → Pages → Build and deployment → Source:
GitHub Actions** e a partir daí cada push publica o jogo numa página que abre
no iPhone. Até lá o job fica `continue-on-error`, para não pintar o CI de
vermelho a cada push. Já está apontado no painel de prioridades.

### GOTCHA que vale ouro: como depurar este CI de fora

Os **logs** dos Actions deste repo pedem sessão iniciada (`Must have admin
rights`, mesmo sendo público). As **anotações** não:

```bash
curl -s "https://api.github.com/repos/paulogomesextp/koliani/actions/runs/<ID>/jobs"
curl -s "https://api.github.com/repos/paulogomesextp/koliani/check-runs/<JOB_ID>/annotations"
```

Duas armadilhas que já morderam:
- **o GitHub só CRIA as primeiras dez anotações de cada nível por passo.**
  Uma linha por anotação faz o essencial cair fora — manda-se **tudo numa
  anotação só**, com as quebras em `%0A`;
- correr o export com `-v` enche o log de `Loading resource:` e o `tail`
  passa a apanhar só ruído.

**Estado do diagnóstico:** o ambiente do CI está BOM —
`ANDROID_HOME=/usr/lib/android-sdk`, `apksigner` em `build-tools/33.0.2`,
OpenJDK 17. Não é SDK nem Java. As linhas reais que já saíram foram
"Could not find version of build tools that matches Target SDK, using 33.0.2"
(aviso, não fatal) e "Unable to load fontconfig" (ruído de headless). **A
próxima sessão pega o log inteiro na anotação e resolve.**

---

# BLOCO 5 (b) — UI e indicador de nível: o levantamento já está feito

> *"Melhore o UI, o Indicador de Nível, etc, vá buscar assets free."*

**Hoje a HUD não tem arte nenhuma.** É toda `Label` + `StyleBoxFlat` desenhados
por código no `scripts/controlos_toque.gd`: as barras de vida/energia, a barra
do chefe (`_ao_combate_chefe`), e o cabeçalho de nível
(`_encher_cabecalho_nivel`, que é só três Labels — nº do nível, nome, nome do
chefe).

**Já há um kit de HUD no repo, e do pack certo.** Não é preciso descarregar
nada:

```
assets/sprites/incoming/anokolisa/Legacy-Fantasy - High Forest 2.3/HUD/Base-01.png
```

432×304, e traz: **painéis** (pergaminho e madeira, com moldura própria — dão
`NinePatchRect` directo), **calhas e enchimentos de barra** em quatro cores +
as versões finas, e um bloco de **ícones** (pausa, X, +, play, seta, coroa,
troféu, engrenagem, caveira, relógio, aviso, boneco). É do **mesmo pack
anokolisa** que já dá o terreno da floresta, portanto a licença já está
resolvida e creditada.

O que falta é o trabalho: uma ferramenta `tools/gerar_ui.py` a recortar as
peças, e depois trocar os `StyleBoxFlat` por `NinePatchRect` no
`controlos_toque.gd`. O cabeçalho de nível é o sítio onde se nota mais.

---

# BLOCO 5 — a tabela das 100 mecânicas está escrita

`docs/mecanicas_por_nivel.md`, e a mesma coisa em página para ele ver no
telemóvel: <https://claude.ai/code/artifact/10c02ed5-c074-4992-9348-841002e59c31>

Cem níveis, cem mecânicas, uma por nível. A regra: **cada nível ESTREIA uma
mecânica** (mansa, é o tutorial dela sem texto), e **depois ela pode voltar,
sempre mais dura** — cada uma tem um parâmetro que escala com `_dif`.

O inventário honesto: **38 já existem** (actor ou câmara já no jogo), **17
são variações** baratas de coisas que existem, **31 são actores novos
pequenos** e **14 são grandes** (nadar, gancho, gravidade rotativa, a sombra
com atraso...). A página diz quais são os 14 e diz-lhe que **cortar qualquer
um deles não parte a promessa**.

**NÃO CODAR NADA DISTO** antes de ele responder às quatro perguntas do fim da
página. Foi ele que pediu para começar pela tabela.

Quando aprovar, o que muda: a tabela vira `MECANICA_DO_NIVEL` no
`gerador_corredor.gd` (ao lado do `PERFIL` e do `ASSIN_NIVEL`, que já fazem
uma versão fraca disto) e o `TIER_FLAVOUR` deixa de mandar na estreia.

---

# BLOCO 2 (som e música) — **FECHADO** (4 set 2026)

Os quatro pedidos dele sobre som estão feitos. A ordem passa ao **bloco 3
(projécteis, aura, luz e escudo)**.

## Música — o defeito era sistémico, não eram duas faixas

Ele queixou-se de que *"a música do Nível 32 é esquisita e tem vários
cortes"* e de que *"a do nível 1 e a do 2 são iguais"*. Medi antes de mexer
e o problema era maior:

- as camas tocam **sempre em ciclo** (`musica.gd` põe `loop = true`), mas
  **8 das 20 de nível e 10 das 20 de chefe tinham fade-out**. De X em X
  segundos a música desaparecia e voltava a entrar a todo o volume — é esse
  o "corte". A do nível 32 (`Zwischenwelt`) caía 19,5 dB e dava a volta de
  47 em 47 s;
- **7 faixas de nível eram curtas de mais**. A do nível 1 tinha **7,6
  segundos** (era o jingle *Victory Stats*, não uma cama) e a do 2 tinha
  8,0 s, do mesmo álbum — daí soarem iguais.

`tools/preparar_musica.py` reconstrói as 40 de raiz: corta o troço útil,
**cruza a cauda por cima da cabeça** para o fim ligar ao início sem salto, e
iguala tudo a -16 LUFS com ganho fixo. Entraram **6 faixas de rock/metal
CC0 do autor [nene](https://opengameart.org/users/nene)** nos níveis e 3 nos
chefes (o pedido do "tom de rock"); a que ele adorou (nível 38) fica onde
estava, só sem o fade final. As linhas 09-13 dos chefes eram os mesmos cinco
temas das 04-08 noutra versão — passam a ser cinco temas distintos.

> Gotcha guardado: o `acrossfade` do ffmpeg, quando a cauda tem exactamente
> a duração do cruzamento, **há faixas em que não devolve nada** (apanhado
> no `boss_03`). Por isso o cruzamento é feito em Python, no `.wav`.

## SFX — sons novos e uma VOZ por família de monstro

`tools/preparar_sfx.py` (novo). Duas coisas que mudam de método:

- **Sons que não existiam**: passos (três amostras sorteadas, cadência a
  acompanhar a velocidade), rolamento, dash, raspar na parede, agarrar a
  borda, morte, e som próprio para o remate do combo.
- **Sons por FAMÍLIA de monstro**: as 19 espécies partilhavam quatro
  rosnados. Agora há sete famílias (humano, morto, gosma, besta, insecto,
  voador, grande), cada uma com ataque/dano/morte — tabela `FAMILIA_SOM` em
  `demonio_base.gd`.
- **A espada e os mísseis em CAMADAS.** Já tinham sido trocados duas vezes
  por *outra amostra solta*, e era aí que falhava: uma amostra solta nunca
  soa a golpe de jogo. O golpe passa a ser ar + metal com 30 ms entre eles;
  o tiro é sopro grave + zumbido metálico.

**Se ele continuar a não gostar da espada**, a receita é uma linha do
`SONS["ataque"]` em `tools/preparar_sfx.py` — trocar as camadas, correr a
ferramenta e importar. Os packs já estão todos em disco.

Redes de segurança novas: `preparar_musica.py --verificar` (mede o degrau
na costura de cada cama), `teste_camas_de_musica` e `teste_sfx_existem` na
suite.

---

# FEITO — os dois bugs que ele apanhou a jogar (4 set 2026)

## "Quando ataca com espada o ecrã treme e gera frame drop"

Não era impressão. O `_hitstop` põe `Engine.time_scale = 0.0`, ou seja
**pára o jogo**, e estava espalhado por sítios onde não devia: o balanço do
4.º golpe parava 50 ms e abanava a câmara **sem ter acertado em nada**, o
`_flash_golpe` abanava mais 1,8 px em todos os balanços, e cada acerto
parava 50 ms (crítico 110 ms). Num combo de quatro acertos dava **~340 ms
de jogo parado dentro de 1,5 s — 23% do tempo**. E o `Tremor`, a 42 px/s,
durava 107 ms: os abanões encavalitavam-se.

Regra nova, em constantes com nome (`HITSTOP_*` / `TREMOR_*` no
`koliani.gd`): **o balanço não mexe na câmara nem pára o tempo**; só a
ligação tem peso, e o peso é curto. `Tremor.DECAIMENTO` 42 → 70.

## "Quando salta vemos alguns frames acima da cabeça dela"

Duas causas, as duas medidas:

1. O atlas do Shadowblade foi recortado de uma imagem de apresentação e
   trouxe as **guias do cartaz**: uma faixa azul-escura chapada (cor
   `(22,25,38)`) a atravessar células inteiras, desenhada *por trás* das
   figuras, e guias tracejadas mais finas. Como encostam à figura, nem o
   `apagar_linhas` nem o `limpar_celula` as apanhavam. Entraram
   `apagar_faixas` (apaga **pela cor dominante**, para o cabelo desenhado
   por cima sobreviver) e `apagar_riscos`, mais duas regras no
   `limpar_celula`.
2. **A fila do salto não está na grelha de 128** — o mesmo defeito da
   corrida. Os centros medidos estão a 326, 459, 588, 720, 862 e 988: passo
   de ~135. E duas dessas poses (720 e 862) estão mesmo **sem cabeça** no
   atlas — o recorte de origem cortou-as. Eram elas que apareciam a meio do
   salto. Saíram da tabela; `jump` fica com as duas poses inteiras e a
   queda passa a usar a pose de queda da fila do salto duplo.

Conferido com `tools/RigKoliani.tscn` e com uma varredura das 13 tiras:
**zero componentes soltos acima da cabeça em qualquer frame**.

---

# FEITO — softlock do portal (4 set 2026, `712137f`)

Medido, não adivinhado. `tools/verifica_portais.gd` percorre os 100 níveis
**com o índice real de cada um** — a jornada é semeada com
`hash("jornada4|idx")`, portanto carregar a cena com índice 0 gera outro
nível e a medição não vale nada (foi o primeiro erro desta análise).
Resultado: **7 das 36 chegadas de portal punham o corpo dela (20×44) dentro
da geometria** — n32, n59, n75, n81, n90, n91, n93. Os spawns de início de
nível estavam todos bons (0 em 100).

A correcção está no `portal.gd`, onde vale para todos os portais:
`SUBIDA` 6→20 px (sobravam 4 px acima da plataforma) e `_lugar_livre()`, que
consulta a forma contra a camada do mundo e procura o livre mais próximo —
a subir, depois de lado, em passos de 10 px. A ferramenta sai != 0 se alguma
voltar a entalar.

---

# Pendências antigas que sobrevivem (detalhe)

0. **Laser roxo do pack Wenrexa — a meio.** O pack
   [`wenrexa/laser2020`](https://wenrexa.itch.io/laser2020) é **CC0, grátis,
   uso comercial, sem crédito obrigatório** e já está descarregado em
   `assets/sprites/incoming/wenrexa/laser2020/Laser Sprites/` (66 PNGs
   soltos, `01.png`..`66.png`; o demo Windows foi apagado). O Paulo escolheu
   **o último da primeira fila da imagem de capa** — a capa mostra 10 por
   linha, portanto é o **10.º sprite**: o cometa MAGENTA/roxo de cauda
   comprida. Falta: confirmar que a ordem da capa bate certo com a numeração
   dos ficheiros, recortar e apontar o projéctil para ele. Isto casa com o
   pedido nº 4 da fila ("não gosto do estilo do projétil dos mísseis, mude o
   recurso e coloque roxo com brilho").
1. **Escolher mecânicas do catálogo.** O Paulo deixou uma lista enorme de
   mecânicas em [`docs/mecanicas_catalogo.md`](mecanicas_catalogo.md)
   (chefes, coletáveis, mobilidade, game feel, plataformas, perigos,
   combate, puzzles, estrutura de fase). **Ele define as prioridades** —
   perguntar antes de implementar seja o que for daí.
2. **Portal animado do fim de nível: BLOQUEADO por licença.** O pack pago da
   Frostwindz está em `assets/sprites/incoming/frostwindz/` e o recorte
   sai com `python tools/gerar_fx_portal_balas.py`, mas a licença dele
   proíbe redistribuir os ficheiros e este repo é **público** — por isso a
   `Porta.tscn` ficou com o vórtice desenhado por código. Se o repo passar
   a privado (ou houver acordo com a Frostwindz), é só apontar a `Porta`
   para `props/portal_fim.png`. Detalhe em `incoming/LICENSES.md`.
3. **Licença do pack das balas por confirmar.** O `500 Bullet 24x24 Free`
   não traz ficheiro de licença nenhum — só PNGs. Confirmar os termos na
   página do itch.io de onde veio.
4. **O glow do golpe não foi visto em jogo.** Os testes e o smoke-test
   passam, mas não se chegou a tirar uma screenshot da Koliani a atacar
   depois de os efeitos saírem — confirmar que o `COR_GLOW_GOLPE` (roxo
   escuro, `koliani.gd`) está no ponto certo e não subtil demais.
5. Continua tudo o que estava pendente das sessões anteriores (ver o resto
   deste ficheiro e `docs/progresso_agente.md`).

---

# FEITO — tiros de energia novos + espada sem efeitos (4 set 2026)

- Os projécteis da Koliani voltaram ao **roxo** e passaram a usar o pack
  **"500 Bullet 24x24 Free"**. O tiro básico **sorteia uma de três formas a
  cada disparo** — dardo, seta e risco, as que o Paulo escolheu (bloco
  lavanda do `Part 2C`) — e são direccionais: apontam para onde vão.
  Zeriko ficou com um anel grosso e o Kamehameha com um flare espetado, de
  propósito com formas diferentes para se ler de quem vem o tiro.
- **Espada sem efeitos**: saíram os dois arcos de luz que varriam, o rasto
  em `Line2D` e o smear que esticava o sprite; ficou só um **glow roxo
  escuro** discreto (`COR_GLOW_GOLPE`). O "pop"/squash que ainda deformava
  o sprite passou a estar atrás do guarda `RIG_PIXEL`.
- `tools/gerar_fx_portal_balas.py` faz os recortes;
  `tools/shot_projeteis.gd` é a bancada para os ver lado a lado.

---

# ⚠ FILA DO PAULO (por ordem que ele deu)

## FEITO nesta sessão

- ✅ **Koliani mostra o equipamento** (arma/armadura) — por troca de paleta.
- ✅ **Menus de arma/armadura em carrossel**, com preview e stats/diferenças.
- ✅ **PRIORIDADE: o rig "Shadowblade" (arte dele) é a Koliani principal.**

## FEITO — a faixa "SKILL" de volta, a azul (4 set 2026)

> *"O ícone de ganhar novas skills, meta como estava inicialmente, letras a
> azul e um brilho a dizer skill."*

A placa tinha sido removida a 2 set (commit `4c78f1c`) porque ele achou que
lia como uma caixa solta em cima das plataformas. Está reposta em
`scripts/coletavel.gd::_faixa_skill`, igual à original mas com a paleta
passada de verde-água para AZUL — as constantes `COR_LETRAS`/`COR_BORDA`/
`COR_BRILHO`/`COR_LUZ` no topo do ficheiro são o sítio para afinar o tom.
O brilho continua aditivo, para acender por cima do cenário escuro.

---

## FEITO — o rig Shadowblade a sério (4 set 2026)

Três queixas dele sobre o boneco novo, todas resolvidas:

> *"Parece que tem algum frame drop e duplica kolianis."*

A ferramenta antiga deitava fora a grelha do atlas e procurava as figuras por
componentes ligados. Como a arte de células vizinhas se toca, saíam **frames
com duas Kolianis** e frames com meio corpo — e um frame de ataque SEM
personagem nenhuma (a célula que só tem o raio magenta). É isso que se lê
como frame drop. Agora `tools/importar_rig_shadowblade.py` usa a grelha real
(8×5 de 128×160, a mesma do `.tres` que veio no pack), limpa o transbordo do
vizinho célula a célula e ancora tudo pela **mediana do tronco** + linha do
chão, sem recentrar figura a figura (era isso que fazia a personagem tremer).

A **linha da corrida** é o caso feio: cada pose está desenhada DUAS VEZES com
~35 px de desvio e as cópias tapam-se. As cinco janelas de `run1..run5` na
tabela `FRAMES` foram medidas à mão sobre a cópia que ficou inteira; a 6.ª
pose fica cortada pela margem do atlas e perde-se. **Se o Paulo reexportar o
atlas com a linha da corrida espaçada, é só acrescentar uma linha à tabela.**

Do lado do código, `koliani.gd` deixou de deformar o sprite: a animação
procedural (balanço da corrida, inclinação, "respirar" parado, esticão do
salto) era feita para o rig vectorial e, num sprite de pixel-art com filtro
Nearest, escalar/rodar continuamente faz os pixéis saltarem. Fica só o que é
transitório (squash de aterragem, pop e smear do golpe) — ver `RIG_PIXEL`.

> *"Nos combos de ataque faz sempre a mesma animação."*

A linha de ataque do atlas tem quatro poses diferentes e estavam todas na
mesma tira. Agora são quatro tiras: `attack` (corte descendente), `attack2`
(arco roxo por cima), `attack3` (estocada + raio, com o feixe composto por
cima do corpo) e `attack4` (investida rasteira). O `_iniciar_ataque` já conta
o rig "shadowblade" como tendo combo.

> *"Pendurada numa parede esquerda aparece agarrada no lado direito."*

As poses de parede foram desenhadas com a parede à ESQUERDA dela, ao
contrário da convenção "virada à direita" do resto do rig. `_flip_sprite()`
inverte o espelho quando a animação a desenhar é `wallslide`/`borda`
(`PAREDE_ESPELHADA`).

Ferramenta nova para conferir: **`tools/RigKoliani.tscn`** — todos os estados
lado a lado, dentro do jogo, com a linha do chão e a pose de parede
espelhada.

```bash
"...Godot..." --window --screen 1 res://tools/RigKoliani.tscn -- user://rig.png
```

---

## POR FAZER — pedidos "secundários" (ele próprio classificou assim)

Ele disse: *"meta os pedidos que fiz como secundários e dê prioridade a
meter o asset shadowblade"*. O Shadowblade está feito; **isto é a fila.**

### 1. Bug — softlock no primeiro portal
> *"Quando apanhamos o primeiro portal, onde nascemos após apanhar o portal
> é entre 2 plataformas e a Koliani fica presa."*

É o pior da lista (tranca o jogador). Ver `scenes/actors/Portal.tscn` /
o script do portal e onde o `gerador_corredor.gd` põe o destino. O ponto de
saída tem de ser validado contra a geometria — há já
`tools/verifica_alcance.gd` para medir alcance, e o mesmo raciocínio serve
para "há chão por baixo e espaço por cima".

### 2. Sons
> *"Faça um set de sons para a koliani quando faz animações, ataques, etc.
> Faça com que os mobs façam sons também apropriados ao tipo de monstro."*
> *"Continuo sem gostar do som da espada, dos mísseis."*

`tools/gerar_audio.py` sintetiza os `.wav`; os SFX reais CC0 estão
creditados em `assets/audio/CREDITS.md`. A espada e os mísseis já foram
refeitos duas vezes e ele continua a não gostar — desta vez ir buscar
samples reais em vez de sintetizar.

### 3. Música
> *"A música do Nível 32 é esquisita e tem vários cortes, troque."*
> *"Adorei o final da música do Nível 38, se conseguir mais músicas assim
> com tom de rock perfeito."*

Duas coisas: **substituir a do 32** e **usar a do fim do 38 como
referência** (rock) para as próximas. Ver `Musica` (autoload) e as camas por
bioma.

### 4. Projéteis e aura
> *"Não gosto do estilo do projétil dos mísseis, mude o recurso e coloque
> roxo com brilho."*
> *"Faça uma aura roxa brilhante à volta da Koliani."*

Os VFX de projétil vêm do pack bdragon1727 (licença OK). A aura: já existe
`Sprite/LuzAura` (PointLight2D) no `Koliani.tscn` — é ligá-la e afiná-la.

### 5. Escuridão dos mapas
> *"O jogo está um bocado escuro no geral, coloque candeeiros ou lâmpadas a
> acompanhar os níveis, algo que dê alguma luminosidade aos mapas."*

Candeeiros/tochas como decoração **com luz própria** ao longo do percurso.
`tools/gerar_deco.py` faz os props; a luz por nível vem de
`tools/afinar_atmosfera.py`. **Atenção à ordem do pipeline** (ver abaixo).

### 6. Escudo
> *"Tente meter um escudo melhor e quando usamos o escudo fazer um escudo de
> energia roxo brilhante em volta do escudo normal."*

`Sprite/Escudo` no `Koliani.tscn` (polígonos vectoriais) — hoje só aparece
no rig "codigo". Com o Shadowblade é preciso decidir onde encaixa.

### 7. UI
> *"Melhore o UI, o Indicador de Nível, etc, vá buscar assets free."*

Luz verde permanente para descarregar assets grátis (`tools/baixar_packs_itch.py`).

### 8. Vidas
> *"Aumente a quantidade inicial de vidas para 5, e cada vez que passamos num
> nível aumente 1 vida."*

`EstadoJogo` (vidas). Pedido simples — provavelmente o mais rápido da lista.

### 9. MECÂNICAS — o pedido grande
> *"Joguei até Nível 37 e acho que o jogo tem poucas mecânicas, analise
> outros jogos e faça muito mais mecânicas. E mude o raciocínio: em vez de
> ir adicionando mais mecânicas e ir misturando e pôr mais quantidades em
> níveis mais altos, tente pôr uma mecânica nova a cada nível, e aumente a
> dificuldade das mecânicas à medida que o nível aumenta."*

**Uma mecânica nova por nível, 100 níveis.** É uma reformulação de design,
não um patch: hoje há ~12 mecânicas que se repetem e se misturam. Vale a
pena escrever um `docs/mecanicas_por_nivel.md` (tabela nível→mecânica→
parâmetro de dificuldade) ANTES de codar, e mostrar-lha.

---

# O que se fez nesta sessão (4 set 2026)

## 1. A Koliani mostra o que tem vestido — `44fa613`

O rig traz a lâmina e as placas pintadas dentro de cada frame, em sítios
diferentes por frame; pôr o nó `Arma` por cima dava duas espadas (foi por
isso que a sessão anterior o desligou). **A saída foi trocar a PALETA**:
o rig usa duas rampas de cinzento separadas — os médios são o fio da lâmina
e o rasto do golpe, os escuros são as placas do peito/ombros/saia.
`assets/shaders/equipamento.gdshader` reescreve cada rampa na cor do item
guardando a posição na rampa (o sombreado sobrevive), nos 18 estados e sem
tabelas de posição. `tools/verificar_paleta_rig.py` é a rede de segurança.

> ⚠ **Isto está escrito para o rig "cavaleiro"** (`RIGS_COM_PALETA` em
> `koliani.gd`). Com o Shadowblade activo **o shader já não apanha nada** —
> as rampas dele são outras. Falta ler as rampas do Shadowblade (a lâmina é
> roxa e brilha) e acrescentá-las, senão o pedido do equipamento regride.
>
> **Investigado a 4 set (Jensath/Luís) — NÃO é só "ler as rampas".** O
> `koliani_cavaleiro` foi desenhado (ou preparado) de propósito com duas
> rampas de cinzento EXCLUSIVAS (nada mais no rig usa essas cores) — é
> isso que torna a troca de paleta possível. O Shadowblade veio de uma
> imagem de concept art com sombreado contínuo: amostrei os PNGs por
> HSV (matiz/saturação) à procura de uma faixa isolável para a lâmina e
> para a armadura, e **não há separação limpa** — o roxo da lâmina cai na
> mesma faixa que o cabelo e a capa, e a "armadura" cinzenta nem tem uma
> zona de baixa saturação que se distinga do resto. Trocar por cor
> (exata ou por faixa HSV) vai sempre apanhar a personagem toda ou nada.
> Só resolve com **máscara manual por frame** (marcar à mão os pixéis da
> lâmina/armadura, ~12-15 frames) ou pedindo para a próxima exportação já
> vir com a lâmina/armadura numa rampa de cor exclusiva, como no
> cavaleiro. Por agora fica por implementar — o Luís preferiu aceitar a
> limitação a fazer a máscara à mão sem confirmar primeiro com o Paulo.

## 2. Menus de equipamento em carrossel — `dcfaa93`

Mesma forma do `SeletorNiveis`: um cartão por item, setas, arrastar, som
"carrossel", e a **Koliani dentro do cartão** a usar o item. Além dos
números vai a **diferença** para o equipado ("+20 DMG", verde/vermelho).
Corrigido de caminho: as duas tiras não têm a mesma célula (`armas.png` é
640×32 = 20 lâminas de 32×32, `armaduras.png` é 270×26 = 15 de 18×26) e os
cartões cortavam as duas a 18×26 — as armas saíam em pedaços.
`tools/shot_equip.gd` fotografa o ecrã (**precisa de janela**).

## 3. O rig Shadowblade — `40dea83`

**O atlas não se corta pela grelha do `.tres`.** Foi recortado de uma
imagem de apresentação e ficou com: passo entre figuras diferente por
estado (o `idle` anda de 128 em 128, o `run` de ~153); linhas horizontais do
fundo a atravessar a folha, que **colavam as figuras** umas às outras; as
paredes de pedra dos frames de encostar; e figuras descentradas.

`tools/importar_rig_shadowblade.py` limpa isso e procura as figuras por
componentes ligados. **A linha 2 do atlas (o `attack`) tem cortes à mão** —
o rasto do golpe liga tudo e nem a análise pelas pernas separa, porque o
chão da imagem de origem também ficou desenhado. São 33 figuras (o `.tres`
dizia 34: o `crouch` só tem duas poses).

**O que o atlas NÃO tem** (para uma versão futura que o Paulo faça): `roll`,
`dash`, `hurt`, `defesa`, `borda`, `aterrar`, `morte` e os golpes 2/3/4 do
combo. O jogo aguenta (`_atualizar_anim` pergunta `has_animation`), mas cada
tira nova entra só por acrescentar uma linha ao `ORDEM` da ferramenta.

---

# Pendente de antes (não perder de vista)

1. **Playtestar.** 100 níveis e 34 rigs de chefe nunca foram jogados de fio
   a pavio. `tools/testar_chefe.gd` e `tools/folha_de_contacto.gd` (**as
   duas precisam de janela**: `--window --screen 1`).
2. **A curva do 2.º acto** (níveis 31+) espalha-se por 70 níveis; os pontos
   de partida (dificuldade 0.72, 14000 px) continuam a ser palpite.
3. **O nível 100 não é um chefe normal**: é um duelo de espada, sem poderes,
   sem HUD e sem barra de vida. Está montado como `ChefeGenerico` até ser
   feito a sério.
4. **Arte própria das regiões novas** — `gerar_terreno.py` só conhece 6
   biomas de terreno.
5. **Sino Vivo (n11) é um baú-mímico e Vyrak (n15) um morcego gigante** —
   escolhas por confirmar com o Paulo.
6. CI do APK Android falha desde o run 264.

# Ordem obrigatória do pipeline dos níveis

```bash
python tools/gerar_niveis_31_100.py     # escreve os .tscn (e RETRATO_CHEFE)
"...Godot..." --headless --import
python tools/afinar_atmosfera.py        # só DEPOIS: reescreve o bloco Atmosfera
```

Ao contrário, o gerador apaga a atmosfera afinada.

# Gotchas desta máquina (não voltar a descobrir)

- **Screenshots não saem em `--headless`** (renderer dummy). Usar
  `--window --screen 1` — janela real no 2.º monitor.
- Em `--script` os autoloads **não existem como identificador**; buscá-los
  pela árvore (`get_root().get_node("/root/EstadoJogo")`), como fazem o
  `folha_de_contacto.gd` e o `shot_equip.gd`.
- `ERROR: There is no animation with name 'idle'` vinha do `Koliani.tscn`, que
  declarava `animation = &"idle"` num `AnimatedSprite2D` sem `SpriteFrames`
  (quem os monta é o `_montar_frames`). Removido a 4 set 2026.
- **Heredocs longos pelo Bash tool corrompem-se** — escrever o ficheiro com
  a ferramenta de escrita, ou pôr o script no scratchpad e correr o ficheiro.
- Os `.json` de i18n **não estão por ordem alfabética** (a ordem agrupa por
  ecrã) — não os re-ordenar ao acrescentar chaves.
- `ffmpeg` existe via `pip install --user imageio-ffmpeg`.
- **NUNCA `git add -A`** — o `incoming/` tem packs enormes.
