# Região II — passe de fecho (Super-Process A)

## Estado

**TÉCNICO COMPLETO — HUMAN PLAYTEST REQUIRED** (17 set 2026).

Branch `claude/region02-completion-pass`, base
`claude/region02-n10-guardian-skies@d7af0c3d`.

A Região II — Desfiladeiro dos Ventos — fecha como bloco: o Guardião dos
Céus tem contrato visual e arte canónica, os cinco níveis deixaram de
parecer uma prisão, o bug das zonas de vento partilhadas está corrigido, e
o texto deixou de contradizer o cânone. Falta o percurso humano.

**Região III NÃO foi iniciada.**

---

## 1. Gate A — contrato visual do Guardião dos Céus

`docs/art_direction/regions/region_02/GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md`

A referência aprovada **é suficiente** — não houve nada a inventar. A
prancha `boss_pack.png` traz conceito com escala humana medida, seis poses
de animação nomeadas, três de dano/morte, oito padrões de ataque, onze FX
e uma paleta de 36 amostras. `concept_environment_01.png` confirma a
silhueta em contexto de jogo, no painel `BOSS (NÍVEL 10)`.

O contrato separa **LOCKED** (espécie corvídea, escala, paleta, olho =
núcleo, nove estados, âncoras) de **IMPLEMENTATION FLEX** (nº de frames,
resolução, forma das penas). Impacto autorizado em colisão: **nenhum**.

### O que a prancha diz e o jogo não dizia

| | Antes | Cânone |
|---|---|---|
| Espécie | humanoide de manto (rig de pack `monge_celeste`) | **corvídeo colossal** |
| Paleta | ciano/branco-gelo | violeta-índigo + carmesim + ouro |
| Núcleo | diamante ciano no peito | **o olho** (a prancha rotula-o `OLHO / NÚCLEO`) |
| Altura | ~125 px (1,9 × Koliani) | ≈2,6 × Koliani |

### Os três ataques já eram canónicos

A luta implementada no Process 12 não teve de mudar: os três ataques
**já existem na prancha**, com outros nomes.

| Luta | Nome na prancha |
|---|---|
| LÂMINA | 2. PENAS CORTANTES |
| COMANDO DO VENTO | 4. CHAMADA DOS VENTOS |
| QUEDA | 3. MERGULHO |
| Fase 2 | 8. FASE 2 — FÚRIA CELESTIAL |

Por fazer (fora deste processo): RAJADA DE VENTO, CHOQUE AÉREO, METEOROS
CELESTIAIS, INVOCAR GAIVOTAS SOMBRIAS.

---

## 2. Fase B — o Guardião

Arte nossa, pelo motor dos chefes (`tools/gerar_chefes_anim.py`). Plano de
corpo **`ave`** novo em `tools/chefes_corpos.py`, que reutiliza os nomes de
junta do `alado` para herdar o gait — com o sinal da asa da frente trocado,
porque no desenho ela está espelhada.

| | Valor |
|---|---|
| Rig | `assets/sprites/pixel/bosses_anim/guardiao_dos_ceus/` |
| Estados | idle 6 · walk 8 · attack 10 · hurt 4 · death 10 |
| Tamanho no ecrã | **235 × 160 px** = 2,46 × a altura da Koliani |
| Rácio | 1,47 (a prancha mede 1,39 no painel `ESCALA`) |
| Paleta | penas `#1e1e33`/`#433d80`, ponta `#8e3a3c`, ouro `#c98f4e`, núcleo `#c68af9` |

Os outros 54 rigs regeneram **byte a byte iguais**.

### O que a luta perdeu: nada

`ChefeBase`, vida, fases, timings, máquina de estados, arena, `WindZone`,
recompensa, porta, morte e save ficam iguais. **A colisão também**: corpo
40×88 e `AreaContacto` 58×96 são os da luta aprovada. As asas são
silhueta, não hitbox — de propósito: uma arena onde as asas dessem dano
não tinha por onde passar.

Só as **âncoras visuais** mudaram, para a arte e o efeito baterem certo:

| Âncora | Antes | Agora | Porquê |
|---|---|---|---|
| Lâmina | `(0, −8)` | `_origem_asa()` = `(26·dir, −64)` | contrato L7: nasce da asa |
| Pó da picada | `(0, +6)` | `(0, +44)` | o ponto de chão são as garras |
| Núcleo | `(0, −16)` | `(37, −90)` | medido no rig: o olho |

### Quatro coisas que não passaram

1. **Perfil estrito**, as duas asas varridas para trás: lia-se como um
   galináceo deitado. A prancha desenha-o de frente/três quartos — foi
   seguir isso que resolveu.
2. **Leque de penas todas na mesma junta**: dava uma cauda de peru. Uma
   asa lê-se por massa varrida + remiges a abrir só na ponta.
3. **Rodar só o desenho da asa**, não a junta da 2.ª metade: a ponta
   descolava do ombro. `ARCO_ASA` passou a ser usado nos dois sítios.
4. **Envergadura a mais**: 304 × 150 (rácio 2,03) dava 324 px de largo
   contra os 560 px da plataforma da arena. **A suite apanhou** — ver §6.

---

## 3. Fase C — passe de arte canónico (N06–N10)

Os cinco níveis corriam com `bioma = "prisao"` e `fundo_pack` `prisao`
ou `masmorra`.

A região passa a ter **material próprio**, e não emprestado: a regra do
`afinar_atmosfera.py` — *um pack nunca aparece em duas regiões* — vale, e
os packs certos em matéria (`montanhas` tem a lua e as serras, `rochoso`
tem o mar de nuvens) são os da **Região III**.

| Ferramenta nova | O que produz |
|---|---|
| `tools/gerar_fundos_regiao02.py` | 4 camadas de parallax (`ceu`, `serras`, `nuvens`, `falesias`) |
| `tools/gerar_terreno_regiao02.py` | material de terreno + 12 props góticos |
| `tools/gerar_tileset_regiao02.py` | a folha da `CascaMasmorra`, recolorida |

Tudo composto de material CC0 **que já estava no repositório**, recortado
e recolorido para a paleta amostrada da prancha. Nada descarregado.

### A casca fechada: troca-se a textura, não os tiles

No `masmorra.tres` **cada tile sólido traz o seu polígono de colisão
16×16**, e o `casca_masmorra.gd` conta com isso (está escrito no comentário
do `abrir_esquerda`). Trocar coordenadas de atlas mudava a colisão.

Por isso o `assets/tiles/desfiladeiro.tres` é o `masmorra.tres` com **outra
imagem e exatamente as mesmas coordenadas e os mesmos polígonos**. A
colisão é idêntica por construção. O `estilo` é um `@export` novo, com
`"masmorra"` por omissão — nenhuma cena fora da Região II muda.

### O fundo deixa de ser ácido

| Nível | Antes | Agora |
|---|---|---|
| N06 | ácido verde `(0.28, 0.42, 0.14)` | abismo `(0.46, 0.14, 0.28)` |
| N07 | lava laranja `(0.62, 0.22, 0.08)` | idem |
| N09 | verde-água `(0.22, 0.40, 0.30)` | idem |
| N10 | ácido verde `(0.24, 0.40, 0.16)` | idem |

E a **mesma "faixa verde-oliva chapada"** que a 9H.12D tirou da Região I
estava aqui também, no `LIQUIDO[1]` do `gerador_corredor.gd` — a jornada
procedural de N06/N07/N09 pintava o fundo de ácido oliva. Corrigido.

### Cada nível continua a ter a sua hora

O sítio é um só, a luz não. A progressão segue o papel de cada nível:
N06 chegada (ar limpo), N07 a subida (nuvem fecha-se), N08 o ponto mais
alto (céu aberto, menos neblina), N09 o vento vira (o carmesim entra no
ar), N10 o exame sob a lua de sangue (violeta fundo).

---

## 4. Fase D — as zonas de vento partilhavam a forma

O Godot **partilha sub-recursos entre instâncias da mesma PackedScene**, e
a `WindZone.tscn` traz o `RectangleShape2D` como sub-recurso. Como o
`_configurar_forma()` o **redimensiona**, a última zona a correr `_ready()`
impunha a sua forma a todas as outras da cena.

Medido antes da correção:

| Nível | Zona | Desenhado | Real |
|---|---|---|---|
| N06 | `VentoEntrada` | 760×250 | **820×300** |
| N07 | `UpdraftMeio` | 210×320 | **190×300** |
| N09 | `VentoVariavelEntrada` | 680×240 | **300×220** |
| N09 | `VentoVariavelCombate` | 650×270 | **300×220** |

O N09 era o pior: as três zonas ficavam com a forma da última e perdiam
**mais de metade da largura desenhada** — o vento variável quase não
existia onde tinha sido posto. N08 e N10 escapavam porque as cenas já
davam uma forma própria a cada zona.

A correção é copiar a forma por instância no `_configurar_forma()`:
genérica, sem saber de níveis nem de tamanhos, e as cenas que já tinham
forma própria ficam exatamente como estavam.

**Porque é que ninguém tinha visto:** o contrato estrutural olhava o
`tamanho` (o `@export`), não a forma que a física usa. O harness novo,
`tests/run_region02_wind_shapes.tscn`, mede a forma **real**. Corre no CI.

---

## 5. Fase E — o texto contradizia o cânone

| O que dizia | O que passou a dizer |
|---|---|
| `level.n05`–`n09`: "Prison of the Damned", "Furnace of Sinners", "Corridor of Executions", "Ward of the Dead", "Cell Zero" | The Open Cliffs · The Rising Gorge · The Suspended Ruins · The Turning Gale · The Eternal Winds |
| As duas pistas do N10 diziam que quem está ali é **o Primeiro Prisioneiro** | o **Guardião dos Céus** |
| 5 pistas descreviam celas, foles de forja, cepo de execução, carcereiros | abrigos de vento, pontes, marcos e vigias do desfiladeiro |
| 2 pistas de níveis **posteriores** listavam "prison" entre as regiões andadas | "gorge" (troca de uma palavra) |

Nos **6 idiomas**, com as aspas de cada casa.

**O arco não muda.** Cada pista faz exatamente o que fazia: a Aurora passou
por aqui, passou há pouco, o Zeriko mandou forjar-lhe grilhões, o registo
tem o nome dela marcado como "guardada", dois irmãos deixaram-na descansar
e morreram por isso, e quem manda no fim deixa passar quem ama alguém o
suficiente para continuar. Só muda o **sítio**, e a figura do N10.

As **chaves** ficam (`clue.prisao_*`, `clue.cela_zero_*`): são
identificadores internos, não aparecem ao jogador, e renomeá-las obrigava
a mexer no mapa de pistas e nos seis ficheiros sem nada ganhar no ecrã.

`data/level_manifest.json` ainda apontava o `boss_ref` do `level_010` ao
`ChefePrimeiroPrisioneiro.tscn`, que já não está em nível nenhum.

### O que só a build exportada apanhou

O cabeçalho da HUD dizia **"PRISON OF THE DAMNED"** por cima de "The
Eternal Winds". Nenhum teste viu isto: a HUD e as pastilhas do carrossel
leem `EstadoJogo.REGIOES`, e a entrada da Região II continuava a ser a da
prisão — nome, chave i18n e cor azul-ferro.

| | Antes | Agora |
|---|---|---|
| `id` | `prisao` | `desfiladeiro` |
| `nome` | Prisao dos Condenados | Desfiladeiro dos Ventos |
| `chave` | `world.prison` | `world.gorge` |
| `cor` | `(0.60, 0.68, 1.00)` | `(0.78, 0.60, 1.00)` |

A chave foi **renomeada** nos seis idiomas, não duplicada: não sobra uma
única referência a `world.prison`. As 7 pistas da região no
`diario_pistas.gd` apontavam-lhe e passam a apontar a nova.

Há teste para não voltar: a Região II tem de apontar `world.gorge`, a
chave tem de estar traduzida, o nome não pode conter vocabulário de prisão
em nenhum idioma, e a região tem de continuar a cobrir os níveis 06–10.

**A lição de método:** a suite valida cenas, dados e comportamento — mas o
que o jogador **lê no ecrã** só se viu ao exportar e fotografar. Vale a
pena fazer isso cedo, não no fim.

---

## 6. Testes

### Art safety — a geometria de jogo não mexeu

`tools/geometria_regiao02.tscn` fotografa, nas cinco cenas, tudo o que o
jogador toca: plataformas, formas de colisão, checkpoints, spawn, portas,
chefe/arena, perigos e zonas de vento (posição, tamanho, direção,
intensidade, modo, pulso). 248 nós ao todo.

Corrido **antes** do passe, guardado, e corrido **depois**: `0 diferenças`.

O próprio comparador foi provado a morder: mexer uma zona do N09 16 px
dá exatamente uma falha, nomeada. (E acusou um falso positivo de início —
o JSON não distingue `int` de `float` e um `modo = 1` voltava como `1.0`;
a comparação passou a ser numérica.)

### Resultados (17 set 2026, Godot 4.7.2, APPDATA isolado)

| Verificação | Resultado |
|---|---|
| Suite completa (`tools/correr_testes.ps1`) | **PASS** |
| Harness do Guardião (`run_boss_guardiao_ceus`) | PASS |
| Glide N08 (`run_glide_region02`) | PASS |
| WindZone (`run_wind_system`) | PASS |
| Formas das zonas (`run_region02_wind_shapes`, novo) | PASS |
| Movement + Camera 4A | PASS |
| Geometria da Região II (novo) | PASS — 0 diferenças |
| 8 verificadores do CI + spawn livre | PASS |
| Godot real, N06–N10 | carregam, 0 erros novos |
| Save real | intacto (SHA igual antes e depois) |

**0 falhas novas. 0 falhas pré-existentes encontradas.**

### A suite apanhou um erro a sério

O teste da silhueta dos chefes lia só as constantes do `ChefeBase`
(`ALTURA_ALVO_CHEFE`, `LARGURA_ALVO_CHEFE`) e por isso media **mal**
qualquer chefe que reescrevesse `_altura_alvo()`/`_largura_alvo()` — que
são virtuais. Acusou o Guardião de sair com 54 px de alto quando sai com
160.

Corrigido: o teste passa a ler os overrides do script do chefe. E com a
medida certa mostrou o problema a sério — **324 px de largo** contra os
560 px da plataforma da arena do N10. As asas encurtaram até ao rácio da
prancha e a largura final é **235 px** (42% da plataforma).

O tecto de largura sobe de 175 para 240 **só** para chefes que declarem
alvos próprios. É uma exceção documentada, não um relaxamento geral.

### Mutações (prova de que os testes novos mordem)

| Mutação | Apanhada por |
|---|---|
| mover uma `WindZone` do N09 16 px | geometria: 1 diferença, nomeada |
| pôr o N09 de volta em `bioma = "prisao"` + casca de masmorra | coerência da região: 2 falhas |
| (antes da correção) as 5 cenas com formas partilhadas | `run_region02_wind_shapes`: 11 falhas |

Todas revertidas; a árvore final não tem mutações.

---

## 7. Limitações — para o playtest humano

1. **A largura do Guardião.** 235 px contra 560 px de plataforma. Está
   acima da banda normal dos chefes (175) e passa o tecto da exceção (240)
   por 5 px. **É a primeira coisa a julgar a jogar**: as asas tapam a
   Koliani na arena? As asas não dão dano — isso lê-se, ou parece injusto?
2. **Os chefes intermédios ainda são de prisão** — a HUD mostra "The
   Jailer", "Ignivar, the Cursed Smith", "The Guillotine Lady", "The
   Condemned Brothers". É agora a contradição mais visível que sobra:
   aparece no cartão de quatro dos cinco níveis. **Não foi mudada de
   propósito**: são mesmo criaturas de prisão (um carcereiro com chaves,
   uma dama da guilhotina), e trocar-lhes só o nome mudava a etiqueta sem
   mudar a contradição. Substituí-los é design, não arte.
3. **Os inimigos não são da região.** N06 esqueleto+chort, N07 imp+chort,
   N08 chort, N09 mastim+orc, N10 orc. O cânone pede Morcego dos Ventos,
   Sentinela Flutuante, Gaivota Sombria, Golem Aéreo e Mago do Vento.
   Trocar a identidade visual é barato (`identidade_visual` existe e não
   mexe em som nem comportamento) — **mas trocar só o aspeto parte a
   leitura silhueta→comportamento**, e trocar o comportamento é gameplay,
   não arte. Fica para um processo próprio.
4. **N06/N07/N09 continuam com `corredor = true`** — têm uma jornada
   procedural prependida à sala desenhada; N08 e N10 não. É uma
   inconsistência de estrutura da região, e mudá-la é gameplay.
5. **O tipo de perigo do fundo.** Passou a ler-se como abismo, mas
   continua a ser um `AguaVenenosa` — um plano de líquido. A auditoria
   pedia queda/abismo a sério. É gameplay.
6. **As zonas de vento do N06/N07/N09 ficaram MAIORES** do que estavam a
   correr até agora (é o tamanho que sempre estiveram desenhadas a ter).
   O N09 é o que mais muda: duas zonas passam de 300 px de largo para 680
   e 650. **Isto muda como esses níveis se jogam** — para o que estava
   desenhado, mas nunca foi jogado assim.
7. Continua tudo o que o Process 12 já tinha deixado em aberto sobre a
   luta: sensação da arena, ritmo do `EXPOSTO`, justiça da picada na borda.

---

## 8. Ficheiros

**Novos**

```
docs/art_direction/regions/region_02/GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md
tools/gerar_fundos_regiao02.py · gerar_terreno_regiao02.py
tools/gerar_tileset_regiao02.py · geometria_regiao02.gd/.tscn
tests/run_region02_wind_shapes.gd/.tscn
assets/tiles/desfiladeiro.tres
assets/sprites/pixel/backgrounds/desfiladeiro/  (4 camadas)
assets/sprites/pixel/terreno/desfiladeiro/      (4 peças)
assets/sprites/pixel/deco/desfiladeiro/         (12 props)
assets/sprites/pixel/bosses_anim/guardiao_dos_ceus/ (5 tiras)
assets/sprites/pixel/tiles/desfiladeiro_0x72.png
```

**Alterados**

```
scripts/wind_zone.gd · atmosfera.gd · plataforma.gd · casca_masmorra.gd
scripts/plataforma_corrente.gd · gerador_corredor.gd
scripts/chefe_guardiao_dos_ceus.gd
scenes/actors/ChefeGuardiaoDosCeus.tscn
scenes/levels/  (as cinco cenas da Região II)
tools/chefes_corpos.py · chefes_gaits.py · gerar_chefes_anim.py
tests/run_tests.gd · tests/test_region02_wind_levels.gd
assets/i18n/*.json (6) · data/level_manifest.json
.github/workflows/ci.yml
```

---

## 9. Próximo passo

**HUMAN PLAYTEST REGIÃO II + N10 BOSS.**

Build Windows isolada em `builds/windows/`, com launchers por nível e save
próprio — não toca no save real.

**Não iniciar a Região III.**
