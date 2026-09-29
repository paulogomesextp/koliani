# Decisões do Game Director — Anexo B (estado a 25 set 2026)

Fonte: `docs/auditoria_global_game_director.md` §10.5 (13 decisões). Fechadas 6 (4 na Fase 0 + #5 e #12 a 25 set); restam **7**
que exigem o Game Master. Nenhuma decisão narrativa/artística foi tomada pelo agente.

## RESOLVIDAS

| # | Decisão | Resolução (GM, Fase 0) | Implementação |
|---|---|---|---|
| 2 | Chefes: 20 regionais vs 85 | **20 bosses regionais**, 1 por região. Os restantes não são automaticamente canon: podem ser removidos, virar elite/mini-boss ou ser reaproveitados **só se servirem o design regional** | Migração NÃO feita agora (congelada) |
| 3 | N30 / Zeriko | Zeriko **não** é derrotado definitivamente no N30; o conteúdo atual é **legacy**. N30 pode virar encontro/manifestação/confrontação parcial/foreshadowing/avatar subordinado; a resolução pertence ao arco final | NÃO implementado |
| 6 | Guardiões N1–N4 | Na R-I o **Ghorak** é encontro/mini-boss (elite de sala no N1, recomendação em `vertical_slice_region01.md` §3) e o boss da região é só o do N5. Generalização a outras regiões decide-se após o slice | No slice |
| 5 | Nome da Região I | **Floresta Corrompida**; boss regional mantém-se **Coração Putrefacto** (GM, 25 set 2026) | A propagar no i18n/canon ao produzir o slice |
| 12 | Calendário de verbos | **Opção A**: N1 movimento base+salto+ataque básico+leitura de hazards · N2 Dash · N3 Pogo/ataque descendente · N4 Especial com custo de Energia (combate+dash+pogo) · N5 exame de tudo. **Wall-kick fora da R-I** (região posterior) (GM, 25 set 2026) | Por implementar (F2 desenha o custo do especial) |
| 7 | Música | Stock = **placeholder** durante o desenvolvimento, não autoridade. Direção final = canon aprovado: dark, gótico, mais peso/tensão, instrumentação orgânica/orquestral/coral/acústica; evitar dungeon synth/soft | Nada substituído agora |

Também fechado (estrutura): **20 regiões × 5 níveis = 100**, mas a jornada procedural quase igual deixa de
ser aceitável como conteúdo principal; alvo = pipeline regional intencional. Vertical slice = Região I
(N1, Ghorak, N5 Coração Putrefacto). Fora isso: `FROZEN PENDING VERTICAL SLICE` (ver `foundation_plan.md`).

## AINDA PENDENTES (7)

### 1. Tabela única região → tema → mecânica → chefe
- **Contexto**: o jogo segue a tabela de 3 set (`REGIOES`, `world.*`); o canon de 15 set
  (`KOLIANI_REGION_CANON.md`) nunca chegou às cenas. A decisão nº 2 implica um chefe por região mas não
  diz qual tabela manda.
- **A**: canon de 15 set. **B**: manter a tabela de 3 set em jogo.
- **Consequências**: A obriga a migrar dados/i18n/nomes antes de qualquer conteúdo IV–XX (custo alto, mas
  só se faz uma vez); B mantém o jogo estável mas o trabalho aprovado das 20 pranchas não tem destino.
- **Recomendação técnica**: A (só para a Região I no slice; migrar as restantes antes da fase CONTENT).
- **Necessário**: escolher a tabela autoritativa.

### 4. Nome da mãe (Aurora vs Elara)
- **Contexto**: jogo/pistas/CLAUDE.md/historia usam Aurora; a visão 1.0 usa Elara.
- **A**: Aurora. **B**: Elara.
- **Consequências**: uma passagem única em i18n (6 línguas) + pistas; adiar deixa dois nomes no jogo.
- **Recomendação**: fechar antes de mexer em intro/diálogos do slice; a escolha em si é narrativa.
- **Necessário**: o nome canónico.

### 8. "Música claramente à frente" (`SFX_MIX_DB −6`)
- **Contexto**: hoje o feedback de jogo (hit/dano/telégrafo) fica 5–24 dB abaixo da música.
- **A**: manter global. **B**: música à frente só do decorativo; feedback ao nível da música.
- **Consequências**: A mantém a sensação atual e o combate sem peso no telemóvel; B muda a mistura
  inteira e exige re-medir (SMR ≥ 0 dB é critério do slice).
- **Recomendação**: B.
- **Necessário**: confirmar a intenção de mistura.

### 9. Âmbito da 1.0
- **Contexto**: 100 níveis à barra do slice é custo enorme.
- **A**: 100 níveis à barra. **B**: campanha menor à barra. **C**: 100 com parte procedural assumida.
- **Consequências**: define o roadmap e a fase CONTENT.
- **Recomendação**: decidir **depois** da Validação, com o custo por região medido.
- **Necessário**: adiar conscientemente (ou decidir já).

### 10. Vidas
- **Contexto**: vidas até 99 e fogueira como checkpoint coexistem sem contrato claro.
- **A**: manter. **B**: ecrã explícito. **C**: remover (fogueira = contrato).
- **Consequências**: mexe em HUD, save e dificuldade/retry do slice (retry ≤ 0,5 s).
- **Recomendação**: C.
- **Necessário**: escolher.

### 11. Moedas
- **Contexto**: Essência + Kolicoins + Veracoins.
- **A**: manter 3. **B**: 1 moeda de jogo, Veracoins escondidas até haver pagamento e conteúdo.
- **Consequências**: simplifica economia/UI; toca na loja já construída.
- **Recomendação**: B.
- **Necessário**: escolher.

### 13. Koliani Sombria (N27) e outros chefes legados com valor narrativo
- **Contexto**: dependente de #1 (tabela única) e do destino dos bosses não regionais.
- **A**: cortar. **B**: reaproveitar como elites/momentos de história.
- **Consequências**: narrativo; não bloqueia o slice.
- **Recomendação**: avaliar caso a caso após #1.
- **Necessário**: decisão caso a caso.

## Bloqueiam o slice?
Desde 25 set 2026 (#5 e #12 fechadas) **nenhuma** decisão pendente bloqueia F1–F4 nem o N1/N5.
