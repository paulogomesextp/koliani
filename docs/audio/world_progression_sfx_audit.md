# Auditoria SFX — MUNDO e PROGRESSÃO (SFX Overhaul, Prompt 3B)

Branch `codex/sfx-overhaul`. Âmbito: vento, sinos, mecanismos, perigos,
portas/grades, checkpoint, baú, pickups, desbloqueio, fim de nível, portal.
Fora de âmbito: música, UI global, chefes (só regressão), arte.

---

## 1. O que a auditoria encontrou

O problema não era mistura mal afinada. Era **ausência**: 28 scripts de
cenário com **zero** chamadas a `Som.`

```
agua_venenosa   alavanca(*)   armadilha     bau_chefe(*)  bola_fogo
espinhos        fogo          level_session melhorias     nivel_com_chefe
para_raios      pedra_queda   pendulo_lamina  plataforma   plataforma_corrente
plataforma_espectral  plataforma_flutuante   plataforma_luz
plataforma_olhar      plataforma_peso        plataforma_quebra
plataforma_roda       raio_tempestade        serra         sino_torre
tumulo_elevador       wind_zone              chefe_sino_vivo(**)
```

`(*)` tinha som, mas emprestado. `(**)` é chefe, fora de âmbito.

E o que tinha som pedia-o emprestado a quem não devia. O empréstimo não é só
feio — **ensina a coisa errada**:

| Callsite | Usava | De quem é esse som | O que o jogador lia |
|---|---|---|---|
| `alavanca.gd:99` | `selo` | **checkpoint** (`checkpoint.gd:298`) | "gravei o jogo" |
| `placa_peso.gd:82` | `selo` | idem | idem |
| `porta_trancada.gd:85` | `porta` / `selo` | porta de **fim de nível** / checkpoint | "acabei o nível" |
| `vela.gd:48/57` | `selo` / `onda` | checkpoint / ataque de **9 chefes** | "onda de choque" |
| `bau_chefe.gd:55` | `apanhar` | a **moeda de essência do chão** | prémio == moeda |
| `santuario.gd:221` | `conquista` | a **vitória sobre um chefe** (6,1 s) | fanfarra num botão de loja |
| `santuario.gd:223` | `dano` | **levar dano** | "perdi vida" num menu |
| `seletor_equip.gd:641` | `dano` | idem | idem |
| `sino_torre.gd` | *(mudo)* | — | mecânica invisível ao ouvido |

E a **hierarquia estava invertida** no fim de nível. Medido
(`ffmpeg -af ebur128/volumedetect`), LUFS integrado do ficheiro + `volume_db`
do callsite:

```
                        ficheiro   callsite   efectivo
conquista (vitória)      -10,4      -6,0       -16,4   <- topo, certo
PORTA de fim de nível    -17,3      -3,0       -20,3   <- 2.o mais alto (!)
baú do chefe             -16,5      -6,0       -22,5   <- igual a uma moeda
coletável comum          -16,5      -6,0       -22,5
essência do chão         -16,5     -14,0       -30,5
```

Sair do nível soava mais alto do que o prémio do nível. E o baú do chefe
soava exactamente como a moeda que se apanha dez vezes por sala.

---

## 2. Tabela EVENT → RESULT

Tipos: `AMB` ambience · `LOOP` · `1SHOT` · `MEC` mechanism · `HAZ` hazard ·
`INT` interaction · `PROG` progression · `REW` reward · `TRA` transition.

| EVENT | LOCATION | CURRENT SFX | TYPE | PROBLEM | ACTION | RESULT |
|---|---|---|---|---|---|---|
| **VENTO** |
| ar da zona | `wind_zone.gd` | *(nada)* | AMB/LOOP | mudo | laço `vento_ciclo` −26 dB, um canal partilhado por todas as zonas | ✅ |
| entrar na zona | `wind_zone.gd:_ao_entrar` | *(nada)* | 1SHOT | mudo | `vento_rajada` −13 dB, recarga 1,2 s **por corpo** | ✅ |
| ficar dentro | idem | — | — | risco de spam | histerese dupla (dicionário `_saudados` + cooldown no `Som`) → 0 vozes em 30 frames | ✅ |
| pulso da zona | `modo = PULSADO` | — | — | seria 1 som/s | **deliberadamente mudo** — a guia visual e o empurrão já dizem | ✅ |
| sair / trocar de cena | `_ao_sair`, `_exit_tree` | — | LOOP | vazamento | fecho com contagem por grupo `zonas_vento`; `Som._process` mata tudo na troca de cena | ✅ |
| **SINOS** |
| sino da torre (N11) | `sino_torre.gd:tocar` | *(nada)* | MEC | mudo | **`sino_mecanismo`** −8 dB, badalada longa e limpa | ✅ |
| sino do chefe | `chefe_sino_vivo`, `chefe_vyrak` | `sino_ataque` | — | — | **intocado** (é golpe, e soa a golpe) | ✅ |
| **MECANISMOS** |
| alavanca | `alavanca.gd` | `selo` | MEC | rouba o checkpoint | `mecanismo` −11 dB, pitch 1,12/0,86 | ✅ |
| placa de peso | `placa_peso.gd` | `selo` | MEC | idem | `mecanismo` −13 dB | ✅ |
| grade a abrir | `porta_trancada.gd` | `porta` | MEC | é a porta de fim de nível | `portao_abre` −10 dB | ✅ |
| grade a fechar | idem | `selo` | MEC | é o checkpoint | `portao_fecha` −10 dB (varrimento invertido) | ✅ |
| elevador START | `tumulo_elevador.gd` | *(nada)* | MEC | mudo | `mecanismo` −15 dB pitch 0,80 | ✅ |
| elevador LOOP | idem | *(nada)* | LOOP | mudo | laço `mecanismo_ciclo` −24 dB, partilhado pelo grupo `tumulos` | ✅ |
| elevador STOP | idem | *(nada)* | MEC | mudo | `mecanismo` −17 dB pitch 0,62 + fecho do laço | ✅ |
| vela acende/apaga | `vela.gd` | `selo` / `onda` | INT | checkpoint / chefe | `mecanismo` −19/−21 dB | ✅ |
| serra, plataformas móveis | `serra.gd`, `plataforma_*.gd` | *(nada)* | — | — | **deixadas mudas de propósito** — ver §5 | ➖ |
| **PERIGOS** |
| plataforma a ceder (telegrafo) | `plataforma_quebra.gd` | *(nada)* | HAZ | mudo | `pedra_racha` −14 dB, 1× por pisada | ✅ |
| plataforma a cair | idem | *(nada)* | HAZ | mudo | `pedra_parte` −13 dB | ✅ |
| pedra a soltar-se (aviso) | `pedra_queda.gd` | *(nada)* | HAZ | mudo | `pedra_racha` −15 dB | ✅ |
| pedra no chão | idem | *(nada)* | HAZ | mudo | `pedra_parte` −12 dB (sem 3.º som na queda livre) | ✅ |
| lâmina pendular | `pendulo_lamina.gd` | *(nada)* | HAZ | mudo | `lamina_passa` −14 dB, 1× por travessia (gatilho: mudança de sinal do ângulo) | ✅ |
| jato de fogo | `fogo.gd` | *(nada, removido)* | HAZ | mudo desde que `investida` foi tirado | `fogo_sopro` −16 dB; nada ao apagar | ✅ |
| raio (telegrafo) | `raio_tempestade.gd` | *(nada)* | HAZ | 0,8 s de aviso sem som | `raio_aviso` −17 dB | ✅ |
| raio (descarga) | idem | *(nada)* | HAZ | mudo | `raio_cai` −8 dB, prioridade MÉDIA | ✅ |
| raio desviado p/ para-raios | idem | *(nada)* | HAZ | mudo | `raio_cai` −14 dB pitch 0,82 ("escapaste") | ✅ |
| espinhos fixos | `espinhos.gd` | *(nada)* | — | — | **mudos** — estáticos, sem evento | ➖ |
| água venenosa | `agua_venenosa.gd` | *(nada)* | HAZ | — | **mudo** — `dano = 999` mata, e o `morte_koliani` do Prompt 1 já é o feedback; um splash por cima competia com ele | ➖ |
| **CHECKPOINT** |
| activar | `checkpoint.gd:298` | `selo` −12 dB | PROG | — | **intocado** (validado no Prompt 1); regressão no harness: 1 voz, sem repetição | ✅ |
| **BAÚ** |
| abrir | `bau_chefe.gd` | `apanhar` | INT | pickup genérico | **`bau_abrir`** −9 dB | ✅ |
| receber prémio | idem | *(era o mesmo)* | REW | mesmo evento | **`recompensa`** −7 dB, +0,36 s, prioridade MÉDIA | ✅ |
| **PICKUPS** |
| essência | `essencia.gd` | `apanhar` −14 dB | REW | — | intocado (base da hierarquia) | ✅ |
| coletável comum | `coletavel.gd` | `apanhar` −6 dB | REW | — | intocado | ✅ |
| **DESBLOQUEIO** |
| habilidade por coletável | `coletavel.gd:174` | `apanhar` −6 dB | PROG | igual a uma moeda | **`desbloqueio`** −6 dB, prioridade MÉDIA | ✅ |
| habilidade do chefe (N5) | `nivel_com_chefe.gd:227` | *(nada)* | PROG | — | **fica sem som de propósito** — corre no instante do `chefe_cai` + `conquista`; ver §4 | ➖ |
| melhoria no Santuário | `santuario.gd:221` | `conquista` | PROG | fanfarra de vitória num botão | `desbloqueio` −9 dB | ✅ |
| recusa no Santuário | `santuario.gd:223` | `dano` | INT | som de levar dano | `ui_negado` −9 dB | ✅ |
| recusa no equipamento | `seletor_equip.gd:641` | `dano` | INT | idem | `ui_negado` −10 dB | ✅ |
| **FIM DE NÍVEL / PORTAL / PORTAS** |
| porta de fim de nível | `porta.gd:67` | `transicao` −3 dB | TRA | o som mais alto da cadeia | `transicao` **−7 dB** | ✅ |
| portal | `portal.gd:208` | `transicao` −10 dB pitch 1,08 | TRA | — | **intocado** (Prompt 1); regressão verde | ✅ |
| entrar num nível (menu) | `seletor_niveis.gd:800` | `porta` −10 dB | TRA | — | intocado — aqui `porta` é mesmo uma porta | ✅ |

---

## 3. Os 16 streams novos

Sintetizados por `tools/gerar_sfx_3b.py` (método da 9H.13B: corpo +
transiente + cauda, normalização por **sonoridade** — RMS da janela de 100 ms
mais forte — e não por pico). Sem samples de terceiros, sem licenças, sem
numpy. 2,0 MB no total, todos mono 44,1 kHz como o resto do catálogo.

| ficheiro | dur | alvo (son.) | LUFS | pico | papel |
|---|---:|---:|---:|---:|---|
| `vento_ciclo.wav` | 6,00 | −25,0 | −24,8 | −16,4 | AMB loop |
| `mecanismo_ciclo.wav` | 2,40 | −23,0 | −28,2 | −12,5 | AMB loop |
| `vento_rajada.wav` | 0,85 | −18,0 | −21,8 | −8,4 | vento gameplay |
| `mecanismo.wav` | 0,46 | −16,0 | −22,6 | −4,4 | alavanca/placa/elevador |
| `portao_abre.wav` | 0,95 | −14,5 | −22,9 | −7,9 | grade |
| `portao_fecha.wav` | 0,95 | −15,5 | −23,2 | −6,3 | grade |
| `pedra_racha.wav` | 0,70 | −18,0 | −26,3 | −11,2 | telegrafo |
| `lamina_passa.wav` | 0,34 | −17,5 | *(curto)* | −6,4 | pêndulo |
| `raio_aviso.wav` | 0,62 | −18,5 | −21,4 | −14,3 | telegrafo |
| `fogo_sopro.wav` | 0,62 | −15,0 | −18,8 | −4,4 | jato |
| `pedra_parte.wav` | 0,80 | −13,5 | −24,4 | −1,5 | impacto |
| `sino_mecanismo.wav` | 2,30 | −12,0 | −21,5 | −6,6 | sino da torre |
| `bau_abrir.wav` | 0,78 | −12,0 | −19,4 | −1,4 | baú |
| `raio_cai.wav` | 1,40 | −10,5 | −18,0 | −3,8 | descarga |
| `recompensa.wav` | 1,30 | −11,0 | −16,2 | −2,9 | prémio |
| `desbloqueio.wav` | 1,80 | −10,5 | −15,1 | −5,0 | progressão |

**Sonoridade ≠ LUFS.** A coluna "alvo" é o RMS da janela de 100 ms mais forte
(o que o ouvido regista num som curto); o LUFS integrado é uma média com
gate sobre o ficheiro inteiro, e por isso caudas longas puxam-no para baixo
(`pedra_parte`: −13,5 de sonoridade, −24,4 LUFS). `lamina_passa` (0,34 s) é
curto demais para o gate do EBU R128 e lê −70 — não é um defeito.

Todos os picos ficam em −1,4 dBFS ou abaixo: há margem para as 8 vozes
somarem sem clipar o master.

**Hierarquia, como pedido (AMBIENCE < MECHANISM < HAZARD/INT < PROGRESSION):**

```
mecanismo_ciclo -28,2 │ vento_ciclo -24,8      AMBIENCE
portao -22,9/-23,2 │ mecanismo -22,6 │ rajada -21,8   MECHANISM
sino -21,5 │ raio_aviso -21,4 │ bau_abrir -19,4 │ fogo -18,8 │ raio_cai -18,0
                                                HAZARD / INTERACTION
recompensa -16,2 │ desbloqueio -15,1            PROGRESSION
conquista -10,4 (legado, intocado)              TOPO ABSOLUTO
```

Nenhum som novo ultrapassa a `conquista`, que continua a ser o momento mais
alto do jogo.

### Os dois laços

São os primeiros sons contínuos do jogo. A emenda de um laço ouve-se sempre:
ou um estalo (salto de fase) ou um buraco (queda de energia na junção). Os
dois evitam-se com um crossfade de **potência constante** (`sin`/`cos`, não
linear — duas fontes de ruído descorrelacionadas somam em potência, e
0,5 + 0,5 de amplitude é −3 dB de energia).

Para o `mecanismo_ciclo` isso não chegou: as partes **deterministas** (as
duas sinusoides do rangido e a modulação lenta) não fechavam um número
inteiro de ciclos no corpo, e a junção somava fases diferentes.

```
mecanismo_ciclo, junção medida:  1,76 dB  (frequências cruas)
                                 0,30 dB  (arredondadas a múltiplos de 1/2,4 s)
vento_ciclo, junção medida:      0,02 dB  (só ruído — o crossfade basta)
```

O gerador mede isto sozinho e sai com código ≠ 0 acima de 1,5 dB.

---

## 4. Decisões de NÃO tocar nada

O briefing pede "não adicionar ruído desnecessário" e "não criar 5 sons
quando um one-shot chega". Ficaram deliberadamente mudos:

- **Zona de vento no modo PULSADO** — um som por pulso é 1/s. O que pulsa
  lê-se pela guia e pelo empurrão.
- **Serra e plataformas móveis** — são cenário *permanente*. Um laço por
  serra em cada nível é ruído constante e vozes gastas num jogo de telemóvel.
- **Espinhos fixos** — não têm evento nenhum; só existem.
- **Água venenosa** — `dano = 999` mata a Koliani, e o `morte_koliani` que o
  Prompt 1 corrigiu já é o feedback. Um splash por cima competia com ele, e
  a Fase 5 diz que o SFX do perigo não se pode confundir com o do jogador.
- **Pedra em queda livre** — entre o aviso e o impacto não há som. Mais um
  evento no meio tirava peso ao único que interessa.
- **Chama a apagar-se** — não é informação que o jogador precise.
- **Habilidade do chefe (N5)** — `nivel_com_chefe.gd` desbloqueia o salto
  duplo no instante em que o chefe morre, quando já tocam o `chefe_cai` e,
  0,45 s depois, a `conquista` de 6,1 s. Um `desbloqueio` no meio seria o
  terceiro jingle empilhado. Anuncia-se pela HUD e pelo baú que nasce a
  seguir. (O `Coletavel` com `habilidade_id` toca `desbloqueio`: esse não
  tem fanfarra nenhuma por cima.)

---

## 5. Dois defeitos de runtime encontrados pelo caminho

Nenhum destes é de mistura; os dois estavam a fazer a funcionalidade não
existir, e os dois foram apanhados porque o harness mede o que o motor faz
em vez de ler o código.

**1. `loop_end = 0` não quer dizer "até ao fim".** É uma região de ciclo de
comprimento zero: o player arranca e pára no mesmo frame. Media-se
`playing == false` com `loop_mode == 1` — parecia um laço que não arrancava e
era um laço vazio. Corrigido em `som.gd:_marcar_ciclico` com
`loop_end = int(get_length() * mix_rate)`.

**2. `AnimatableBody2D` com `sync_to_physics = true` devolve a transformada
ANTIGA.** O `tumulo_elevador.gd` detectava "anda" comparando
`global_position` antes e depois da atribuição — e lia sempre deslocamento
zero, com a laje a subir à vista. O laço nunca arrancava. Passou a
perguntar `global_position.distance_to(alvo) > PARADO` ("tem para onde ir"),
que é a pergunta certa e não depende do momento em que a transformada é
aplicada.

### E uma armadilha de método, para a próxima bancada

As zonas, as placas de detecção e os baús ficam todos na origem. Uma Koliani
**viva** em cena dispara o `body_entered` a sério no primeiro frame de
física; o harness chamava depois `_ao_entrar(k)` à mão, já dentro da
recarga, e media zero vozes — lia-se como "o callsite está mudo" quando
tinha tocado um frame antes. Afastá-la 4000 px **não chegou**: o
`body_entered` sai na mesma no frame em que ela é adicionada.

A solução é instanciar a Koliani **fora da árvore** (`instantiate()` sem
`add_child`): não há física nenhuma e `corpo is Koliani` /
`has_method("atualizar_vento")` continuam a responder. Só os blocos em que a
*proximidade é a mecânica* (`PedraQueda`) usam uma Koliani viva — e mesmo
essa fica ao lado da linha de queda, senão leva dano e a voz do `dano` dela
entra na contagem do perigo.

---

## 6. Testes

```
Godot_v4.7.2_console.exe --path . --screen 1 --resolution 640x360 \
    --script res://tools/verificar_sfx_mundo.gd
```

Renderer **real**, não `--headless`: em headless o
`AudioStreamPlayer.playing` nunca fica verdadeiro e metade das asserções
deixava de morder sem dar erro.

### Harness novo — `tools/verificar_sfx_mundo.gd` (0 falhas)

```
SFX MUNDO CATALOGO novos=16 ausentes=0 total=95
SFX VENTO        rajada=1 spam_dentro=0 lacos_2zonas=1
SFX SINO         mecanico=sino_mecanismo.wav vozes=1 (o chefe continua com sino_ataque.ogg)
SFX ALAVANCA     stream=mecanismo.wav vozes=1
SFX PORTAO       vozes=2 ultimo=portao_fecha.wav (repetir estado nao soa)
SFX ELEVADOR     lacos=1 oneshots_em_marcha=0
SFX PLATAFORMA   telegrafo+queda=2 vozes ultimo=pedra_parte.wav
SFX PEDRA        aviso+impacto=2 vozes ultimo=pedra_parte.wav
SFX PENDULO      vozes_por_periodo=2 stream=lamina_passa.wav
SFX CHECKPOINT   (Prompt 1) stream=selo.wav vozes=1 repetido=0
SFX BAU          vozes=2 ultimo=recompensa.wav atraso=0.36s
SFX PICKUP       comum=apanhar.wav (bau e desbloqueio tem os seus)
SFX UNLOCK       stream=desbloqueio.wav (nao e' chefe_cai nem conquista)
SFX PROGRESSAO   porta=-7.0 dB portal=-10.0 dB (conquista -6 no topo)
SFX CENA         lacos_apos_troca=0
SFX DESEMPENHO   pool=8 lacos_max=3 pedidos=5 aceites=3 vivos=3 apos_parar=0
SFX MUNDO FINAL  falhas=0
```

### Regressões Prompt 1–3A — todas PASS, 0 regressões

- `verificar_sfx_criticos.gd` — catálogo **95/95** (79 + 16 novos), portal
  `transicao.wav` 1 voz, checkpoint `selo.wav` 1 voz, UI, morte de inimigo,
  `chefe_cai`→`conquista` a 0,45 s, morte da Koliani. **0 falhas.**
- `verificar_sfx_combate.gd` — combo 1–4, dash, escudo, hurt, as 7 famílias
  de inimigos, projécteis, hurt do chefe, prioridade do pool. **0 falhas.**
- `verificar_sfx_chefes.gd` — sem chaves mortas (os 16 novos estão todos
  ligados), `chefe_cai`/`conquista` reservados ao `chefe_base` em 40
  scripts, falso-kill 0/10, fases, hurt, Guardião, Vyrak, anti-repetição,
  prioridade. **0 falhas.**

### Suite completa

`tests/run_tests.tscn` → **"OK -- todos os testes passaram"**, exit 0.

Aparece o erro conhecido de teardown da Região III, com a assinatura exacta
que o briefing manda documentar e não corrigir aqui:

```
SCRIPT ERROR: Cannot call method 'get' on a previously freed instance.
   at: teste_r3_vyrak_leva_dano_muda_de_fase_e_morre (res://tests/run_tests.gd:4010)
```

**PREEXISTENTE.** Vyrak é um chefe e não foi tocado neste lote; o erro sai no
teardown e não faz a suite falhar.

### Smoke-test das cenas afectadas (300 frames, renderer real, 0 erros)

`Torre_da_Tempestade`, `Torre_dos_Sinos`, `Cemiterio_dos_Reis`,
`Fornalha_dos_Pecadores`, `Corredor_das_Execucoes`.

---

## 7. Desempenho

O pool continua com **8 vozes**. Os laços **não** o aumentam: são players
próprios, no mesmo bus `SFX`, com tecto duro `LACOS_MAX = 3`. Pedir o 4.º
laço devolve `false` e fica calado — medido no bloco `SFX DESEMPENHO`
(5 pedidos, 3 aceites).

Um laço pertence ao autoload, não à cena. Sem guarda, o vento do N08 seguia
para o menu. `Som._process` compara `get_tree().current_scene` com a cena
que estava de pé quando o laço abriu e mata tudo na troca — provado em
`SFX CENA lacos_apos_troca=0`.

Anti-spam, por evento (nada corre por frame):

| evento | mecanismo | recarga |
|---|---|---|
| rajada de vento | dicionário por corpo **+** cooldown no `Som` | 1,2 s |
| pêndulo | mudança de sinal do ângulo + cooldown | `periodo × 0,35` |
| jato de fogo | cooldown por instância | `intervalo × 0,5` |
| raio | cooldown por instância | `aviso × 0,5` |
| sino da torre | `recarga` da própria mecânica | 0,5 s |
| pedra / plataforma | cooldown por instância | 0,25–0,3 s |

Chaves de cooldown por `instance_id`: dois pêndulos lado a lado soam cada um
o seu, mas nenhum dispara duas vezes.

---

## 8. Gameplay

**NÃO alterado.** Zero mudanças em física, dano, timings, lógica de
checkpoint, lógica de portas, forças de vento, progressão ou saves.

A única mudança fora de áudio é o `tumulo_elevador.gd`, e é uma **leitura**:
a pergunta "anda?" passou de "mexeu-se desde a linha anterior" para "tem
para onde ir". O movimento (`move_toward(alvo, velocidade * dt)`) é byte a
byte o mesmo.

---

## 9. HUMAN LISTEN REQUIRED

Nada aqui foi ouvido por uma pessoa. A validação é medida, não auditiva.
A ouvir, por ordem de risco:

1. **vento ambiente** — é o primeiro som contínuo do jogo. −26 dB é uma
   aposta: acima disso tapa os passos, abaixo disso não existe. E confirmar
   que o ciclo de 6 s não se dá a ouvir como ciclo.
2. **laço do elevador** — 2,4 s é curto; o rangido pode virar padrão.
3. **sino da torre** — 2,3 s de cauda; confirmar que não tapa o combate que
   acontece logo a seguir à badalada.
4. **mecanismos** — a alavanca e a placa partilham ficheiro com o elevador,
   só mudam de tom; confirmar que não soam a "o mesmo clique outra vez".
5. **perigos** — sobretudo se o `raio_cai` a −8 dB é demais, e se o
   `pedra_racha` se lê mesmo como aviso e não como dano.
6. **baú** — os 0,36 s entre `bau_abrir` e `recompensa`.
7. **sequência de progressão completa** — matar o chefe, abrir o baú, sair
   pela porta, de seguida e sem cortes.
8. **hierarquia de volume** no conjunto.

**DEVICE VALIDATION REQUIRED:** Web e telemóvel reais. Os laços são novos no
motor de áudio e o Web já deu problemas de buses criados em runtime
(ver `execution-9f-ui-audio-web`); confirmar que `vento_ciclo` toca mesmo no
Chrome e que não estala no Android.
