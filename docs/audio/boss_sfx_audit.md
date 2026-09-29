# SFX Overhaul — Prompt 3A: passe de som dos CHEFES

Data: 20 setembro 2026. Base: `codex/sfx-overhaul` em `9f6dcd41`.
Âmbito: **só chefes**. Wind, sinos ambientais, mecanismos, baús, unlock,
menu e música ficam para o Prompt 3B e não foram tocados.

## Resultado executivo

O defeito que este lote corrige não é de mistura, é **semântico**.
`chefe_cai` — o som de MORTE do chefe — estava em **33 callsites**, e só
**dois** eram morte. Os outros 31 eram mudanças de fase (28) e ataques (3).
Ou seja: a meio de quase todas as lutas do jogo tocava o som de o chefe cair.

Em dois casos era pior. O Rei Devorador, de cada vez que comia um servo para
se curar, tocava `chefe_cai` **+ `conquista`** — a assinatura exacta da
vitória — estando vivo e a **ganhar** vida. Os Irmãos Condenados faziam o
mesmo quando um dos dois morria. Um falso "ganhaste" é pior que um som
errado: mente ao jogador sobre o estado da luta.

Três achados vieram da medição e não da leitura do código:

- **`raio.wav` e `olho_carregar.wav` eram byte a byte o mesmo ficheiro**
  (único par duplicado do catálogo). A *carga* do laser do Olho do Abismo
  soava exactamente ao *relâmpago* do Voltaris.
- **A fase 2 do Vyrak era MUDA**: chamava `Som.toca("boss", ...)` e `"boss"`
  nunca foi chave do catálogo — `boss.wav` é uma cama de música. O `toca()`
  devolve `false` em silêncio, por isso ninguém deu por ela.
- **O Vyrak — o chefe-SINO — usava `ataque_forte`**, que é a espada pesada da
  *Koliani*, em três ataques. O chefe soava ao jogador.

Estado final: `chefe_cai` e `conquista` existem em **2 callsites**, ambos no
caminho de morte do `ChefeBase`. Há um teste estático que lê os 40 scripts
de chefe e rebenta se alguém os voltar a usar noutro sítio.

## FASE 1 — inventário dos chefes

38 scripts de chefe, 30 com máquina de estados e som próprio. 160 callsites
de áudio no total.

| BOSS | ATTACK | CURRENT SFX | HURT | PHASE | DEATH | PROBLEM | ACTION | RESULT |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **Guardião dos Céus** (N10) | Penas/Blade, Vento, Mergulho | `projetil`, `chefe_magia`, `investida`+`demonio_ataque` | base | `grito` | base | blade era o projéctil genérico; vento era magia genérica **e** 14 dB abaixo do resto | blade→`lamina_cair`; vento→`onda`; fase→`_som_fase("vento")` | 3 ataques distinguíveis, provado em teste |
| **Vyrak** (Região III) | 9 ataques | `ataque_forte`×3, `projetil`, `investida`, `invocar`, `raio` | base | `"boss"` (inexistente) | base | fase MUDA; chefe-sino com a espada da Koliani | fase→`_som_fase("sino")`; `ataque_forte`→`sino_ataque`/`onda` | fase audível; identidade de sino |
| **Rei Devorador** | garfo, pratos, servos, devorar | `golpe_pesado`, `projetil`, `invocar` | base | `chefe_cai` | base | `_devorar` tocava morte+recompensa vivo | devorar→`praga` grave; cura→`invocar` agudo; fase→`_som_fase("carne")` | falso "ganhaste" eliminado |
| **Irmãos Condenados** | investida, dardos | `investida`, `projetil` | base | `chefe_cai`+`conquista` | base | irmão a morrer disparava a fanfarra de vitória | fase→`_som_fase("energia")`; `conquista` retirada | recompensa só no fim |
| **Aerion** | investida, lanças, tornados, pisão | `investida`, `gelo`, `grito` | base | `chefe_cai` | base | pisão usava `chefe_cai` a **−3 dB** — o callsite mais alto do jogo, mais alto que a própria morte | pisão→`_som_impacto("esmagar")`; fase→`_som_fase("vento")` | pisão lê-se como impacto |
| **Morvanna** | magia, mãos, clones | `chefe_magia`, `invocar`, `grito` | base | `chefe_cai` | base | aterragem da picada usava o som de morte | aterragem→`_som_impacto("esmagar")` | impacto leve |
| **Sino Vivo** | 4 ataques | `sino_ataque` nos **quatro** | base | `chefe_cai` | base | grito e baque radial eram a mesma badalada | grito→`grito`; baque→`esmagar`; 2 mantêm o sino | 3 famílias em 4 ataques |
| **Zeriko Final** | 9 ataques | `feixe_vil`, `meteoro`, `esmagar`… | base | `chefe_cai`+`mudar_forma` | base | fase com duas vozes a dobrar | `_som_fase("magia")`, `chefe_cai` fora | 2 vozes, ordenadas |
| **Arauto de Zeriko** | golpe, sopro, dardos, nova | `golpe_pesado`, `chama`, `projetil`, `grito` | base | `chefe_cai`+`mudar_forma` | base | idem; `chama` 22 dB abaixo da banda | `_som_fase("fogo")`; `chama` compensada | sopro audível |
| **Olho do Abismo** | laser, clones, inverter | `olho_carregar`, `feixe_vil`, `invocar` | base | `chefe_cai` | base | a carga era o relâmpago do Voltaris | `olho_carregar` derivado (1,6 s, invertido) | carga ≠ relâmpago |
| **Capitão Negro**, **Primeiro Prisioneiro** | vários | `investida`, `golpe_pesado`, `esmagar` | base | `chefe_cai`+`grito` | base | 3 vozes no frame da fase | `_som_fase(...)`, `grito` fora | ≤2 vozes |
| **Ghorak** (N1) | investida, baque, semear | `investida`, `esmagar`, `praga` | base | `chefe_cai` | base | fase = morte | `_som_fase("carne")` | — |
| **Colosso Ósseo, Rei Ossário** | vários | `esmagar`, `golpe_pesado`, `projetil` | base | `chefe_cai` (`_remodelar`/`_desmontar`) | base | fase = morte | `_som_fase("osso")` | — |
| **Restantes 17 chefes** | vários | banco partilhado | base | `chefe_cai` em `_entrar_fase2` | base | fase = morte | `_som_fase(<família>)` | — |

## FASE 2 — auditoria dos 33 `chefe_cai`

| CLASSIFICAÇÃO | N.º | CALLSITES | ACÇÃO |
| --- | ---: | --- | --- |
| **DEATH** | 2 | `chefe_base._tocar_som_derrota`, `chefe_base._cair_com_falas` | mantidos — é a casa do som |
| **PHASE_TRANSITION** | 28 | `_entrar_fase2` (×19), `_virar_fase2` (×2), `_mudar_forma`, `_mudar`, `_virar_energia`, `_remodelar`, `_desmontar`, `_atualiza_fase`, `_um_morre` | → `_som_fase("<família>")` |
| **HEAVY_ATTACK** | 2 | `aerion._stomp_impacto` (−3 dB!), `morvanna` aterragem da picada | → `_som_impacto("esmagar", …)` |
| **OTHER** | 1 | `rei_devorador._devorar` (comer para curar) | → `_som_impacto("praga", …)` |

Depois: **2 callsites**, ambos morte. Provado por teste estático que lê o
código-fonte dos 40 scripts — cobre chefes que nenhum teste chega a
instanciar.

## FASE 3 — identidade sonora

Não foi criado nenhum sistema novo nem nenhum stream novo: os chefes passaram
a usar melhor o catálogo que já existia. **22 streams distintos** repartidos
por famílias: blade (`lamina_cair`), slam (`esmagar`, `golpe_pesado`),
magia (`chefe_magia`, `feixe_vil`), vento (`onda`, `grito`), fogo (`chama`),
orgânico (`praga`, `garra`), pedra/osso (`esmagar`), sino (`sino_ataque`),
energia (`raio`), projéctil (`projetil`, `lamina_cair`), máquina
(`engrenagem`).

A mudança de fase ganhou **assinatura por material** sem custar um stream por
chefe: `mudar_forma` com o tom da família, mais **uma** camada de reforço
que o chefe já usava nos ataques, 90 ms depois (a sobreposição exacta
mascarava o transiente — é a mesma razão pela qual a morte separa queda de
recompensa em 450 ms). Máximo **duas** vozes no frame.

| FAMÍLIA | TOM | CAMADA | CHEFES |
| --- | ---: | --- | ---: |
| magia | 1,06 | `chefe_magia` | 7 |
| carne | 0,72 | `praga` | 7 |
| energia | 1,10 | `raio` | 5 |
| metal | 0,94 | `engrenagem` | 3 |
| vento | 1,14 | `grito` | 2 |
| sino | 1,00 | `sino_ataque` | 2 |
| osso | 0,86 | `esmagar` | 2 |
| fogo | 0,82 | `chama` | 2 |
| pedra | 0,78 | `esmagar` | omissão |

## FASE 4 — boss hurt

A base do Prompt 2 (`mob_grande_dano`, −14 dB, 0,82 ±2 %, cooldown 220 ms,
prioridade MÉDIA) **não foi alterada** e continua a ser o único hurt de
chefe. Auditados os 38 scripts: nenhuma subclasse tem hurt próprio, nenhuma
duplica o da base; as três que redefinem `receber_dano`
(Guardião, Vyrak, Olho) chamam `super` e não tocam som por conta própria.
Não se especializou nada: não havia asset que melhorasse a leitura e
inventar diferença por chefe só tornaria o feedback inconsistente.
Death continua a ganhar sempre a hurt — regressão provada em teste.

## FASE 5 — transições de fase

28 subclasses passaram a `_som_fase()`. Contrato: **nunca** morte, **nunca**
recompensa, no máximo duas vozes, prioridade ALTA (é informação de estado —
tem de passar a meio de uma rajada), cooldown de 600 ms por instância
porque vários chefes avaliam o limiar dentro do `_physics_process` e podiam
disparar duas vezes antes de a flag assentar.

Cinco vozes a mais foram retiradas: `mudar_forma` a dobrar (Arauto, Zeriko),
`grito` a somar-se à camada (Capitão Negro, Primeiro Prisioneiro) e a
`conquista` falsa dos Irmãos Condenados.

## FASE 6 — boss death

Inalterado e defendido por teste: `chefe_cai` → 450 ms → `conquista`,
exactamente uma vez cada. Há **três** portas de entrada na morte
(`_tocar_som_derrota`, `_cair_com_falas`, `_cair_derrotado`) e nenhuma
subclasse duplica nenhuma delas. Nos chefes-história a `conquista` só toca
**depois** das últimas falas — por isso o teste exige, nesse caminho, que ela
**não** se antecipe ao diálogo.

## FASE 7 — Guardião dos Céus (N10)

Gameplay, tempos, fases e hitboxes **não** foram tocados. Só routing.

| ATAQUE | ANTES | DEPOIS | PORQUÊ |
| --- | --- | --- | --- |
| Penas Cortantes / Blade | `projetil` −10 dB | `lamina_cair` −11 dB, tom 1,42 | `projetil` é o projéctil genérico de **doze** chefes; uma pena-lâmina a cortar o ar não pode ser o mesmo som que um prato ou uma lança |
| Chamada dos Ventos | `chefe_magia` −8 dB | `onda` −9 dB, tom 1,28/1,04 | `chefe_magia` tem pico de −14,6 dBFS: a ordem de vento saía ~14 dB abaixo da luta, quase inaudível — e era "magia", não vento |
| Mergulho / Dive | `investida` + `demonio_ataque` | iguais, via helpers | já eram dois tempos distintos; ganharam prioridade MÉDIA no embate para não serem cortados por projécteis |
| Abrir asas (fase 2) | `grito` | `_som_fase("vento")` | passa a ler-se como fase |

Teste dedicado exige que os três resultem em **três ficheiros diferentes** e
que a lâmina não volte ao projéctil genérico.

## FASE 8 — Vyrak (Região III)

Gameplay N11–N15 **não** foi tocado.

- **Fase 2 muda** → `_som_fase("sino")`. `"boss"` não era chave do catálogo.
- **`ataque_forte` ×3** (espada da Koliani) → `sino_ataque` no golpe de sino
  e na queda de sino, `onda` na onda de eco.
- O `_som()` do Vyrak era um `Som.toca` cru, sem prioridade nem cooldown;
  passou pelo helper (o chefe telegrafa **e** executa, podiam cair dois sons
  do mesmo ataque no mesmo par de frames).

## FASE 9 — medição objectiva (ffmpeg/ffprobe)

26 streams de chefe medidos: duração, sample rate, canais, pico
(`volumedetect`) e LUFS integrado (`ebur128`).

**Faixas encontradas** (LUFS integrado; em ficheiros < 0,4 s o gating do
ebur128 devolve −70 e a leitura útil é o **pico**):

| TIPO | FAIXA OBSERVADA | FORA DA FAIXA |
| --- | --- | --- |
| attack | −10 a −17 LUFS, pico −3 a 0 dBFS | `chama`, `feixe_vil`, `chefe_magia` |
| hurt | −15,0 LUFS (`mob_grande_dano`) | — |
| phase | −12,7 LUFS (`mudar_forma`) | — |
| death | −12,2 LUFS (`chefe_cai`), −10,4 (`conquista`) | — |

**Os três fora da faixa, e o que se fez:**

| FICHEIRO | PICO | LUFS | ABAIXO DA BANDA | COMPENSAÇÃO |
| --- | ---: | ---: | ---: | ---: |
| `chama` | −24,3 dBFS | −35,4 | ~22 dB | +18,0 dB |
| `feixe_vil` | −15,1 dBFS | −32,1 | ~18 dB | +14,0 dB |
| `chefe_magia` | −14,6 dBFS | −31,1 | ~17 dB | +13,0 dB |

A correcção foi feita **uma vez**, numa tabela `COMPENSACAO` em `som.gd`, e
não nos dez callsites: a compensação é propriedade do **ficheiro**, não do
sítio que o toca — corrigi-la callsite a callsite garantia que o uso seguinte
voltava a nascer surdo. Os três são exclusivos dos chefes. Os ganhos deixam
pelo menos 1 dB de margem de pico. **Isto não substitui normalizar os
ficheiros de origem**; é o que se pode fazer sem mexer nos assets.

**Um asset foi alterado**, e só um, por motivo forte:

`raio.wav` e `olho_carregar.wav` eram **byte a byte idênticos**
(md5 `60d89d5f…`), o único par duplicado do catálogo. Uma carga e um impacto
são envelopes opostos — a carga cresce e resolve no disparo, o impacto
arranca no pico e decai. `tools/gerar_sfx_3a.py` deriva a carga do mesmo
material CC0 (mesmo pack, mesma licença, já creditado): invertida no tempo,
passa-banda a fechar, 1,6 s em vez de 5,61 s — os 5,61 s nunca chegavam a
ouvir-se, o disparo cortava-os a meio. Depois: md5 diferente, −15,0 LUFS,
pico −4,2 dBFS.

`raio` fica como o stream mais alto do conjunto (−9,4 LUFS, pico 0,0 dBFS) e
o mais longo (5,61 s). Os callsites mandam-no a −8/−12 dB, o que o põe dentro
da banda — não foi normalizado às cegas. Fica anotado para escuta humana.

## FASE 10 — anti-repetição

Um chefe repete o mesmo ataque dezenas de vezes numa luta. `_som_ataque()`
aplica um ciclo de tom **determinístico** `[0, −3,5 %, +2,5 %]` — o **mesmo**
que o `DemonioBase._voz` já usava nos inimigos, de propósito: um ciclo, não
um sorteio. Assim o harness pode afirmar a sequência exacta e o RNG de
gameplay fica intocado. A variação central do `Som.toca()` é posta a zero
nestes callsites: duas variações empilhadas foi o defeito que o Prompt 2
corrigiu no player e não vale a pena reintroduzi-lo nos chefes.

Provado: três disparos dão três tons diferentes, e a segunda série de três dá
exactamente os mesmos três.

## FASE 11 — prioridade

O pool de 8 vozes do Prompt 2 **não foi refactorizado**. Só se passou a
declarar prioridade onde não havia nenhuma:

| NÍVEL | EVENTOS |
| --- | --- |
| **ALTA** | boss death (`chefe_cai`, `conquista`), mudança de fase (`mudar_forma`) |
| **MÉDIA** | boss hurt (já era), ataque pesado / impacto (`_som_impacto`, 31 callsites) |
| **NORMAL** | ataques e projécteis comuns (`_som_ataque`, 99 callsites) |

Antes deste lote, **nenhum** ataque de chefe declarava prioridade nem
cooldown: eram todos NORMAL sem debounce, e uma rajada podia roubar a voz da
morte.

## Callsites, antes e depois

| | ANTES | DEPOIS |
| --- | ---: | ---: |
| `Som.toca` cru nos chefes | 160 | 9 (só `chefe_base`) |
| `chefe_cai` | 33 | 2 (morte) |
| `conquista` fora da morte | 2 | 0 |
| `_som_ataque` (NORMAL + anti-repetição) | 0 | 99 |
| `_som_impacto` (MÉDIA) | 0 | 31 |
| `_som_fase` (ALTA) | 0 | 30 |
| chaves inexistentes no catálogo | 1 (`boss`) | 0 |
| ficheiros duplicados no catálogo | 1 par | 0 |

## Validação

Harness novo: `tools/verificar_sfx_chefes.gd`, 9 blocos, renderer real.
Todos os harnesses correm com o `APPDATA` redireccionado para uma sandbox —
a suite **escreve no save real** e já apagou a campanha do Paulo uma vez.

### Harness novo — `tools/verificar_sfx_chefes.gd` (0 falhas)

| BLOCO | RESULTADO |
| --- | --- |
| catálogo sem chaves mortas; carga ≠ relâmpago | `sem chaves mortas, carga != relampago` |
| reserva estática de `chefe_cai`/`conquista` | `so' no chefe_base (40 scripts)` |
| nenhum chefe toca morte/recompensa vivo | `0 em 10 chefes` |
| fase ≠ morte, ≤ 2 vozes | `mudar_forma + 1 camada, nunca morte` |
| sequência de morte | `chefe_cai x1; conquista x1 (ou apos falas)` |
| hurt com cooldown, nunca no fatal | `1 voz por 220 ms, mob_grande_dano` |
| Guardião: 3 ataques distintos | `["lamina_cair.ogg", "onda.ogg", "demonio_ataque.ogg"]` |
| Vyrak: fase audível, sem espada do player | PASS |
| anti-repetição determinística | `[1.0, 0.965, 1.025]`, repetível |
| prioridade: morte protegida | PASS |

Os dez chefes cobertos: Ghorak (chefe inicial, N1), **Guardião dos Céus**
(N10), **Vyrak** (Região III), Sino Vivo, Rei Devorador, Irmãos Condenados,
Zeriko Final, Aerion, Morvanna, Olho do Abismo — inclui os dois com falso
"ganhaste", o do pisão a −3 dB e os que redefinem `receber_dano`.

O harness **mordeu** durante o desenvolvimento antes de passar: apanhou a
`conquista` em falta no Guardião (chefe-história), a Chamada dos Ventos muda
sem `WindZone`, o ciclo de tom lido da voz errada e uma fuga de vozes entre
secções do próprio teste. Nenhuma asserção passou por não medir nada.

### Regressões dos Prompts 1 e 2 (0 falhas cada)

- `verificar_sfx_criticos.gd`: catálogo 79/79, portal, checkpoint, UI, morte
  de inimigo, morte da Koliani e **`SFX CHEFE vozes=2
  sequencia=chefe_cai.wav>conquista.wav atraso=0.45s`** — o contrato do
  Prompt 1 intacto.
- `verificar_sfx_combate.gd`: combo 1–4, dash, escudo, hurt do player, as 7
  famílias de inimigos, antirrepetição, projécteis, **boss hurt
  `mob_grande_dano.ogg` cooldown 0,22 s** e pool com prioridade alta
  protegida.

### Suite geral

Chega a `OK -- todos os testes passaram`. Reproduz **exactamente** a
assinatura preexistente que o briefing manda não corrigir: o runner destrói a
SceneTree, repete a suíte, e a Região III emite
`Cannot call method 'get' on a previously freed instance` em
`run_tests.gd:4010`
(`teste_r3_vyrak_leva_dano_muda_de_fase_e_morre`). A causa é do teste, não do
jogo: o laço bate no Vyrak até `vida <= 0`, o `ChefeBase` faz `queue_free()`,
e o teste volta a ler `chefe.get("vida")` **depois** do `await`, já com a
instância libertada.

Provado que é **PREEXISTENTE** e não deste lote:
`tests/` não tem uma linha alterada; o diff de `chefe_base.gd` **não toca
nenhuma** linha do caminho de morte (`_ja_derrotado`, `queue_free`,
`derrotado.emit`, `_cair_derrotado`, `_explodir_derrotado`); e o diff inteiro
do `chefe_vyrak.gd` são cinco linhas, todas de routing de som. O runner não
foi alterado.

### Save real

Todos os harnesses correram com `APPDATA` redireccionado para uma sandbox
descartável. O `progresso.json` do Paulo ficou com a mesma data de escrita
(19:45) e o mesmo SHA-256 de antes da sessão.

### Ambiente

Godot 4.7.2 (`--headless --import`): zero erros de script ou de recurso.
Medições com ffmpeg/ffprobe 9.0.1. Os avisos de `ObjectDB`/RID à saída são os
de sempre nos harnesses e não foram escondidos nem corrigidos.


`HUMAN LISTEN REQUIRED` para: timbre das transições de fase por família;
o `olho_carregar` novo; os três ganhos de compensação (`chama` +18 dB é
muito, e o ficheiro pode ter chão de ruído); o `raio` a 5,61 s; e se os três
ataques do Guardião se lêem como três **no meio do combate**, não só em
ficheiros diferentes. `HUMAN PLAYTEST REQUIRED` para fadiga ao fim de uma
luta inteira. `DEVICE VALIDATION REQUIRED` para mobile e Web.

A validação técnica prova routing, contagem, sequência, prioridade e margem.
**Não** prova que soa bem.

## Gameplay

**Não alterado.** Nenhuma mudança em dano, tempos, fases, hitboxes, arenas,
máquinas de estados ou progressão. Todas as alterações são routing de áudio,
ganho e prioridade — excepto `assets/audio/olho_carregar.wav`, que é um
asset derivado por ferramenta do material CC0 já presente.

## Próxima acção

**SFX PROMPT 3B — WORLD + PROGRESSION SOUND PASS**: wind, sinos ambientais,
mecanismos, hazards, baús, unlock, checkpoint, level complete e feedback de
mundo. Não iniciado.
