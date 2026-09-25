# Auditoria global — 02 · Combate e inimigos (Agente 2)

Data: 25 set 2026 · HEAD `bcac9fde` · modo só diagnóstico (nada no jogo foi alterado).
Harnesses próprios (fora do repo): `scratchpad/a2/a2_censo.gd` (censo dos 100 níveis) e
`scratchpad/a2/a2_duelo.gd` (duelo Koliani contra cada arquétipo numa arena plana). Tudo corrido
pelo wrapper de sandbox (`godot_sandbox.sh`). Os dados em bruto ficaram em `scratchpad/a2/censo.json` e
`scratchpad/a2/duelos.log`. As capturas estão em `docs/qa/global_audit/img/a2/`.

---

## 0. Resposta curta

**Não. Hoje não existe um core combat loop que aguente 100 níveis.** A Koliani tem uma base
decente: quatro golpes com startup, active e recovery explícitos, cancel para rolar e para dash,
buffer, e uma cadeia de status que liga o crítico ao estado do alvo. Só que **do outro lado não há
adversário**. Com os números medidos, um inimigo comum morre em **1–2 golpes durante a campanha toda**
(e **com 1 golpe a partir do nível ~45**). 56 % dos inimigos colocados **não têm ataque nenhum**, e
nenhum inimigo tem hitbox de ataque: o dano vem sempre do **corpo a tocar**. A espécie é só uma pele
em cima de 7 scripts genéricos, que são sorteados. O tiro é ilimitado, faz 6,25 disparos/s e chega
a ~1190 px. Com ele, matei todos os arquétipos terrestres **sem sofrer dano**. Por isso os inimigos
são **obstáculos com vida**. Não pedem decisões. O que muda do nível 1 para o 100 é a **densidade**
(4 → 60 bichos por nível), não o problema.

---

## 1. Causas-raiz (por prioridade)

| # | Causa-raiz | Sintomas que explica | Prioridade | Ação |
|---|---|---|---|---|
| **RC1** | **O inimigo é modelado como “movimento + corpo que magoa”. Não há ataque, não há papel, não há aggro.** A espécie é cosmética e o comportamento é sorteado. | 56 % sem ataque; a Região II “aérea” anda a pé; o combate parece igual em todo o lado; não há decisões; os boards aprovados não estão implementados | **P0** | **MAJOR REWORK** |
| **RC2** | **O modelo numérico está partido.** A vida dos inimigos satura no idx 29 e a arma sobe até 200. O TTK fica em 1–2 golpes e a dificuldade escala por quantidade. | O combo de 4 golpes (atordoar/sangrar) não serve para nada; o late game é trivial; “ficar mais difícil” = mais bichos iguais | **P0** | **REBUILD** do modelo de tuning |
| **RC3** | **O kit da Koliani não tem economia de risco.** O tiro é ilimitado e dominante, a Energia existe mas nada a gasta, o Kamehameha foi removido e o escudo é hold-block sem parry. | Estratégia dominante = disparar à distância sem sofrer dano; a espada é opcional; o upgrade “foco” é inútil | **P1** | **PARTIAL REWORK** |
| **RC4** | **A legibilidade do contacto não está casada com o que se vê.** Hitbox para lá da lâmina, área de contacto maior do que o sprite, ataque sem commitment, hitstop abaixo de 1 frame a 60 Hz, flash que tapa o alvo, telegraph só por cor. | “Bate no ar”, “leva no ar”, combate sem peso no telemóvel, telegraphs difíceis de ler | **P1** | **TUNE / PARTIAL REWORK** |
| **RC5** | **Os encontros são sorteados, não desenhados.** São N inimigos em fila numa laje, cada um com o comportamento sorteado. | Não há combinações que obriguem a priorizar (escudo+cuspidor, voador+carga…) | **P2** (depende do RC1) | **PARTIAL REWORK** (com o agente de level design) |

---

## 2. Koliani — ataque, combo, cancels

### CURRENT STATE (RUNTIME VERIFIED, `a2_duelo.gd frames`, física a 60 Hz)

A janela activa da hitbox foi medida frame a frame (`#` = activa):

| Golpe | Sequência medida | Startup / Active / Recovery (frames) | Avanço medido | Mult. dano | Recuo no alvo | Extra |
|---|---|---|---|---|---|---|
| 1 | `...#####...` | 3 / 5 / 3 (11 f, 0,18 s) | 21,2 px | 0,85 | 90 px/s | — |
| 2 | `...######....` | 3 / 6 / 4 (13 f) | 26,4 px | 1,0 | 150 | — |
| 3 | `.....#########.....` | 5 / 9 / 5 (19 f) | 30,7 px | 1,25 | 230 | atordoa 0,38 s |
| 4 | `......######....` | 6 / 6 / 4 (16 f) | 45,4 px | 1,9 | 470 (+levanta) | sangra 2,6 s |

Os valores vêm de `scripts/koliani.gd:84-91` (DUR_COMBO/ATAQUE_ATIVO_*), `:164-189` (avanço/dano/recuo).
A cadeia completa dura ~59 f (~1 s) e desloca a Koliani **~124 px** para a frente.

Cancels (runtime, `A2CANCEL`):
- ataque → **rolar**: cancela logo (`_ataque_restante` 0,147 → 0; `koliani.gd:1567`);
- ataque → **dash**: cancela logo (`koliani.gd:1573`);
- ataque → **saltar**: **o ataque não é cancelado nem trava o salto**. Salta (vy −211) e o golpe continua (0,147 → 0,113). O `Movimento.passo` corre durante o ataque (`koliani.gd:1581-1600`), portanto **atacar nunca prende o movimento**: anda-se e salta-se à vontade a meio do golpe.

### WHAT WORKS
- Estrutura de frame data explícita por golpe, com antecipação crescente. O remate lê-se como remate (startup 6 f).
- Cancel para rolar/dash e buffer do próximo golpe (`koliani.gd:1507-1530`). É a “fluidez Dead Cells” certa.
- A curva do combo (abrir → continuar → **3.º atordoa** → **4.º sangra/atira**) é um bom desenho **no papel**.
- Recuo com atrito em vez de teletransporte (`demonio_base.gd:1105-1114`), com o flinch visual.

### WHAT DOES NOT WORK
- **A curva do combo nunca se exerce**: o alvo morre antes do 3.º golpe (ver §5). O atordoar/sangrar só chega a existir contra elites e chefes.
- **Não há commitment**: sem lock de movimento, o golpe é uma hitbox colada a um corpo que corre. Não há risco ao atacar, e por isso não há decisão.
- O avanço de 21–45 px por golpe **empurra a Koliani para dentro da área de contacto** (ver §4: a d = 48–52 px levou dano de contacto a atacar).

### BENCHMARK GAP
Dead Cells: cada arma tem um moveset próprio, com recovery que compromete (os pesados não se cancelam
em qualquer frame), e o roll-cancel é a exceção que se aprende. Nine Sols: o ataque é a parte fraca e
o jogo gira à volta do deflect. Na Koliani a cadeia está bem estruturada, mas não tem alvos que a justifiquem.

### ACTION: **KEEP** a estrutura (frame data, cancels, buffer). **TUNE**: lock parcial de movimento
nos golpes 3–4 e avanço que pare antes da área de contacto. Tudo depende do RC2 (TTK) para ter sentido. **P1.**

---

## 3. Tiro, Energia, Kamehameha, escudo

### CURRENT STATE
- **Tiro** (`koliani.gd:2280-2303`, `projetil_koliani.gd:8,25`): premir ou manter dispara de 0,16 em 0,16 s (**6,25/s**), a 540 px/s e com vida de 2,2 s (**alcance ~1190 px**, maior do que o ecrã). Dano de 1/3 do golpe. **Deixa o alvo a ARDER** (`projetil_koliani.gd:99`), e isso torna-o **vulnerável**, ou seja, **crítico ×1,7 na espada**. Não gasta nada.
- **Energia**: a barra regenera (`koliani.gd:1358-1360`), mas **nenhum código a consome** (grep a `_energia`: só inicialização e regeneração). O **Kamehameha foi removido** (commit `77c0ab33`). Sobra o ícone `ui_producao.gd:332` e o upgrade “foco” (`regen_energia`), que não serve para nada.
- **Escudo** (`koliani.gd:1495-1502, 2419-2436, 2704-2708`): segurar, andar a 70 px/s, bloquear o que vem de frente e 0,14 s de i-frames. **Não há parry**, não há contra-ataque e não há custo.

### RUNTIME VERIFIED (`a2_duelo.gd ttk_tiro`, nível 29, a 380 px)
| Arquétipo | Tiros | Tempo para matar | Dano sofrido |
|---|---|---|---|
| patrulha / saltador / carga / cuspidor | 7 | 1,55 s | **0** |
| escudeiro | 7 | 1,52 s | **0** (o escudo só apara o tiro quando está virado; o DoT da queimadura passa sempre) |
| elite carga (322 HP) | 25 | 3,88 s | **0** |
| voador / trepador | — | não medido (o harness só dispara na horizontal) | — |

### WHAT WORKS
- A sinergia **“o tiro marca (queima) → a espada executa (crítico)”** é o embrião mais interessante do combate e tem identidade Koliani (roxo, energia, Shadowblade).
- O escudo tem um feedback bem feito (cúpula, som, tremor).

### WHAT DOES NOT WORK
- O tiro é a **estratégia dominante**: não custa nada, dispara depressa, chega longe e aplica status. Kitar a 380 px anula todos os arquétipos terrestres (medido: 0 dano).
- Existe uma barra de recurso **sem gasto**. É UI que mente ao jogador.
- O escudo é uma postura passiva (hold) sem janela de timing. Não gera decisões.

### BENCHMARK GAP
Dead Cells: as skills têm cooldown, as armas ranged têm munição/recarga e o arco perde para o
corpo-a-corpo ao perto. Nine Sols: o deflect com timing é o centro, e o dano vem do Qi ganho ao
aparar (é o recurso que liga defesa e ataque).

### KOLIANI OPPORTUNITY
Fazer da Energia o recurso da Shadowblade: o **tiro gasta Energia**, o **parry (escudo com timing) devolve
Energia**, e o **Kamehameha/especial gasta Energia cheia**. Assim fica fechado um ciclo de risco
“aparar → carregar → marcar → executar”, próprio da Koliani, que junta Nine Sols (deflect→recurso) e
Dead Cells (status→crítico).

### ACTION: **PARTIAL REWORK**, **P1**.

---

## 4. Hitboxes vs hurtboxes vs sprite

### RUNTIME VERIFIED (`a2_duelo.gd geometria`, inimigo `goblin` imóvel, 1 golpe por distância)

Formas medidas (px de mundo):

| | Tamanho | Posição |
|---|---|---|
| Corpo Koliani | 20×44 | (0,0) |
| **Hitbox da espada** | 30×34 | centro +23 → **chega a 38 px à frente** (`Koliani.tscn:27-28,217-219`) |
| Lâmina desenhada (frames `attack` do rig shadowblade, pixel opaco mais à frente) | — | **25,5 px** à frente |
| Corpo/hurtbox inimigo | 40×64 | (0,−13) (`DemonioBase.tscn:10-11`) |
| **Área de contacto inimigo** (é o que magoa) | **58×74** | (0,−14) (`DemonioBase.tscn:13-14`) |
| Sprite opaco do inimigo (idle) | **44×47** | — |

Varrimento (distância entre centros → resultado de 1 golpe):
- **acerta** de 20 a 76 px e **falha** a partir de 80 px;
- a 48 e a 52 px **acerta mas leva dano de contacto**: o avanço do golpe (21 px) mete-a dentro da área;
- **faixa segura real ≈ 56–76 px**, ou seja **~20 px** num ecrã de telemóvel.

### WHAT DOES NOT WORK
- A hitbox chega **~12 px para lá da lâmina desenhada**, e o golpe 1 mostra a lâmina **para trás** enquanto o impacto aparece à frente (captura `img/a2/a2_cuspidor_golpe1.png`). “Acertou sem tocar.”
- A área que magoa o jogador é **+14 px de largura e +27 px de altura** do que o bicho desenhado. “Levei no ar.”
- O **dano de contacto só dispara ao ENTRAR** (`demonio_base.gd:396` `body_entered` → `_ao_tocar` `:1041`). Ficar sobreposta não volta a magoar (runtime `A2DENTRO`: 0,53 s sobreposta e 0 dano; STATIC para o caso geral). É inconsistente: tocar magoa, estar dentro não.

### ACTION: **TUNE** (P1). Casar a hitbox com o arco desenhado por golpe (1 forma por golpe), pôr a área de contacto ≤ sprite e passar a um modelo de **ataque com hitbox própria** (RC1), com contacto só como dano residual e baixo.

---

## 5. TTK, dano recebido e escalada

### RUNTIME VERIFIED (`a2_duelo.gd ttk`, espada com cadência de combo)

| Nível | Vida medida | Golpes para matar | Tempo | Nota |
|---|---|---|---|---|
| 1 (idx 0) | 46 | **1** | 0,10 s | 1.º golpe crítico pelas costas (no harness o inimigo nasce virado para fora); sem crítico dá 2 |
| 30 (idx 29) | 81 | **2** | 0,27 s | iguais para patrulha/saltador/carga/escudeiro/cuspidor |
| 100 (idx 99) | 81 | **2** | 0,27 s | **igual ao 30** |
| 30, voador | 81 | 2 (16 carregamentos) | 2,38 s | o único que exige posicionamento; levou 22 |
| 30, elite (valores do gerador, `_dif`=1) | 322 | 4 | 0,82 s | levou 36 |
| 61 com armas tardias (`forjaluz` 80 / `crescente_lunar` 98 / `cutelo_real` 112) | 81 | 1 | 0,10 s | ver aritmética abaixo |

Aritmética (STATIC, confirmada pela vida medida em runtime): a vida dos comuns só escala em
`clampi(indice_nivel,0,29)` (`demonio_base.gd:381-384`) e **congela em 81 HP / 22 dano do nível 30 ao 100**.
O censo confirma: vida mínima 81 e dano mínimo 22 em todas as regiões VII–XX. A arma sobe de 50 a 200
(`equipamento.gd:24-46`). A partir de `crescente_lunar` (98, nível 45), o golpe 1 (98×0,85 = 83) já
**mata qualquer inimigo comum sem crítico**. Durante 55 níveis nenhum inimigo comum aguenta um golpe.

### Dano recebido e frequência (`a2_duelo.gd passivo`, Koliani parada a 140 px durante 20 s, 100 HP)

| Arquétipo | Dano em 20 s (N1 / N30) | Golpes levados | Telegraph → dano (lead) |
|---|---|---|---|
| patrulha | 20 / 66 | 2 / 3 | **sem telegraph** |
| escudeiro | 10 / 44 | 1 / 2 | **sem telegraph** |
| trepador | 0 / 0 | 0 | nunca desceu (só cai com a Koliani por baixo) |
| saltador | 40 / 110 | 4 / 5 | 0,73 s (repetível) |
| carga | 50 / 110 | 5 / 5 | ≥ 0,45 s |
| voador | 70 / 154 | 7 / 7 | 0,42–0,65 s |
| cuspidor | 104 / 208 | 11 / 10 | ≥ 0,60 s |

### WHAT WORKS
- Os 4 arquétipos “activos” têm **leads de 0,42–0,73 s**, que é uma boa faixa (Nine Sols e Dead Cells andam por 0,3–0,6 s nos comuns), e **janelas de castigo** reais: a carga bate na parede e fica atordoada 0,85 s; a picada acaba em 0,5 s de tontura; o cuspo deixa 0,35 s (`demonio_base.gd:825-835, 886-889, 952`).

### WHAT DOES NOT WORK
- **TTK de 1–2 golpes em 100 níveis.** Não há tempo para um inimigo mostrar o que faz. Mata-se antes do telegraph.
- **A dificuldade só escala por densidade**: 4 bichos no N1, 40 no N19 e 60 no N95/N99 (censo). É a mesma pele de 81 HP repetida.
- Não há poise nem super-armor: qualquer golpe interrompe o movimento com o recuo (`demonio_base.gd:778-787`). O windup não é cancelado, só pausado (STATIC).

### BENCHMARK GAP
Dead Cells: um comum a meio do jogo leva 3–6 golpes da arma base, a escala do inimigo acompanha a da
arma (tiers de Boss Cells) e os elites têm modificadores. Na Koliani a curva do jogador e a curva do
inimigo **divergem**.

### ACTION: **REBUILD** do modelo de tuning, **P0**. Definir o TTK-alvo por papel (fodder 2–3, soldier 4–6,
elite 10+) em **golpes normalizados**, escalar a vida pelos 100 níveis indexada ao dano esperado da arma
do jogador nesse ponto, e acrescentar poise/armadura aos papéis pesados.

---

## 6. Inimigos — comportamentos, variedade, telegraph

### CURRENT STATE — censo RUNTIME dos 100 níveis (`a2_censo.gd`, 45 frames após carregar cada nível)

**2969 inimigos comuns** colocados (fora chefes). Existem **7 comportamentos** (`demonio_base.gd:33`):

| Comportamento | Nº | % | Tem ataque? | O que faz de facto |
|---|---|---|---|---|
| patrulha | 1656 | **55,8 %** | **Não** | vai e volta 40–90 px (`gerador_corredor.gd:1780`), **ignora a Koliani** |
| carga | 273 | 9,2 % | investida com o corpo | telegraph 0,42 s, 3,4× vel, 0,55 s |
| voador | 250 | 8,4 % | picada com o corpo | telegraph 0,3 s, 460 px/s |
| saltador | 223 | 7,5 % | salto em arco com o corpo | telegraph 0,26 s |
| cuspidor | 197 | 6,6 % | projéctil (BolaFogo) | telegraph 0,5 s, alcance 440 |
| trepador | 185 | 6,2 % | queda do tecto, depois **vira patrulha** | — |
| escudeiro | 185 | 6,2 % | **Não** (bloqueia de frente) | patrulha lenta |

→ **68 % dos inimigos não atacam** (patrulha + escudeiro + trepador depois de cair). **Nenhum** tem hitbox
de ataque: “atacar” = mexer o corpo para cima dela. **Nenhum persegue.** O censo conta **34 “espécies”**,
mas `especie` só escolhe o sprite, o som e o tamanho. O comportamento é **sorteado à parte**
(`gerador_corredor.gd:1797-1812`), e só `olho`/`abutre` ficam presos a `voador`.

Por região (censo): **5–10 peles** distintas por região e sempre os mesmos 7 comportamentos.
- **Região II** (Desfiladeiro dos Ventos): o bestiário canónico está todo lá (37/37 são as 5 espécies
  aprovadas), mas **0 voadores**. 25 são patrulha, 9 carga, 2 saltador e 1 cuspidor. O board aprovado
  (`docs/art_direction/regions/region_02/enemy_gameplay_pack.png`) diz *“voa em padrões, investida”*,
  *“patrulha e dispara projécteis de vento”*, *“mergulho em picada”*, *“ataque à distância e corpo a corpo”*,
  *“lança magia, teletransporta-se”*. **Nenhum destes comportamentos existe.** As criaturas aéreas aprovadas andam no chão.
- **Região III**: 10 peles canónicas, só **2 voadores em 74**.
- N08 e N10 têm **1** inimigo comum cada.
- As “regras” de bicho são raras e boas: `divide_em` (N58, 16), `so_tiro` (N73, 16), estátuas `so_mexe_sem_olhar` (N68/N74/N89, 40), `dormente` (N21, 17).

### Telegraph (RUNTIME, capturas)
É só **tinta a pulsar + inclinação** do sprite (`demonio_base.gd:603-606, 705-706`). A maioria das
espécies tem **uma pose por estado** e **não tem animação de ataque** (`ATAQUE_FRAMES` só lista 5
espécies da Região II, `demonio_base.gd:433-439`). Nas capturas `img/a2/a2_cuspidor_telegrafo_1.png` e
`a2_carga_telegrafo_0.png`, tiradas ~0,1 s depois do início do telegraph, **o bicho é indistinguível do
idle**. No acerto, o flash (`piscar_dano`, modulate 3.0) mais o anel `Impacto` **tapam o alvo por inteiro**
(`img/a2/a2_patrulha_golpe4.png`, `a2_cuspidor_golpe1.png`).

### WHAT WORKS
- Os 4 arquétipos activos já têm o triângulo **telegraph → compromisso → castigo**.
- As regras (incorpóreo só-tiro, estátuas, divisão, emboscada) são **o que mais se aproxima de exigir decisões**. Mudam *como* se resolve, não só *quanto* se bate.
- Vozes por família (`demonio_base.gd:456-492`), decal e barra de elite.

### WHAT DOES NOT WORK
- A variedade é **visual, não mecânica**: 34 peles × 7 scripts sorteados. Um jogador vê o mesmo goblin-que-anda em todas as regiões com outra cor.
- Os bestiários aprovados (II, III e IV têm board) **descrevem papéis** (torreta, arqueiro, mago que teleporta, serpente que atravessa cenário, espectro com ataque em área) que o código não tem.
- Como não há aggro, o inimigo **não disputa o espaço**. Salta-se por cima ou mata-se em 1–2 golpes.

### BENCHMARK GAP
Dead Cells: cada inimigo = **um papel + um ataque assinado** (grenadier, shieldbearer, lancer, bat…),
aggro e perseguição, animação de antecipação própria, e composições que obrigam a escolher alvo. Nine
Sols: telegraph por animação dedicada, com código de cor para o inaparável (vermelho) e para o aparável.

### KOLIANI OPPORTUNITY
Os boards regionais **já são o design**: 10 criaturas por região com verbo de ataque. Criar um
**sistema de “kit” por espécie** (movimento + 1–2 ataques com hitbox própria + papel + aggro), alimentado
pelo board, e manter as **regras** de bicho (só-tiro, estátua, divide) como modificadores por região. É
exatamente o “teach → combine” de Celeste aplicado ao bestiário.

### ACTION: **MAJOR REWORK**, **P0**.

---

## 7. Status, críticos, hit-stop, feedback

- **Status** (`demonio_base.gd:194-347`): queimar (alastra 48 px), sangrar (acelera se se mexe), atordoar e gelar. **Qualquer um deixa o alvo vulnerável**, e isso dá crítico ×1,7. O crítico também sai pelas costas e pós-rolamento (`koliani.gd:2319-2326`). **KEEP**: é um bom sistema. Só que o tiro ilimitado deixa **tudo sempre a arder**, portanto “crítico” deixa de ser um evento e passa a ser o estado normal (STATIC, derivado de `projetil_koliani.gd:99`).
- **Hit-stop** (`koliani.gd:124-128`): 10 ms no golpe normal, 18 no pesado, 24 no crítico. Foi afinado num monitor de **165 Hz** (comentário `koliani.gd:107-123`). No alvo do produto (**telemóvel a 60 fps**), 10 ms é **0,6 de um frame**: muitas vezes nem se vê. **TUNE P2**: afinar a 60 Hz, com ≥ 2–3 frames no golpe normal *só no alvo*, sem parar o mundo inteiro (STATIC: não medi em dispositivo).
- **Feedback de acerto**: há flash branco, recuo com física, flinch, voz, faíscas e tremor (2,0 px) (RUNTIME, capturas). O flash + anel é **grande demais e opaco** e esconde a pose de dano (§6).
- **Morte do inimigo**: animação `dead` + anel + estilhaços + essência (`demonio_base.gd:1222-1240`). OK.

---

## 8. Encontros

`_f_arena` (`gerador_corredor.gd:2212-2224`) põe `3 + 4·dif` inimigos **igualmente espaçados** numa laje,
cada um com o comportamento **sorteado**, e 1 elite a partir de `dif > 0,42`. Não há composições desenhadas
nem ondas, e não há geometria de combate (plataformas para os voadores, cobertura contra o cuspidor).
**PARTIAL REWORK P2**, a fazer depois do RC1, com o agente de level design (STATIC para a composição;
os números por nível vêm do censo RUNTIME).

---

## 9. O que preservar (potencial próprio da Koliani)

1. Frame data explícita, cancels para rolar/dash e buffer: **é uma base de movimento de combate de qualidade**.
2. A cadeia de 4 golpes com atordoar no 3.º e sangrar no 4.º. Fica certa **quando os alvos aguentarem 4+ golpes**.
3. A sinergia **status → crítico** e o **tiro que marca**, como núcleo “Shadowblade”.
4. As **regras de bicho** (incorpóreo, estátuas, divisão, emboscada): são decisões verdadeiras.
5. As janelas de castigo pós-investida, pós-picada e pós-cuspo.
6. O hitstop à prova de NaN (`HITSTOP_ESCALA_TEMPO`, `koliani.gd:129-150`): é engenharia a manter.

---

## 10. Plano sugerido (ordem)

1. **P0 · Modelo de números (RC2)**: TTK-alvo por papel, escala da vida indexada à arma esperada até ao N100, poise nos papéis pesados. Barato de fazer e desbloqueia o resto.
2. **P0 · Sistema de kit de inimigo (RC1)**: ataque com hitbox, antecipação animada, recovery, aggro, papel. Primeiro implementar o bestiário da Região I/II a partir dos boards, e só depois multiplicar.
3. **P1 · Economia do kit (RC3)**: Energia gasta pelo tiro, parry/deflect no escudo que devolve Energia, especial (Kamehameha) de volta como sumidouro.
4. **P1 · Legibilidade (RC4)**: hitbox por golpe = arco desenhado, contacto ≤ sprite, flash que não tapa, hitstop afinado a 60 Hz.
5. **P2 · Encontros (RC5)**: composições por papel na jornada e nas salas à mão.

---

## RUNTIME VERIFIED vs STATIC ONLY

**RUNTIME VERIFIED** (Godot 4.7.2, sandbox):
- Censo dos 100 níveis: 2969 inimigos, distribuição por comportamento/espécie/região, vida e dano por região, elites e regras.
- Frame data dos 4 golpes (startup/active/recovery), avanço em px e cancels ataque→rolar/dash/saltar.
- Varrimento de alcance (acerta ≤ 76 px, falha ≥ 80) e contacto ao avançar (48–52 px). Medidas das formas e do sprite.
- TTK com espada (7 arquétipos × níveis 1/30/100), elite e armas tardias; TTK com tiro (5 arquétipos + elite).
- Dano recebido em 20 s parada e lead telegraph→dano por arquétipo.
- Capturas de combate em janela real (`--screen 1`), numa arena de teste com o rig shadowblade e os VFX de fallback (os usados nos 95 níveis fora da Região I): `img/a2/*.png` (telegraph + 4 golpes por arquétipo).

**STATIC ONLY — NOT RUNTIME VERIFIED:**
- One-hit kill sem crítico a partir do nível 45 (aritmética; em runtime o 1.º golpe foi crítico por orientação do harness).
- Hitstop “sub-frame” a 60 fps em dispositivo real (não testado em telemóvel).
- Tiro contra voador/trepador (o harness só disparava na horizontal).
- Windup não cancelado por golpe; queimadura a atravessar o escudo do escudeiro; “estar dentro não magoa” no caso geral (o runtime só mostrou 0,53 s de sobreposição sem dano).
- Arte golden/VFX 9G da Região I (L1–L5) no combate: a arena não carrega o kit da Região I.
- Chefes: fora do âmbito deste relatório (só contados: 1 por nível no censo).
- Comparações com Dead Cells e Nine Sols: conhecimento de design, sem medição.

## Save real

SHA256 de `%APPDATA%\Godot\app_userdata\Koliani\progresso.json` no fim:
`9DC2E4A161C38D16CBA5F29A42F2771CF9ED8F00FB2C63FF31DA48397A764238`. **Igual ao de antes. Save intacto.**
