# Shadowblade e Featured em master — 1 outubro 2026

Pedido do Paulo: colocar a Shadowblade e a loja em master e terminar com Windows jogável. Integração seletiva sobre b31821b8; não inclui níveis nem remoção de equipamento do ramo de origem. Os documentos locais anteriores foram preservados.

## Conteúdo integrado

- Shadowblade: 84 frames com poses/pés preservados, acessórios, aura independente, iluminação própria e VFX separados. Fontes e geradores acompanham os derivados.
- Posicionamento visual de ataque após a espada; nenhuma mudança nos contratos de gameplay.
- Loja: adquirir/equipar Shadowblade, sprite no detalhe e splash no Featured. Cinco splashes existentes, um destaque de cada vez, troca após 5 segundos com fade de 0,3 segundos na saída/entrada. Rotação não muda o alvo da compra; Ver seleciona o anúncio apresentado.
- Só chaves i18n Shadowblade adicionadas aos seis catálogos. Preços e modo grátis de desenvolvimento preservados.

## Evidência no checkout master

- Importação final sem SCRIPT ERROR/ERROR; o primeiro ciclo detetou classes duplicadas dentro do backup, corrigido com .gdignore nesse backup.
- Fidelidade estrutural: 84 frames, zero falhas.
- QA carrossel: timer real, fade, ciclo das cinco artes, Ver, detalhe preservado, seleção manual, tabs e fecho passaram.
- QA loja: 1280/1920, adquirir/equipar/save/fallback passaram. Carrossel/loja registam 111/112 ObjectDB e um recurso ativo ao encerrar o arnés. Limitação registada, não apresentada como execução sem erros.
- QA VFX: 150 casos, nove skins, quatro golpes, dois sentidos e gravidades, mais três modelos anteriores; sem ERROR, aviso ObjectDB ao encerrar.
- QA jogo com renderer Vulkan real: idle/run/attack/dash/roll nos dois sentidos, VFX vivos observados. Recorte do arnés corrigido para converter RGB8 em RGBA8; repetição sem ERROR. Capturas em work/shadowblade_fidelity/master_ingame. Aviso Camera2D/ObjectDB permanece.
- Cada execução Godot verificou três ficheiros de save real intactos. Não foi declarada suite geral nem medição de performance.

Backup das fontes anteriores: work/integracao_shadowblade_backup_20261001 (ignorado pelo editor). Build Windows/Web será exportada deste mesmo master local/version 0.18.20 e o arranque final verificado antes da conclusão. Sem push ou publicação online.

HUMAN PLAYTEST REQUIRED para qualidade percebida; DEVICE VALIDATION REQUIRED para telemóvel. Outras skins conceptuais aguardam identificação do Paulo devido às decisões anteriores de descarte.
