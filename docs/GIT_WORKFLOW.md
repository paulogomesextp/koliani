# KOLIANI — SHARED GIT WORKFLOW

## Source of truth

GitHub é a fonte partilhada oficial do projeto.

Cada colaborador trabalha numa cópia local independente.

Não usar OneDrive/Google Drive como diretório ativo do repositório.

## Base branch de integração

codex/region-canon-integration

Esta branch contém o canon regional e as auditorias aprovadas.

## Regra por processo

Cada novo processo deve:

1. começar numa NOVA conversa Codex/Claude;
2. atualizar referências remotas com `git fetch`;
3. confirmar a base correta;
4. criar ou usar uma branch dedicada à tarefa;
5. alterar apenas o scope autorizado;
6. testar;
7. criar um commit dedicado se o processo passar;
8. fazer push dessa branch para `origin`;
9. confirmar que local HEAD = remote HEAD;
10. reportar branch + commit + testes ao ChatGPT.

## Nunca fazer automaticamente

- commit direto em master;
- merge em master;
- force push;
- reset destrutivo;
- rebase de trabalho alheio;
- apagar branches remotas;
- incluir alterações não relacionadas.

## Branches

Usar nomes descritivos, por exemplo:

codex/region02-wind-system
codex/region02-level06
codex/region03-migration

Outro colaborador pode usar:

claude/region02-wind-system

## Regra de publicação

PROCESS PASS:
commit + push obrigatório.

PROCESS PARTIAL:
commit/push apenas se o estado estiver estável e explicitamente
documentado.

PROCESS FAIL/BLOCKED:
não publicar alterações incompletas salvo instrução explícita.

## Handoff

Todo relatório deve incluir:

BRANCH
LOCAL HEAD
REMOTE HEAD
HEADS MATCH
TESTS
REGRESSIONS
NEXT ACTION
