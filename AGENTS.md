# AGENTS.md — Koliani

Koliani é um platformer mobile-first em Godot 4.7.2/GDScript, landscape,
60 fps, com export Web preservado. A fonte de verdade documental começa em
`docs/retomar_aqui.md`.

## Cânone e scope

- Campanha: 100 níveis em 20 regiões de 5 níveis.
- Koliani tem 16 anos; Elara é o nome canónico da mãe.
- Shadowblade é a arma principal.
- Hardcore está fora do scope 1.0.
- A Região I, níveis 1–5, é a primeira Vertical Slice.

Não contrariar `docs/visao_koliani_1_0.md` nem decisões aceites em
`docs/decisoes.md`. Divergências existentes no jogo são backlog, não licença
para mudanças oportunistas.

## Método de trabalho

Antes de alterar ficheiros, declarar objetivo, âmbito e critério de conclusão.
Usar `docs/plano_atual.md` para trabalho amplo. Consultar apenas a documentação
necessária, começando pelo topo de `docs/retomar_aqui.md`.

- **No opportunistic work:** não corrigir, limpar, refatorar ou expandir fora
  do âmbito pedido, mesmo que pareça simples.
- **No speculative completeness:** não declarar sistema, plataforma, nível ou
  execução completos sem evidência correspondente.
- **Investigation budget:** começar por leituras dirigidas e até três hipóteses
  verificáveis. Se não houver evidência nova após três ciclos de investigação,
  parar, registar o que falta e pedir decisão em vez de alargar o âmbito.
- **Failure budget:** depois de três falhas consecutivas com a mesma causa,
  parar as repetições. Preservar logs, classificar o bloqueio e escalar.
- **Human playtest stop:** quando a conclusão depender de sensação, diversão,
  legibilidade subjetiva ou percurso humano, marcar `HUMAN PLAYTEST REQUIRED`
  e não declarar PASS final desse ponto.
- **Device validation stop:** quando depender de hardware/browser real, marcar
  `DEVICE VALIDATION REQUIRED`; desktop, emulação ou captura não substituem o
  dispositivo.
- **Design decision stop:** se opções alterarem cânone, scope, economia,
  progressão ou experiência, apresentar alternativas e parar antes de editar.
- **Execution stop:** respeitar a fronteira entre execuções; não começar a
  seguinte para “adiantar” trabalho.
- **Context efficiency:** usar `rg`, leituras pequenas e evidência já válida;
  não reler históricos extensos nem repetir testes sem mudança relevante.

## Projeto e alterações

- Código, comentários e logs em português. Texto visível usa `Textos.t()` e
  os seis catálogos em `assets/i18n/`; `en.json` é a base.
- Preservar trabalho alheio e alterações locais não relacionadas.
- Nunca alterar configuração/remotes Git nem usar `git add -A`.
- Arte é gótica pixel-art de luar, magenta/roxo; assets têm de ser CC0/grátis
  e creditados. Nunca comprar sem autorização.
- Alterar fontes/geradores, não PNGs gerados. O risco de sobrescrita dos níveis
  31–100 está registado em `docs/backlog_tecnico.md`.

## Validação e paragens

Validar proporcionalmente ao diff e ler erros/logs, não apenas exit codes.
Alterações de níveis exigem `.agents/skills/koliani-validar-niveis/SKILL.md`.
Capturas exigem renderer real; alcance estático não prova jogabilidade.

Não contornar validações bloqueadas, reduzir o âmbito em silêncio nem publicar
trabalho incompleto. Um commit só pode abranger um lote concluído e validado.
Commits do agente terminam com:
`Co-Authored-By: Codex Sonnet 5 <noreply@anthropic.com>`.

Na primeira interação do dia, executar `git fetch origin master` e resumir
`git log origin/master --since="1 day ago"` antes de avançar. No fim, atualizar
a retoma com factos e próximo passo e indicar usage disponível; se estiver
indisponível, dizê-lo sem reutilizar números antigos.

## Entregas Windows e PWA — decisão do GM

- Cada alteração destinada a entrega exige atualizar Windows e Web/PWA no mesmo lote, a partir do mesmo commit e da mesma versão em project.godot.
- Exportar e validar ambos; publicar a PWA e disponibilizar o Windows correspondente. Não concluir uma entrega só numa plataforma.
- Um candidato local incompleto não é uma entrega. Se um build ou publicação falhar, reportar a divergência e o bloqueio; não declarar paridade apenas pelo número de versão.
- Preservar userdata/saves em ambas as plataformas. Validação no telemóvel mantém DEVICE VALIDATION REQUIRED até evidência no dispositivo.
