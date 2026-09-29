# QA final de áudio — SFX Overhaul, Prompt 4

Fecha a fase **automática** do overhaul. A partir daqui, qualquer mudança de
timbre ou volume nasce do ouvido do Paulo — ver
[`HUMAN_SFX_PLAYTEST.md`](HUMAN_SFX_PLAYTEST.md).

Regra deste passe: corrigir só o que é **objetivo** (stream em falta,
routing errado, duplicação, clipping, loop com emenda, fuga de vozes, spam,
erro de import ou de runtime). Tudo o que é "isto devia ser mais forte?"
ficou por ouvir.

**STATUS: READY_FOR_HUMAN_TEST** — com uma ressalva no Web (§7) e uma
decisão à espera do Paulo (§3).

---

## 1. Inventário (Fases 1–2)

`tools/inventario_audio.py` cruza três coisas que andavam separadas: o
catálogo (`Som.CAMINHOS`), os ficheiros em `assets/audio/` e os callsites no
código do jogo. É na junção que vivem os defeitos silenciosos — uma chave
sem ficheiro deixa o evento mudo sem erro nenhum.

```
chaves=95  ficheiros=117  MISSING=0  UNUSED=0  duplicados=0  órfãos reais=0
sobras de formato=13 (143 KB)
```

Tabela completa por categoria (PLAYER / ENEMY / BOSS / WORLD / HAZARD /
MECHANISM / PROGRESSION / UI / AMBIENCE), com formato, duração, SR, canais,
pico, LUFS e callsite: [`final_sfx_inventory.md`](final_sfx_inventory.md).

**Sobras de formato** — 13 `.ogg`/`.mp3` que ficaram para trás quando a
9H.13B trocou os samples de terceiros por `.wav` sintetizados. Nenhuma chave
lhes aponta e entram no export sem serem tocados. Não apagados: é decisão do
Paulo.

### A armadilha do detector de callsites

A primeira versão deu **29 falsos "sem uso"** — incluindo as 21 famílias de
inimigos e os 4 golpes do combo. Isso é pior do que não medir: convida a
apagar som que o jogo toca. O jogo pede sons de três maneiras e é preciso
cobrir as três:

- **directo** — `Som.toca("selo", ...)`;
- **tabela** — `const SOM_COMBO := ["ataque", "ataque2", ...]`, a chave está
  num array e a chamada usa o índice;
- **composto** — `Som.toca("mob_%s_%s" % [fam, que])`, em que a chave nunca
  aparece inteira em lado nenhum. O molde vira expressão regular e vê-se que
  chaves casam.

`tools/` e `scripts/dev_sons.gd` não contam como uso: o painel de sons do
dev toca o catálogo inteiro e mascararia todas as chaves mortas.

---

## 2. Clipping (Fases 3–4)

Encontrado com `astats`, que lê a descodificação em vírgula flutuante.
`volumedetect` **mentia** aqui: mede depois de cortar a int16 e dizia
"0,0 dB" — parecia um ficheiro no tecto e era um ficheiro **por cima** do
tecto.

Três samples CC0 descodificam acima de 0 dBFS:

| ficheiro | pico | RMS | crista | callsites |
|---|---:|---:|---:|---:|
| `esmagar.ogg` | **+7,26** | −20,8 | 28 dB | 16 |
| `golpe_pesado.ogg` | **+9,63** | −20,2 | 30 dB | 11 |
| `grito.ogg` | **+1,90** | −16,0 | 18 dB | 4 |

É próprio do Vorbis. O Godot descodifica para float, soma no bus e só corta
no fim — e os dois piores tocam a −5/−6 dB, portanto chegam ao master a
+3,6 dBFS. São os dois ataques de chefe mais usados do jogo a distorcer.

`raio.wav` é outro caso: 238 amostras coladas ao tecto (0,096%) e flat factor
10,6 — **já vem clipado**. Um limitador não desfaz o que já foi cortado; só
re-sintetizar, e isso é redesenho. Toca entre −8 e −15 dB, nunca chega ao
tecto do master. **Não tocado**, fica para HUMAN LISTEN.

---

## 3. A correcção, e porque é que o critério óbvio estava errado

`tools/corrigir_clipping_p4.py`. Duas tentativas falharam antes de acertar,
e as duas por motivos que vale a pena guardar.

**Erro 1 — o limitador.** Um limitador clássico (ataque instantâneo,
libertação de 40 ms) arruinou os ficheiros: o `golpe_pesado` perdeu
**6,7 LUFS**. O excesso está em 36 amostras dentro de **3 ms**; uma
libertação de 40 ms agarra 1 700 amostras por pico, e num som de meio
segundo isso é o som inteiro a levar duck. A dimensão certa é a **janela**,
não o tempo de recuperação: calcula-se o ganho necessário amostra a amostra
e espalha-se por 6 ms com um perfil de coseno levantado.

**Erro 2 — o critério.** Exigi que o LUFS integrado não mexesse mais de
0,5 dB. Falhou por 2,7 e 3,5 dB — e era o critério que estava errado. Estes
sons são quase silêncio com um golpe (no `esmagar` a mediana das amostras é
**0,002** e o máximo é **2,308**): o transiente é praticamente toda a
energia do ficheiro, logo domina o RMS e domina o bloco de 400 ms do
EBU R128. Baixar um pico de +9,6 dB **tem** de mover essas medidas, por
construção.

Só que **o jogador nunca ouviu esses +9,6 dB**. O motor já corta no fim: o
que sai hoje pelas colunas é o sinal ceifado, com a distorção que isso traz.
A referência honesta não é o float cru (que é irreproduzível) — é o mesmo
ficheiro **ceifado**, que é o que se ouve hoje. Contra essa referência a
pergunta passa a ser a certa: *depois de tirar a distorção, o golpe ficou
com o mesmo peso?*

E aí faltava ainda o **ganho de compensação**: um sinal ceifado tem o topo
chato durante 107 amostras, e isso é mais energia do que a mesma onda
limitada com rampa. Tirar a distorção tira também esse peso emprestado. Por
isso limita-se **e** repõe-se o nível, com uma procura amortecida (sem
amortecimento oscila: mais ganho → mordida mais larga → menos sonoridade →
pede mais ganho).

### Resultado

| ficheiro | pico antes | pico depois | compensação | dLUFS | dSonoridade | |
|---|---:|---:|---:|---:|---:|---|
| `golpe_pesado.ogg` | +9,63 | **−0,80** | +2,69 dB | −0,30 | −0,09 | ✅ corrigido |
| `grito.ogg` | +1,90 | **−0,77** | +0,42 dB | +0,40 | −0,05 | ✅ corrigido |
| `esmagar.ogg` | +7,26 | — | +4,88 dB | −1,40 | −0,48 | ⏸ **recusado** |

**O `esmagar` não passa e não foi forçado.** O excesso não é um pico, são
sete rajadas espalhadas por 18 ms; repor a sonoridade pede +4,88 dB, e a
esse nível o limitador morde 451 amostras em vez de 107 — já não é
cirúrgico, e o LUFS cai 1,40 dB. Mudar 1,4 dB no ataque de chefe mais usado
do jogo é decisão do Paulo, não do script. Fica medido e a um comando:

```bash
python tools/corrigir_clipping_p4.py --forcar esmagar.ogg
```

Até lá continua a distorcer — exactamente como já distorcia antes deste
overhaul.

---

## 4. Laços (Fase 5) — e um defeito real do Prompt 3B

`tools/verificar_lacos_p4.gd`, com renderer real e o relógio a correr.

```
LACOS arranque/paragem: vento ok, mecanismo ok
LACOS vento_ciclo:     32 s, ciclo 6,00 s, voltas=5,  calado=0, pos_max=5,77
LACOS mecanismo_ciclo: 32 s, ciclo 2,40 s, voltas=13, calado=0, pos_max=2,37
LACOS 20 pedidos iguais -> 1 player; filhos de audio no Som=9
LACOS troca de cena: lacos=0, players no Som=8 (so' o pool)
LACOS 3 reloads: lacos=0, players 8 -> 8 (sem acumular)
LACOS 3 respawns dentro da cena: lacos=1 (esperado 1)
LACOS FINAL falhas=0
```

### O defeito

Este bloco apanhou um bug **meu, do Prompt 3B**, que a bancada da 3B tinha
deixado passar:

> **Em GDScript, um `Object` já libertado compara IGUAL a `null`.**

O guarda que mata os laços na troca de cena comparava *referências* de cena.
Com a cena antiga já libertada, `null != <libertado>` dava **falso** — ou
seja, o guarda calava-se exactamente no caso para que foi feito. E é o caso
normal: `change_scene_to_file()` liberta a cena antiga. **Sair de um nível
com vento levava o vento para o nível seguinte.**

A bancada da 3B passou porque lá a cena velha ainda estava viva quando a
nova entrava. Corrigido guardando o `instance_id` (um inteiro nunca "vira
null"), e o caso — libertar a cena velha **primeiro** — ficou preso no
`verificar_sfx_mundo.gd` para não voltar.

### Segundo defeito, também real

`WindZone._exit_tree` rebentava com um corpo já libertado na lista:

```
Invalid type in function '_remover_do_corpo' ... argument 1 (previously freed)
```

O `is_instance_valid` estava **dentro** da função, mas o parâmetro é tipado
(`corpo: Node`) e o GDScript valida o tipo do argumento **antes** de entrar.
Basta um inimigo morrer dentro da zona de vento. A guarda passou para o
sítio da chamada.

---

## 5. Testes (Fases 6–7)

| harness | resultado |
|---|---|
| `verificar_sfx_criticos.gd` (Prompt 1) | **0 falhas** — catálogo 95/95 |
| `verificar_sfx_combate.gd` (Prompt 2) | **0 falhas** |
| `verificar_sfx_chefes.gd` (Prompt 3A) | **0 falhas** |
| `verificar_sfx_mundo.gd` (Prompt 3B) | **0 falhas** — 16 blocos |
| `verificar_lacos_p4.gd` (novo) | **0 falhas** — 6 blocos |
| `tests/run_tests.tscn` | **OK — todos os testes passaram**, exit 0 |

### O erro conhecido do runner — agora com prova

A suite emite erros de teardown na Região III. O briefing manda documentar
como preexistente se a assinatura for idêntica — mas a mensagem que eu tinha
registado na 3B era outra (`Cannot call method 'get' on a previously freed
instance`) e a que sai agora é esta:

```
Invalid access to property or key 'process_frame' on a base object of type 'null instance'
   at: teste_r3_niveis_carregam (run_tests.gd:3940)
Invalid access to property or key 'root' ...
   at: teste_r3_vyrak_identidade (run_tests.gd:3945)
   at: teste_r3_vyrak_leva_dano_muda_de_fase_e_morre (run_tests.gd:3983)
Cannot call method 'quit' on a null value
   at: _correr_tudo (run_tests.gd:160)
```

Como a mensagem mudou, não assumi. Fiz `git stash` de todo o trabalho, corri
a suite no HEAD limpo `61cb80f2` e o resultado é **byte a byte o mesmo**.
**PREEXISTENTE, provado** — não é assinatura semelhante, é a mesma saída num
worktree sem nenhuma alteração minha. Não corrigido, como mandado.

### Smoke-tests

Windows QA: arranca, corre 400 frames, sai limpo, 0 erros de script. Os 16
streams novos estão no PCK (verificado no binário).

---

## 6. Gameplay (Fase 8)

**Não alterado.** Nada em dano, física, fases de chefe, lógica de inimigos,
progressão, saves, checkpoints, portas, forças de vento, perigos ou timings
funcionais.

As duas mudanças de código deste passe são defensivas:

- `som.gd` — o guarda de cena passa a comparar `instance_id` em vez de
  referência (corrige um bug, não muda comportamento pretendido);
- `wind_zone.gd` — `is_instance_valid` movido para o sítio da chamada.

Os dois assets re-codificados (`golpe_pesado`, `grito`) mantêm duração,
sample rate e canais; muda só o pico.

---

## 7. Builds (Fases 9–11)

### Windows — OK

```
C:\Projetos\koliani-sfx\build\qa\Koliani-SFX-QA.exe     (207 MB, PCK embutido)
```

Export release. Arranca, menu aparece, sai limpo. **Não substitui** o build
oficial em `C:\Projetos\koliani\build\windows\Koliani.exe`.

### Web — arranca; áudio **por provar**

```
C:\Projetos\koliani-sfx\build\qa\web\
```

Servir com os cabeçalhos de isolamento (o helper já os manda):

```bash
python tools/servidor_prova_web.py build/qa/web build/qa/prova 8099
```

→ `http://localhost:8099/index.html`

Verificado no Chrome real: carrega, o menu desenha-se, `crossOriginIsolated`
é `true`, o `AudioContext` fica em **`running`** com o relógio a avançar, e
não há erros de áudio na consola.

**O que NÃO consegui provar: que sai som.** Liguei um `AnalyserNode` à saída
e o pico ficou em 0,0000 — mas as teclas injectadas não chegaram ao motor (o
menu não se moveu), por isso nunca cheguei a disparar um som. O teste é
**inconclusivo**, não negativo. Fica para o ouvido, e com atenção: "Web
mudo" já foi um defeito real neste projecto (9F).

Erros na consola, todos benignos e não-áudio: registo do ServiceWorker falha
no servidor de teste, e o vídeo da intro não toca no browser (tratado —
"a saltar").

### Android — BLOCKED BY ENVIRONMENT

Não há SDK nesta máquina. A definição do editor aponta para
`C:\Users\paulo\AppData\Local\Android\Sdk`, que **não existe**, e o próprio
export do Windows regista `Unable to open Android 'build-tools' directory`.
Como mandado, não inventei um SDK. O APK sai do CI.

---

## 8. O que fica para o humano

Checklist prática, percurso de teste de 10–15 min e as cinco apostas que
podem estar erradas: [`HUMAN_SFX_PLAYTEST.md`](HUMAN_SFX_PLAYTEST.md).

Nada foi integrado em `master`. A PWA de produção, o `win-latest` e o
`Koliani.exe` oficial ficam como estavam.
