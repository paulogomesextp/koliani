# Regiao II (Desfiladeiro dos Ventos) -- decisoes do GM + auditoria do N6

Estado (26 set 2026, sem push): **AUDITORIA + PLANO DO N6. Nada de N6-N10 foi alterado.**
Substitui, onde diferir, `docs/plano_migracao_regiao_2.md` (que tratava os nomes legacy como base).

## Decisoes fechadas (GM)
1. **Ordem**: N6 -> N7 -> N8 -> N9 -> N10, um nivel de cada vez, com playtest/aprovacao do GM antes de avancar. Nao comecar pelo N10.
2. **CANON**: a Regiao II e' **DESFILADEIRO DOS VENTOS** (`docs/art_direction/KOLIANI_REGION_CANON.md`, `regions/region_02/*`,
   `level_mechanics_and_layout.png`, `GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md`). Prisao/Fornalha/Corredor/Ala dos Mortos/Cela Zero sao
   **legacy**: fornecem codigo/sistemas reutilizaveis, nao autoridade artistica nem de level design. O N10 authored existente
   NAO e' baseline de design se estiver preso a conteudo legacy.
3. **Recompensa do N10**: o boss regional (Guardiao dos Ceus) concede `escalar_paredes` (wall-jump). NAO e' ensinada nem exigida na Regiao II;
   entra no kit a partir da Regiao III; gating ja' existente `EstadoJogo.tem_habilidade("escalar_paredes")`. Nada de wall-jump antes da vitoria do N10.
4. **Cartao de fim da Regiao II**: aprovado, MESMO `cartao_regiao.gd`. Fluxo: boss N10 -> recompensa -> `ESCALAR PAREDES DESBLOQUEADO` ->
   cartao `DESFILADEIRO DOS VENTOS CONCLUIDO` -> Continuar -> saida/Regiao III. Implementacao = 2 linhas de dados em `nivel_com_chefe.gd`
   (`HABILIDADE_DO_CHEFE[9] = "escalar_paredes"`, `REGIAO_CONCLUIDA[9] = "region.2.complete"`) + chave `region.2.complete` nos 6 i18n.
   **Fica para a execucao do N10** (nao foi feito agora, por instrucao).

## Validacao do commit 81e36971 (feita antes da auditoria)
- Suite completa ate' ao fim: `OK -- todos os testes passaram`, exit 0, `save real intacto (3 ficheiros verificados)`.
- Fluxo real do N5 automatizado em `teste_fluxo_fim_regiao1`: porta selada -> boss derrotado -> salto duplo desbloqueado -> bau -> cartao
  -> porta selada enquanto o cartao esta' aberto -> Continuar abre a porta. Passou; sem regressao, nada corrigido.

## ACHADOS TRANSVERSAIS (nao mexidos -- para as execucoes respectivas)
- **`Fornalha_dos_Pecadores.tscn` (N7) tem um `Coletavel` `escalar_paredes`** (l.267) e **`Torre_dos_Sinos.tscn` (N11) tambem** (l.200).
  Viola a decisao 3 (wall-jump so' apos o N10). Retirar o do N7 na execucao do N7; o do N11 deixa de fazer sentido (o jogador ja' o tem).
- O N6 tem um `Coletavel` **`dash_aereo`** (`ColDash`): confirmar com o GM se e' o sitio certo (o Dash vem do N2).
- `EstadoJogo.REGIOES` "desfiladeiro" usa `niveis [5..9]` (indices) -- coerente com N6-N10.

## AUDITORIA DO N6 -- `scenes/levels/Prisao_dos_Condenados.tscn` (indice 5; nome legivel `level.n05` = "The Open Cliffs")
Canon do N6: **rajadas horizontais** ("As Falesias Abertas": foco rajadas + precisao; vento de impulso, plataformas moveis; desafio atravessar
zonas de vento intenso; segredo: areas laterais protegidas do vento; "a primeira coisa que se ve e' que o chao acabou").

### O que ja' esta' no canon (herdado das remodelacoes visuais, ja' em master)
Atmosfera `desfiladeiro` (pack, tinta, neblina, perfil `n06`), Casca de pedra `desfiladeiro`, mar de nuvens no lugar do acido, 2 `WindZone`
(rajada a favor pulsada na entrada; contra a marcha pulsada na bifurcacao), inimigos ja' trocados (golem aereo elite, morcego dos ventos),
`usar_golden_set`. Reutilizavel: `wind_zone.gd` (CONTINUO/PULSADO, direcao, intensidade, guia visual, laco `vento_ciclo`), `corrente_lateral.gd`.

### Desvios face ao quality bar da Regiao I e ao canon
| # | Achado | Gravidade | Accao na reconstrucao |
|---|---|---|---|
| 1 | `corredor` = true (default): **jornada procedural prepende a sala**. Viola "zero jornada". | ALTA | `corredor = false`, `checkpoints_autorais`, `estreia_x_autoral` |
| 2 | So' 3 checkpoints de sala e nenhuma intencao Teach->Boss; sala de ~3,3 k px | ALTA | 5 seccoes (abaixo) com checkpoint antes de cada prova |
| 3 | Tem um **`Chefe` persistente (Carcereiro)** -- N6 nao e' exame regional; marcaria boss derrotado e daria bau de chefe | ALTA | trocar por `Guardiao` (elite que sela a porta, como N1-N4): Golem das Falesias |
| 4 | **`FogoMeio` / `FogoChefe`** (fogo de prisao) e no `AcidoFundo` (nome legacy) | MEDIA | remover fogos; o vazio e' so' o mar de nuvens |
| 5 | Ventos **so' PULSADOS e sem ensino**: a rajada de entrada cai sobre plataformas moveis; nao ha' fase "ler o vento em seguranca" | ALTA | Teach com vento CONTINUO fraco sobre chao firme; so' depois pulsado sobre vazio |
| 6 | 3 `PlataformaCorrente` (pendulo/vertical/horizontal) somam-se ao vento: **dois movimentos externos ao mesmo tempo** | MEDIA | vento sobre plataformas estaticas; moveis so' fora da zona de vento (Combine) |
| 7 | `ColDash` = habilidade `dash_aereo` no meio da sala | MEDIA | decisao do GM; por omissao sai do N6 |
| 8 | Sem "area lateral protegida do vento" (segredo canonico) | BAIXA | ninho lateral abrigado com cache de Essencia |
| 9 | O morcego nao usa o vento como funcao | BAIXA | so' sobre o vazio, para forcar leitura do vento |
| 10 | Nao existe `teste_n6_autoral`; `verifica_alcance` cobre a sala antiga | MEDIA | teste do N6 (alcance com piloto, so' com o kit real) |
| 11 | Arte: golem/morcego/props ja' sao do pack; dividas ficam registadas | -- | nao bloqueia |

### Kit do jogador ao entrar no N6
Dash (N2), Pogo (N3), Especial (N4), **Salto duplo (N5)**; **sem** wall-jump. O N6 pode exigir salto duplo, mas NUNCA parede.

### Reconstrucao proposta (a validar pelo GM antes de mexer) -- "As Falesias Abertas"
Aqui a geometria funcional muda por razoes de level design (jornada, ensino), por isso o baseline `tools/baseline_geometria.gd` e' refeito para o N6 no fim.
| Secao | Funcao | Conteudo | Checkpoint |
|---|---|---|---|
| A. Teach (0-900) | ler o vento sem risco | chao largo, rajada CONTINUA a favor e depois contra, sem vazio; guia visual; nada mata | inicio |
| B. Develop (900-1800) | vento e salto | pontes estreitas sobre o vazio; rajada pulsada com aviso; saltar a favor/contra; salto duplo corrige a deriva | apos a 1.a ponte |
| C. Combine (1800-2700) | vento + combate | golem aereo (elite) e morcegos sobre o vazio; bifurcacao alta (mais vento, cache) / baixa (abrigada, mais inimigos); pogo em morcego cancela deriva | reencontro |
| D. Challenge (2700-3400) | prova final | ponte longa com rajada alternada e uma unica plataforma movel; dash atravessa a rajada | antes do guardiao |
| E. Guardiao (3400-4000) | fecho | Golem das Falesias (elite, `Guardiao`) sela a porta; arena de chao continuo, uma zona de vento fraca | dentro da arena |
Alvo de duracao 3-4 min. **Sem boss regional, sem recompensa de habilidade** (a habilidade vem so' no N10).

### Proximo passo (com o GM)
1. Aprovar esta tabela (sobretudo #3 guardiao, #7 dash_aereo).
2. Implementar como N1-N5: cena editada, `corredor=false`, `checkpoints_autorais`, `teste_n6_autoral` + bot, capturas em `docs/qa/n6_autoral/`,
   doc `docs/nivel_autoral_n6.md`.
3. Playtest do GM; so' entao N7.
