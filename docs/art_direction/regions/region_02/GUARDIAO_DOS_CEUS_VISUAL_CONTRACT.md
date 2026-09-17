# GUARDIÃO DOS CÉUS — CONTRATO VISUAL

**Região:** 02 — Desfiladeiro dos Ventos · **Nível:** 10 · **Data:** 17 set 2026
**Processo:** Super-Process A (Region II Completion Pass), Gate A.

## Autoridade

| Fonte | Peso |
|---|---|
| `boss_pack.png` (esta pasta) | **autoridade primária** — conceito, poses, animações, ataques, FX, paleta, arena |
| `concept_environment_01.png`, painel `BOSS (NÍVEL 10)` | confirma silhueta e nome em contexto de jogo |
| `KOLIANI_REGION_CANON.md` | autoridade textual (nome do boss, níveis da região) |
| `ChefePrimeiroPrisioneiro`, rig `monge_celeste` | **fora do cânone** — substituídos |

**Gate A = PASS.** A referência aprovada é suficiente para definir o Guardião
honestamente: há prancha de conceito com escala humana, seis poses de
animação nomeadas, três poses de dano/morte, oito padrões de ataque, onze
efeitos e uma paleta de 36 amostras. Nada abaixo foi inventado.

---

## LOCKED — o que vem da arte aprovada

Alterar qualquer destes pontos é sair do cânone.

### L1. Espécie e silhueta

O Guardião é uma **ave — um corvídeo/rapina colossal**, não um humanoide.
A silhueta lê-se por: massa de peito baixa e larga, cabeça pequena projetada
à frente, **bico curvo**, e sobretudo **asas** — o elemento mais largo e o
que define a leitura à distância. Cauda de penas longas atrás, pernas curtas
com garras à frente.

Nunca: monge, cavaleiro, figura de manto, bípede humanoide.

### L2. Escala

A prancha traz um painel `ESCALA (ALTURA APROX.)` com uma figura humana
medida contra a pose `GRITO`. Medido em píxeis nesse painel:

| | px na prancha | × figura humana |
|---|---:|---:|
| Figura humana de referência | 27 | 1,00 |
| Guardião pousado, do bico às garras | 72 | **2,67** |
| Guardião com as asas erguidas | 94 | **3,48** |
| Guardião de ponta a ponta, pose `GRITO` | ~100 | **3,70** |

A Koliani canónica mede **65 px desenhados** (bbox do frame golden, escala
1.0). O contrato de escala é portanto:

- **altura do corpo ≈ 2,6 × Koliani ≈ 170 px**;
- **largura ≈ 3,5–3,7 × Koliani ≈ 230–240 px** na pose pousada;
- na pose de voo com asas abertas a envergadura é ainda maior — a `ARTE
  PRINCIPAL` sai fora do enquadramento da prancha, portanto **a largura não
  pode ser normalizada pelo tecto comum dos chefes**. Um Guardião estreito
  não é o Guardião.

### L3. Paleta

Amostrada da prancha (painel `PALETA DE CORES` + pontos altos do corpo):

| Papel | Hex | Origem |
|---|---|---|
| Penas, base | `#151727` `#1e1e33` `#1e2232` | fila `PENAS` / `BASES` |
| Penas, meio | `#433d80` `#5c419f` | fila `PENAS` |
| Penas, luz | `#9769b1` `#d495fd` | fila `LUZ / MAGIA` |
| Acento carmesim (rémiges) | `#713739` `#904143` · alta `#ff7c70` | `BASES` / corpo |
| Bico e garras (ouro) | `#a27f6a` `#c3a390` · alta `#f0c883` | `BASES` / corpo |
| Núcleo (olho) | `#c68af9` | corpo, ponto mais brilhante |

O carmesim aparece **só nas pontas das penas de voo e na cauda** — é acento,
não cor de corpo. O ouro aparece **só no bico e nas garras**.

Proibido: a paleta ciano/branco-gelo do `monge_celeste` (`#a8ebff`,
`#0.66,0.92,1`). O Guardião é violeta-índigo com carmesim, não gelo.

### L4. Núcleo / olho

O painel `DETALHES` rotula o olho como **`OLHO / NÚCLEO`**: no Guardião o
olho **é** o núcleo. É um ponto violeta brilhante (`#c68af9`) com halo, na
cabeça, e é o **centro visual** da criatura — o sítio para onde o jogador
olha e o ponto a que os telégrafos e o flash de dano se devem referir.

Não é um diamante flutuante no peito (como no rig atual).

### L5. Estados que têm de animar

A prancha nomeia-os. Qualquer arte final tem de os cobrir:

`IDLE (ASA FECHADA)` · `IDLE (ASA ABERTA)` · `ANDAR / AJUSTE` ·
`VOO (LOOP)` · `POUSAR` · `LEVANTAR VOO` · `HURT (1)` · `HURT (2)` ·
`MORTE (FASE 2)`

### L6. Ataques canónicos

A prancha traz oito. A luta implementada usa três + fase 2, e **os três já
existem no cânone** — não há invenção nem contradição:

| Luta implementada | Nome canónico na prancha | Leitura |
|---|---|---|
| Ataque 1 — LÂMINA | **2. PENAS CORTANTES** | penas-lâmina violeta/carmesim disparadas |
| Ataque 2 — COMANDO DO VENTO | **4. CHAMADA DOS VENTOS** | colunas de tornado brancas/azuis do chão |
| Ataque 3 — QUEDA | **3. MERGULHO** | picada com detritos de rocha |
| Fase 2 | **8. FASE 2 — FÚRIA CELESTIAL** | asas abertas, partículas violeta |

Por fazer (fora do âmbito deste processo): `1. RAJADA DE VENTO`,
`5. CHOQUE AÉREO`, `6. METEOROS CELESTIAIS`, `7. INVOCAR GAIVOTAS SOMBRIAS`.

### L7. Âncoras (de onde nasce o quê)

| Âncora | Sítio no corpo | Serve |
|---|---|---|
| Origem dos projéteis | **asas** (borda das rémiges) | PENAS CORTANTES |
| Origem do sopro / grito | **bico** | CHAMADA DOS VENTOS |
| Origem do telégrafo | **núcleo/olho** (pisca antes de tudo) | os três ataques |
| Ponto de chão | **garras** | pousar, QUEDA, alinhamento ao solo |
| Centro visual | **núcleo/olho** | câmara, barra de vida, flash |

### L8. Arena e ambiente (nível 10)

Painel `ARENA (ELEMENTOS DO NÍVEL 10)`: plataformas suspensas sobre um mar
de nuvens, **lua de sangue** ao fundo, torres góticas partidas, estandartes
carmesins, correntes, braseiros, colunas em ruínas, cristais.

---

## IMPLEMENTATION FLEX — o que se pode adaptar

Estes pontos são técnicos. Podem mudar desde que **L1–L8 se mantenham**.

| Ponto | Liberdade |
|---|---|
| Nº de frames por estado | livre; a prancha dá poses-chave, não uma folha de sprites |
| Resolução do sprite | livre; o jogo normaliza por altura/largura alvo |
| Altura/largura exatas em px | o rácio de L2 é que manda; ±10% é aceitável |
| Forma exata das penas individuais | livre dentro da silhueta |
| Detritos de rocha a flutuar | decorativos; podem existir ou não |
| Plumas a cair | decorativas |
| Cor exata do rim-light | dentro da família violeta de L3 |
| Ritmo/timings da luta | **não é arte** — fica como está, já aprovado |

### Impacto em colisão

A arte **não** deve pedir alteração de colisão. O corpo do Guardião
(`CollisionShape2D` 40×88) e a `AreaContacto` (58×96) definem o alcance da
espada e o dano de contacto, e foram afinados com a luta aprovada.

Um corvídeo é mais largo que alto, portanto a arte fica **mais larga que a
colisão**. Isso é deliberado e correto: as asas são silhueta, não são corpo.
Se as asas dessem dano de contacto, a arena ficaria injusta — a Koliani não
teria por onde passar. **As asas não são hitbox.**

Alteração de colisão autorizada por este contrato: **nenhuma**.

---

## Delta contra o que está no jogo hoje

| | Hoje (`ChefeGuardiaoDosCeus.tscn`) | Cânone |
|---|---|---|
| Rig | `bosses_anim/monge_celeste` — humanoide de manto, de pack | corvídeo colossal |
| Paleta | ciano/branco-gelo | violeta-índigo + carmesim + ouro |
| Núcleo | diamante ciano no peito | olho violeta na cabeça |
| Largura | limitada a 110 px pelo tecto comum | tem de poder ser larga |
| Altura | ~125 px (≈1,9 × Koliani) | ≈170 px (≈2,6 × Koliani) |

O que **não** muda: `ChefeBase`, vida, fases, timings, máquina de estados,
arena, `WindZone`, recompensa, porta, morte, save.
