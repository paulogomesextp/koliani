# Execution 8.1E — A causa dos ~2 s: reler o manifesto 1312 vezes

Data: 10 de setembro de 2026. Ramo: `perf/windows-gate-8-1`.

## Estado: **PASS — causa provada e corrigida.**

`EstadoJogo.guardar()` passou de **2047 ms** (medição da 8.1C) para **9.2 ms**
de mediana, na mesma ferramenta e na mesma máquina. Uma gravação deixou de
custar dois segundos e passou a caber dentro de um frame a 60 Hz.

## A causa, medida

`ProgressionIDs.identidades()` lia e fazia **parse do
`data/level_manifest.json` do disco a cada chamada** — não havia cache nenhum.
E cada gravação chama-o **1312 vezes**:

- `SaveFoundation.escrever_seguro()` faz **seis validações completas**
  (processar + ler TEMP + ler primary + ler backup + verificar backup +
  releitura final);
- cada validação chama `identidades()` dezenas de vezes através de
  `_validar_campos_v3`;
- e `reward_ids()` sozinho chama-o **uma vez por nível** — 100 chamadas cada
  vez que é invocado.

1312 leituras × ~1,8 ms = ~2,4 s. Bate certo com o que se via.

### Números, com o cache desligado vs. ligado (mesmo processo)

`tools/bench_save.tscn`, 9 gravações de cada lado:

| | ANTES (sem cache) | DEPOIS (com cache) |
|---|---|---|
| `guardar_em()` mediana | **2481,3 ms** | **9,8 ms** |
| `guardar_em()` pior | 2570,1 ms | 10,6 ms |
| leituras do manifesto por gravação | **1312** | **0** |
| parses de JSON por gravação | **1312** | **0** |
| chamadas a `identidades()` por gravação | 1312 | 1312 |

Etapas, por gravação:

| etapa | antes | depois |
|---|---|---|
| A `para_dicionario()` | 10,57 ms | 0,01 ms |
| B `JSON.stringify` | 0,02 ms | 0,02 ms |
| C `identidades()` (1×) | 2,020 ms | 0,001 ms |
| F `processar()`/validar | 413,2 ms | 0,5 ms |
| G escrita crua do TEMP | 0,40 ms | 0,41 ms |
| H/I/J/M `ler()`+validar | 430,7 ms | 0,8 ms |
| L renomear/apagar | 1,30 ms | 1,17 ms |

Confirmação com `tools/verifica_gravar.tscn` — a **mesma** ferramenta que
produziu o 2047 ms da 8.1C, agora sobre o `EstadoJogo` autoload real:

```
mediana=9,2 ms   média=9,5 ms   pior=14,3 ms
```

## O que a 8.1C disse a mais, e que agora se corrige

A 8.1C atribuiu os ~2 s a **~10 operações de ficheiro síncronas inspeccionadas
pelo antivírus em `%APPDATA%`, ~200 ms cada**. Isso **estava errado**, e o
relatório fica como está para não apagar o percurso — a medição de agora
mostra que o custo real de tocar no disco por gravação é de **~2 ms**
(etapa G 0,4 ms + etapa L 1,3 ms). O tempo estava todo em CPU, a reparsear o
mesmo ficheiro imutável. **Não era o disco nem o Defender.** A exclusão do
Windows Defender que ficou sugerida como "teste de confirmação" não era
necessária e não teria mostrado nada.

## A correção

`scripts/progression_ids.gd`: cache do manifesto **e** das identidades já
derivadas, protegido por `Mutex`, com `aquecer()` chamado no `_ready()` do
`EstadoJogo`.

O manifesto é imutável em runtime (vem dentro do PCK) e nenhuma ferramenta em
GDScript o reescreve dentro do processo — quem o gera são ferramentas Python,
noutro processo. Mesmo assim existe `invalidar_cache()` para ferramentas, e
`usar_cache(false)` para a bancada poder medir o antes.

Não muda um único ID, nem o schema, nem a validação, nem a progressão. O teste
`teste_manifesto_cache_nao_altera_identidades` prova a igualdade byte a byte
entre o que o disco dava e o que o cache dá.

**Cuidado registado:** `identidades()` e `carregar_manifesto()` passam a
devolver a instância **partilhada**. São de leitura. Auditei os consumidores
todos (`level_session.gd`, `save_foundation.gd` ×4, `run_tests.gd`, e os usos
internos) — nenhum muta. Quem precisar de mexer que use `.duplicate(true)`.

## A thread de fundo já não é precisa

A 8.1D tinha escrito `scripts/save_pipeline.gd` (thread + coalescência). Com
9,2 ms de mediana e 14,3 ms de pior caso, uma gravação cabe num frame de
16,7 ms. Meter uma thread para isto era risco arquitetural a troco de nada.

**`save_pipeline.gd` foi REMOVIDO** — deixá-lo lá, inerte e por testar, era
arquitetura morta a fingir-se de viva. O desenho não se perde: está no commit
`0269d20` e descrito em `execution_8_1d_save_nao_bloqueante.md`. Se algum dia
uma gravação voltar a passar do frame, ressuscita-se com um `git checkout`.

Isto também resolve a Web/PWA, que a thread **não** resolvia: o export corre
`single-threaded, no GDExtension support` (confirmado na consola do build), por
isso o fallback lá seria síncrono e continuaria a congelar 2 s. O cache é a
única correção que serve as duas plataformas.

## Validação

| | |
|---|---|
| Suite completa | OK, exit 0 |
| Save foundation (11 testes) | OK, exit 0 |
| Progression IDs (6 testes) | OK, exit 0 |
| Testes novos | 2 (leitura zero + identidades iguais) |
| Build Windows | exportado, arranca limpo (300 frames, 0 erros) |
| Build Web/PWA | exportado, arranca, menu → seletor de níveis, 0 erros na consola |

O teste novo `teste_save_nao_repete_leitura_do_manifesto` tem **controlo
negativo**: desliga o cache e exige que aí a leitura dispare acima de 100. Sem
isso a asserção passava mesmo que deixasse de medir alguma coisa.

## Armadilha de método (a que custou a 8.1D)

Uma cena de ferramenta cujo script tem **erro de parse** não faz o Godot
estoirar — ele fica a correr para sempre com o log vazio, e parece lentidão.

A trava agora é esta, e leva segundos:

```bash
godot --headless --path . --check-only --script res://tools/x.gd
```

Sai com 1 e imprime o erro. `tools/bench_save.gd` tem também um limite de
240 s que aborta com código 2. Correr o `--check-only` **antes** de qualquer
cena de ferramenta nova.
