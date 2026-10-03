# Decisões canónicas — Koliani

Este registo prevalece sobre notas históricas quando houver conflito. Alterar
uma decisão requer pedido explícito e atualização coordenada da visão,
prioridades e dashboard.

| ID | Decisão | Estado |
|---|---|---|
| DEC-001 | A campanha contém 100 níveis. | ACEITE |
| DEC-002 | A campanha organiza-se em 20 regiões de 5 níveis. | ACEITE |
| DEC-003 | Koliani tem 16 anos. | ACEITE |
| DEC-004 | Elara é o nome canónico da mãe de Koliani. | ACEITE |
| DEC-005 | Shadowblade é a arma principal. | ACEITE |
| DEC-006 | Hardcore fica fora do scope 1.0. | ACEITE |
| DEC-007 | A Região I, níveis 1–5, é a primeira Vertical Slice. | ACEITE |
| DEC-008 | Validação desktop não fecha problemas específicos de dispositivo. | ACEITE |
| DEC-009 | A Execution 2 não começa durante a Execution 1C. | ACEITE |
| DEC-010 | Paulo aprovou as 20 artes dedicadas do pacote `KOLIANI_LevelSelector_RegionBackgrounds_01-20.zip` para os backgrounds do Level Selector das regiões 1–20 (commit fonte `52ea3394`, 22 set 2026). | ACEITE |
| DEC-011 | Nomes visíveis canónicos: Região I = "Floresta Sagrada"; boss N5 = "Guardião Verde" (ids internos não mudam). Paulo, 3 out 2026. | ACEITE |
| DEC-012 | Guardiões só no 2.º e 4.º nível de cada região + boss no 5.º; o 1.º e o 3.º acabam em desafio de travessia/encontro. Paulo, 3 out 2026. | ACEITE |
| DEC-013 | 1–2 zonas por nível fecham a passagem até limpar (mec.arena), incluindo a Região IV. Paulo, 3 out 2026. | ACEITE |
| DEC-014 | N11 refeito de raiz agora, como nível autoral (pipeline N12–N14). Âmbito do plano de melhoria: N1–N20 (`PROMPT_CHATGPT_PLANO_N1_N20.md`). Paulo, 3 out 2026. | ACEITE |

## Consequências atuais

- “Aurora” em conteúdo existente é uma divergência legada a migrar de forma
  controlada; não muda o nome canónico Elara.
- Remover/ocultar Hardcore exige tratamento seguro do estado persistido e não
  deve ser feito oportunisticamente.
- A Vertical Slice prova apenas a Região I; não autoriza afirmar que a campanha
  completa tem o mesmo grau de acabamento.
- O nível 12 continua `DEVICE VALIDATION REQUIRED` no iPhone Safari/PWA.
