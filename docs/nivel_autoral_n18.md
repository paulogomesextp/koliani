# N18 autoral — "Câmara da Lava" (Região IV, Fornalha)

**Data:** 2 out 2026 · **Cena:** `scenes/levels/Cripta_das_Mil_Velas.tscn` (nome
legado — mudá-lo parte saves) · **Gerada por:** `tools/construir_n18_camara.py`
+ `tools/r4_lib.py` (editar lá, nunca no `.tscn`). Chave i18n: `level.n17`.

## Decisões que divergiram do briefing (contrato LOCKED ganha)
1. **O N17 não existia** quando o N18 foi construído (entretanto o colega publicou-o
   no master e o merge foi feito). O N18 reutiliza só peças que já existiam (carrinhos
   `PlataformaCorrente`, `PlataformaQuebra`, `ElevadorColuna`, `PisoQuente`,
   `JatoFornalha`, `LavaFornalha`).
2. **Contrato LOCKED do N18** (`region_04/level_mechanics.png`,
   `layout_usage.png`) = *Câmara da Lava — "o nível sobe junto": lava que sobe,
   plataformas temporárias, válvulas/jatos, queda sem retorno*; 3 segredos,
   combate 45%, inimigos Elemento de Lava / Sentinela de Pressão / Arqueiro
   Ígneo / Autómato Pesado. O briefing pedia "Ritmo da Fornalha". Seguiu-se o
   contrato e a estrutura A–D + arena do briefing foi **tecida à volta da lava
   que sobe**.
3. **Guardião**: o contrato não nomeia o do N18. Usada a **Sentinela de Pressão**
   elite (um dos 4 inimigos principais do N18 na prancha; o Autómato de Fundição
   já é o guardião do N17). Marcado:
   **GUARDIÃO N18 — NECESSITA DECISÃO DO PAULO.**
4. "Elemento de Lava" (contrato) não tem espécie extraída; não se inventou.
5. Dimensão: **6800 px** de largura (briefing: 4200–4800 de referência). Razão:
   4 secções + poço + arena com vãos ≤ envelope do salto duplo. A altura útil
   vai de y=180 (segredo do poço) a y=760 (fundo da lava).

## Mecânica nova (opt-in; nenhum outro nível muda)
`LavaFornalha` ganhou `sobe_amplitude/espera/aviso/subida/topo/desce/fase`
(`scripts/lava_fornalha.gd`). Com `sobe_amplitude = 0` (omissão) nada muda —
provado: baseline de colisões do N16 (que usa a lava) idêntico antes/depois, e
só `Cripta_das_Mil_Velas.tscn` mudou em `scenes/`. A superfície segue um ciclo
fixo contado desde o início do nível (reaparecer repete o ritmo): espera →
AVISO (linha de fusão a piscar, ainda segura) → sobe (smoothstep) → topo →
desce. `elevacao_em(t)` / `em_aviso_em(t)` são funções puras (testadas).

## Layout (Koliani nasce em x 170; chão principal y=600)
| Secção | x | O que ensina |
|---|---|---|
| A — O chão dita o ritmo | 0–1480 | 2 pisos quentes em contra-fase (sem inimigos), 1 jato isolado, CP1, Trabalhador; **lava A que sobe** sobre 2 pedras (545/530) acima da cota máxima (580): observar custa zero |
| B — Linha de produção | 1480–3300 | B1 carrinho simples sobre lava estática; B2 carrinho + 2 jatos dessincronizados (nas pontas do curso o carrinho está fora das colunas: dá para esperar a bordo ou saltar de volta); B3 duas lajes que cedem (0,7 s) a seguir ao carrinho; CP2 e CP3 |
| C — Poço da Fornalha | 3300–4670 | lava C que sobe (740→540, ciclo ~14 s) por baixo; E1 sobe (600→300, vai a 210 = segredo 2), jatos de parede horizontais (emissor sempre em ecrã); patamar → plataforma do meio com piso quente a ciclar (zonas seguras nas pontas) + Trabalhador + Sentinela; 2 lajes → pedra de espera → E2 desce → saída; CP4 |
| D — Câmara de pressão | 4670–5870 | piso quente (decide quando SAIR) → jato (quando SALTAR) → 2 lajes (quando ABANDONAR) → pedra de espera → elevador curto → arena |
| Arena do Guardião | 5870–6780, chão y=450 | SEGURO\|QUENTE\|SEGURO\|QUENTE\|SEGURO; as duas faixas ciclam em contra-fase (desfasadas 2,5 s de um ciclo de 5 s: nunca ardem juntas); propriedade da arena, nada no Guardião as controla; pontas sempre seguras; CP5 |

5 checkpoints (`CheckA1`, `CheckB2`, `CheckC3`, `CheckD4`, `CheckD5`),
3 segredos (essências): **S1** carrinho B2 no extremo → alcova a 110 px (regresso:
cair na Laje 1); **S2** E1 vai além da saída (210) → alcova (regresso: cair no
patamar); **S3** poleiro D1 → 3 saltos → alcova (regresso directo à pedra de
espera, antes do CP5). Inimigos: Trabalhador Corrompido, Arqueiro da Fornalha,
Sentinela de Pressão, Sentinela de Pressão (elite). **Sem chefe.**

**Marco visual do nível:** a *lava eruptiva* (`r4_lava_eruptiva`, "coluna de
magma" da prancha) a marcar a poça A e o poço C.

## Testes
- `tests/test_region04_n18_level.gd` (estrutura, contagens, vãos medidos com o
  salto duplo real, folgas do carrinho, refúgio entre jatos, lava A nunca toca
  as pedras, faixas da arena nunca ardem juntas).
- Crivo de alcance dos 100 níveis: `porta_alcancavel=true` no N18, 0 inalcançáveis.
- `tools/prova_n18_travessia.gd`: piloto determinista (espera por carrinhos,
  elevadores, pisos e jatos, com os relógios reais) atravessa o nível
  inteiro (121 s). 4 quedas ao fundo do poço, todas no salto Laje3→Laje4→pedra
  (imprecisão do piloto, sem recuperação). **Não** é prova de dificuldade humana.
- `tools/bot_humano_r2.gd` (3 perfis) **não** serve para o N18: não sabe esperar
  por plataformas temporizadas; morre ~50× no E2 (trata-o como chão fixo).
- Capturas reais: `docs/qa/n18_autoral/`.

## Por fazer / risco
- **HUMAN PLAYTEST REQUIRED**: justiça dos timings (ciclo da lava C, jatos,
  elevadores sem pausa nas pontas), dificuldade de C3, TTK do Guardião.
- Largura 6800 px acima da referência do briefing.
- Lava do poço é não letal (20/0,6 s) mas cair no fundo é "queda sem retorno":
  o CP trata.
- Guardião a confirmar.
