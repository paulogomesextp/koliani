# REGIÃO III — TORRE DOS ECOS · PASSAGEM DE MIGRAÇÃO CANÓNICA

**Estado: PARTIAL.** Não integrado em `master` — ver §6.

**Branch:** `claude/region03-completion-pass`
**Base:** `origin/master` @ `17b90e28` (confirmado por `git fetch`, sem
histórico inesperado)
**Contrato:** [`REGION03_VISUAL_GAMEPLAY_CONTRACT.md`](../art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md)
**Auditoria:** [`region_03_audit.md`](region_03_audit.md)

---

## 1. O QUE SE DESCOBRIU (e muda o método)

### 1.1 O `.tscn` é só a sala do chefe

Os cinco níveis usam `nivel_com_chefe.gd`, que **prepende uma jornada
procedural** gerada pelo `gerador_corredor.gd` (5129 linhas) a partir de
tabelas indexadas pela região. O que está na cena é a sala final.

**Consequência:** tornar a região canónica é sobretudo mexer nas tabelas
do gerador, não nas cinco cenas. Medir só o `.tscn` dá uma imagem falsa.

### 1.2 A assinatura da região era a da região errada

`ASSINATURA[2]` era `"vento"` — a assinatura do **Desfiladeiro dos
Ventos**, que é a Região II. O cânone diz que o elemento central da Torre
dos Ecos são os **sinos**, e `sinos` já estava na pool: só não era a
assinatura. Uma linha, e a câmara de assinatura dos cinco níveis passa a
ser de sinos.

### 1.3 A Torre dos Ecos renderizava como floresta

A prova visual (PNGs reais, não leitura de ficheiros) mostrou **pinheiros
verdes**, céu castanho-avermelhado e **cruzes de campa** nos cinco
níveis. Causa: `fundo_pack = "montanhas"`, que tem uma camada
`trees.png`.

### 1.4 O Vyrak era outra criatura

A implementação era "Vyrak, **o Dragão das Sombras**": besta alada roxa,
plano `alado`, **3 fases**, garra/cauda/sopro. A prancha aprovada mostra
"Vyrak, **A Voz dos Ecos**": guardião humanoide encapuzado que paira,
coroa em anel, **sino ao peito**, asas de eco, **2 fases**, nove ataques
nomeados. Não era polimento — eram dois chefes com o mesmo nome.

### 1.5 Zero dos dez inimigos canónicos

A região corria com `xamane, wogol, olho, abutre, imp`: demónios
genéricos herdados.

---

## 2. O QUE SE FEZ

| Área | Antes | Depois |
|---|---|---|
| Nomes | Torre dos Sinos / dos Ventos / da Tempestade / Observatório / Pico Esquecido | **Entrada dos Ecos · Galerias Verticais · Mecanismos Antigos · Campanário · O Topo dos Ecos** (i18n nas 6 línguas) |
| Encontros | 5 `boss.*` | 4 `guard.*` + **1** `boss.vyrak` (precedente da Região II) |
| Assinatura | `vento` | **`sinos`** |
| Fundo | `montanhas` (com pinheiros) | pack próprio **`torre_ecos`** (lua e céu · catedral · torres distantes · silhueta com sinos) |
| Atmosfera | tinta rosada no N11 | uma paleta por nível, da tabela do `afinar_atmosfera.py` |
| Inimigos | 0 dos 10 canónicos | **10 dos 10**, recortados da prancha aprovada |
| Vyrak | dragão roxo, 3 fases, 5 ataques | **guardião de sinos, ~4× Koliani, 2 fases, 9 ataques da prancha** |
| Testes | — | **8 testes novos** da Região III, provados por mutação |

### Regras respeitadas

- **Nomes de ficheiros de cena não mudaram** — mudá-los parte saves e
  checkpoints (precedente já documentado na Região II). O que o jogador
  lê é a chave `level.n##`.
- **A arte foi gerada por ferramentas**, nunca editada à mão:
  `tools/gerar_fundo_torre_ecos.py`, `tools/gerar_chefes_anim.py`,
  `tools/extrair_inimigos_regiao03.py`, `tools/afinar_atmosfera.py`.
- **A geometria não mudou.** O diff das cinco cenas toca no bloco
  `Atmosfera`, no cabeçalho e na `especie` dos cinco elites. Plataformas,
  colisões, vãos, checkpoints, spawn e saída ficaram como estavam.
- Os elites trocaram de **identidade**, não de gameplay: vida, dano,
  comportamento e posição intactos.

---

## 3. FIDELIDADE — avaliação honesta

Comparação lado a lado em
[`region_03_visual_evidence/antes_depois.png`](../playtests/region_03_visual_evidence/antes_depois.png).

| Eixo | Antes | Depois |
|---|---|---|
| Paleta | **FAILED** (céu castanho-avermelhado) | **HIGH** (azul noite, luar, ouro dos sinos) |
| Identidade regional | **FAILED** (floresta) | **MEDIUM-HIGH** (sinos, catedral, torres) |
| Background / parallax | **FAILED** (pinheiros) | **MEDIUM** (5 camadas próprias, mas lêem-se escuras) |
| Inimigos | **FAILED** (demónios de masmorra) | **HIGH** (os dez da prancha) |
| Boss (Vyrak) | **FAILED** (dragão) | **HIGH** em silhueta, escala e detalhes; **MEDIUM** em cor dentro da arena |
| **Arquitetura do primeiro plano** | **LOW** | **LOW** — *não resolvido* |
| Props jogáveis | **LOW** | **LOW** — *não resolvido* |
| Densidade visual | LOW | MEDIUM |
| Identidade entre os 5 níveis | **LOW** (quase indistinguíveis) | **MEDIUM** (paleta distinta, inimigo de assinatura distinto) |

### Porque é que ainda não é PASS

O briefing exige **nenhuma fidelidade LOW**. Dois eixos continuam LOW e
não se vai fingir o contrário:

1. **Arquitetura do primeiro plano.** A camada jogável continua a ser
   corredores de tijolo liso. O cânone pede arcos góticos, colunas,
   vitrais, escadarias, estátuas e contrafortes *na camada onde se anda*.
   Isso está no fundo, não no jogo.
2. **Props jogáveis.** Os sinos aparecem como câmara de assinatura do
   gerador, mas o vocabulário de props da prancha (candelabros,
   braseiros, estátuas angélicas, correntes, memoriais) não está
   colocado.

Resolver isto é mexer no `_deco` por bioma e no vocabulário de câmaras do
gerador — trabalho real, não afinação.

---

## 4. TESTES

`tools/correr_testes.sh` (equivalente Linux do `.ps1`, isola o `user://`
por `XDG_DATA_HOME` e confirma o SHA256 do save real): **PASS**, antes e
depois.

Oito testes novos:

| Teste | Tranca |
|---|---|
| `teste_r3_nomes_canonicos` | os 5 nomes + o Vyrak, paridade de chaves nas 6 línguas, e que o Vyrak não volta a ser "dragon" |
| `teste_r3_um_so_chefe_na_regiao` | 4 guardiões + 1 boss; o Sino Vivo mantém-se |
| `teste_r3_fundo_proprio_da_torre` | pack `torre_ecos` registado, as 4 camadas existem, os 5 níveis usam-no |
| `teste_r3_assinatura_e_de_sinos` | `ASSINATURA[2] == "sinos"` |
| `teste_r3_bestiario_canonico` | as 10 espécies com as 5 tiras, pool sem herdados, 5 assinaturas distintas, nenhum elite fora da região |
| `teste_r3_niveis_carregam` | os 5 carregam com Koliani e Porta |
| `teste_r3_vyrak_identidade` | rig, escala ~4×, 9 ataques, telégrafos ≥ 0,45 s, ataques de F2 fora da F1 |
| `teste_r3_vyrak_leva_dano_muda_de_fase_e_morre` | atingível, transita aos 50 %, **morre** |

### Mutação

Repondo (a) `ASSINATURA[2] = "vento"`, (b) `boss.vyrak = "Vyrak, the
Shadow Dragon"` e (c) `boss.sino_vivo`, os testes acenderam nos três
casos. Tudo restaurado a seguir.

### Região II

Sem regressão: a suite completa inclui os testes da Região II (vento,
planar do N08, Guardião dos Céus) e passa.

---

## 5. PLAYTEST COM BOT

30 runs (3 perfis × 2 seeds × 5 níveis). Relatório completo e
limitações: [`region_03_bot_humanlike_playtest.md`](../playtests/region_03_bot_humanlike_playtest.md).

Em duas linhas: **0 de 30 concluídos, mas isso não mede nada** — a porta
só abre com o chefe morto e o bot não mata chefes; o mesmo bot faz **0 de
4** na Região II, que não foi tocada. O resultado que vale é
**0 frames com NaN e 0 crashes em ~5 horas de jogo simulado**: nenhum
blocker novo.

Sinal a levar ao playtest humano: o **N15 tem queda punitiva** (53 mortes
e 48 saltos falhados por run, contra 0 nos outros quatro).

---

## 6. PORQUE É QUE NÃO FOI PARA `master`

O briefing é explícito: só PASS integra. Falham três critérios:

1. **Há fidelidade LOW** (§3): arquitetura do primeiro plano e props.
2. **A progressão de dificuldade N11→N15 não foi medida** — o bot não
   sobe estes níveis, e inventar a medição era pior do que não a ter.
3. **As mecânicas por nível do cânone não foram implementadas**: as
   plataformas oscilantes do N11, os elevadores e as plataformas que
   desaparecem do N12, as engrenagens e alavancas do N13, o updraft e as
   plataformas rotativas do N14, as plataformas ilusórias do N15.

O que está na branch é sólido, testado e não regride nada — mas é a
**identidade** da região, não a região completa.

---

## 7. PRÓXIMA FASE

Pela ordem de retorno canónico:

1. **Arquitetura e props no primeiro plano** — o único caminho para tirar
   os dois LOW. Mexe no `_deco` por bioma e no vocabulário de câmaras do
   gerador para a região 2.
2. **Mecânicas por nível** (§6.3), que é o que dá aos cinco níveis
   papéis distintos em vez de só paletas distintas.
3. **Bot com navegação vertical** — sem ele não há como medir a
   progressão de dificuldade desta região.
4. Guardiões N12–N14: continuam Aerion/Voltaris/Sacerdotisa. O vento do
   N12 e a lua do N14 têm apoio no cânone; o **raio do N13 não** — o N13
   canónico é de engrenagens.
5. Só depois: build Windows, PWA e integração.
