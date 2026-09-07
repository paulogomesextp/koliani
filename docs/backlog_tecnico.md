# Backlog técnico — Koliani

Este ficheiro regista dívida e riscos conhecidos. Não autoriza implementação;
a ordem executável vive em [../PRIORIDADES.md](../PRIORIDADES.md).

| Item | Risco / resultado necessário | Estado |
|---|---|---|
| Generator overwrite risk | Manifesto identifica origem/ownership; geradores de cena e atmosfera escrevem em staging e só promovem `generated/generated` explicitamente autorizado. Os 31–100 atuais são `unknown` e protegidos. | RESOLVED — Execution 2 |
| Save versioning/migrations | Schema v4 explícito; legacy v0 migra sequencialmente por v1/v2/v3; validação antes/depois; TEMP verificado, backup e recovery cobertos por testes. | RESOLVED — Executions 3A/3B/3C |
| Stable progression IDs | Níveis/regiões vêm do manifesto; schema v3 persiste nível atual/conclusões, bosses, abilities, pistas e rewards por IDs estáveis validados. Checkpoint/session fica para 3C. | RESOLVED — Execution 3B |
| Level Session / checkpoint state | Schema v4 separa `level_session` da campanha; persiste level/checkpoint IDs, resolve posição só em runtime e faz fallback `_start` seguro. Alterar a topologia/ordem de checkpoints exige migration explícita dos IDs. | RESOLVED — Execution 3C |
| Reward identity persistence | Cada baú de boss usa `reward_boss_chest_<level_id>` e o claim persistido impede nova atribuição após reload/replay. | RESOLVED — Execution 3B |
| Safe areas | UI mobile não tem prova canónica de respeito por notch, barras e proporções extremas. | DEVICE VALIDATION REQUIRED |
| Android version mismatch | A versão do preset Android diverge da versão do projeto. Alinhar numa execução autorizada e validar o artefacto. | OPEN |
| Device validation Level 12 iPhone | Reproduzir o nível 12 pelo Safari/PWA num iPhone real, incluindo entrada, morte, respawn e reload. | DEVICE VALIDATION REQUIRED |
| Movement + Camera 4A/4B feel | Parâmetros 4A/4B aceites pelo utilizador; a Execution 3C não os alterou. | HUMAN-APPROVED |

## Regras de tratamento

- Um item `OPEN` não é uma falha confirmada além do risco descrito.
- `RESOLVED` exige que a proteção continue coberta pelos validators da
  execução respetiva; mudar ownership é uma alteração deliberada ao manifesto.
- `DEVICE VALIDATION REQUIRED` não pode ser convertido em PASS por desktop,
  emulação, análise estática ou captura OpenGL.
- Não misturar correções destes itens com outra execução sem alterar primeiro
  o plano e obter a decisão necessária.
