# Execution 8.1D — Pipeline de gravação não-bloqueante

Data: 10 de setembro de 2026. Ramo: `perf/windows-gate-8-1`.

## Estado: **BLOCKED — INCOMPLETO. NÃO ENTREGA O OBJETIVO.**

> **Nota da 8.1E (posterior).** A hipótese do manifesto que este relatório
> levantou **confirmou-se**: 1312 leituras+parses por gravação, 2481 ms -> 9,8 ms
> com cache. A thread de fundo deixou de ser necessária e
> `scripts/save_pipeline.gd` **foi removido** — o desenho fica no commit
> `0269d20`. Ver [execution_8_1e_causa_do_congelamento.md](execution_8_1e_causa_do_congelamento.md).
> O resto deste documento fica como estava, incluindo o que ficou por fazer.

A sessão foi encerrada a pedido antes de a implementação ser ligada ao jogo.
O que está no repo **não altera o comportamento**: `save_pipeline.gd` existe
mas **nenhum ficheiro o usa**. Os engasgos de ~2 s ao passar num checkpoint e
ao levar dano **continuam exatamente como estavam**.

Isto está escrito assim de propósito. O relatório anterior (8.1C) deixou uma
causa provada; este deixa uma peça por encaixar. Fingir progresso aqui custava
à sessão seguinte mais do que poupava.

## O que ficou feito

`scripts/save_pipeline.gd` (210 linhas, **compila**, provado pela suite
completa a passar com a classe registada). Desenho:

- **thread principal**: recebe um instantâneo já imutável, guarda-o como
  pendente, sai. Não toca no disco.
- **worker**: acorda por semáforo, drena o pendente, chama
  `SaveFoundation.escrever_seguro()` — **o mesmo** código de integridade de
  sempre (TEMP, verificação, backup validado, promoção, releitura final). Não
  há um segundo caminho de escrita, por isso as garantias não se dividem.
- **coalescência last-write-wins**: no máximo 1 escrita ativa + 1 instantâneo
  pendente. Um pedido novo substitui o pendente. O que chega ao disco é sempre
  o pedido mais recente.
- **fecho ordeiro**: `parar()` marca saída, posta o semáforo e junta a thread
  depois de drenar o que falta.
- **fallback de plataforma**: `OS.can_use_threads()` é falso no export Web
  (`variant/thread_support=false` em `export_presets.cfg`), e aí `pedir()`
  grava em modo síncrono — comportamento e contrato idênticos aos de hoje.

## O que falta (por ordem)

1. **Ligar ao `EstadoJogo`** — nada disto corre enquanto isso não acontecer:
   - `_ready()`: aquecer caches na thread principal, `carregar()`, criar o pipeline;
   - `guardar()`: `_pipeline.pedir(instantaneo())` em vez da escrita síncrona;
   - `instantaneo()`: `para_dicionario().duplicate(true)` — **obrigatório**.
     `para_dicionario()` devolve `pistas`, `armas`, `armaduras`,
     `bosses_derrotados` e `recompensas_reclamadas` **por referência**; entregar
     isso ao worker é uma corrida de dados a sério, não teoria;
   - `_notification()`: `NOTIFICATION_WM_CLOSE_REQUEST` e `NOTIFICATION_EXIT_TREE`
     chamam `parar()` (idempotente).
   - `guardar_em()` fica **intocado e síncrono** — é o que os testes usam.
2. Medir: latência do pedido na thread principal vs. duração da escrita em fundo.
3. Testes novos: coalescência, último-estado-vence, morte/transição/saída
   durante escrita.
4. Rebuild do `.exe` e verificação real.

## Descoberta que vale mais do que o resto: onde estão os ~2 s

`ProgressionIDs.identidades()` **lê e faz parse de `res://data/level_manifest.json`
do disco a cada chamada** — não há cache nenhum. E `escrever_seguro()` faz
**seis validações completas** (processar + ler TEMP + ler primary + ler backup +
verificar backup + releitura final), cada uma chamando `identidades()` dezenas
de vezes através de `_validar_campos_v3` e `_e_exame_regional`.

Ou seja: os ~2 s são provavelmente **re-parse do manifesto**, não a escrita em
si nem o antivírus. Isto **não foi medido** — a bancada
(`tools/bench_save.tscn`) foi escrita para o provar mas **nunca chegou a dar
número** (ver abaixo). É uma hipótese forte por leitura de código, nada mais.

Se se confirmar, importa muito: um cache do manifesto (aquecido na thread
principal, protegido por Mutex, o ficheiro é imutável em runtime) reduz a
escrita para dezenas de ms e **resolve também o Web/PWA**, onde não há threads
e o fallback síncrono continuaria a congelar 2 s. A thread de fundo sozinha
não salva a Web.

## Armadilha de método (custou a sessão)

`tools/bench_save.gd` tinha um erro de parse (`var c := v.duplicate()` — o
`duplicate()` de Array devolve Variant e não infere tipo). Com o script da
cena a falhar a carregar, o Godot **não estoira: fica a correr para sempre**
sem imprimir nada. Duas execuções de ~10 minutos foram gastas a olhar para um
log vazio a pensar que era o import.

**Regra:** ao correr uma cena de ferramenta pela primeira vez, procurar
`Parse Error` / `Failed to load script` no log **antes** de assumir lentidão.
Um `--headless` que não imprime nada em 60 s está partido, não ocupado.

O erro está corrigido; a bancada continua **por correr**.

## Validação feita nesta sessão

- Suite completa (`res://tests/run_tests.tscn`): **OK, exit 0**, com
  `save_pipeline.gd` presente e a classe registada.
- Reimport completo: exit 0.
- Nada mais. Sem medições, sem build, sem teste de jogo real.
