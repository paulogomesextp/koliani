# VFX após a espada, Shadowblade na loja e splash — 1 outubro 2026

Estado: implementação e QA dirigido concluídos como candidato local. **HUMAN PLAYTEST REQUIRED** para a leitura dos golpes e qualidade premium; **DEVICE VALIDATION REQUIRED** para mobile/PWA. Sem publicação online, push ou declaração de produto pronto para compra real.

## Alterações

- `VfxPosicionamento`: limites visíveis das texturas em cache; união dos frames da animação de ataque e transformação completa do arco (escala, offset, giro, sentido). A margem frontal do efeito começa dois pixels depois da extremidade visual da espada/traje. Aplica ao arco Golden, Shadowblade e combos Vfx9G, em ambos os sentidos e gravidades. Luz de golpe deslocada para a frente nos modelos anteriores. Efeitos já desenhados nos frames de rigs antigos permanecem na arte original; não foram editados PNGs do corpo para os remover.
- Shadowblade conserva os seus efeitos próprios; Golden e outras skins mantêm os efeitos existentes com posição corrigida. Dano, hitboxes, duração, inputs, animações e deslocamento físico não mudaram.
- Loja abre com Shadowblade em destaque; usa o novo splash no Hero e conserva a prévia do sprite real no cartão/detalhe. Novo campo opcional `splash`, com fallback para a prévia dos outros itens. ID, preço de catálogo 500 V, regras, ownership, equip e modo grátis de desenvolvimento preservados.
- Splash novo: `assets/sprites/koliani_skins/shadowblade/apresentacao/splash_premium.png`, 1536×1024, gerado pela ferramenta imagegen integrada a partir da skin. O antigo recorte de referência foi preservado. Prompt/proveniência/crédito em `docs/shadowblade_splash_prompt.md`.

## Evidência

- `qa_vfx_espada.gd`: 150 casos, nove skins, quatro golpes, dois sentidos, duas gravidades; três modelos anteriores com luz reposicionada. Capturas reais dos dois sentidos em `work/shadowblade_fidelity/espada_*.png`.
- `qa_shadowblade_loja.gd`: splash e sprite corretos a 1280×720 e 1920×1080, adquirir/equipar e round-trip de save passaram. O arnés específico regista 113 ObjectDB e um recurso ativo ao encerrar; não foi tratado como log limpo. O teste geral `qa_shop_layout.tscn` passou com zero falhas, 110 ObjectDB ao encerrar e sem ERROR.
- Paridade Godot Shadowblade: zero falhas. Fidelidade estrutural: 84 frames, zero falhas. Auditoria: 7.927 hashes, 34 alterações visuais autorizadas, zero inesperadas. Prova por subtração dos trechos exatos garante que Koliani ficou idêntica fora das chamadas visuais autorizadas; catálogo idêntico fora do campo splash.
- Windows e Web exportados da mesma árvore de fontes/version 0.18.20; smoke do Windows exportado terminou sem erro. Três ficheiros de save real intactos. Logs e hashes em `work/shadowblade_fidelity/`; manifesto `builds_manifesto.json`.

## Builds e retoma

A base real deste worktree é **a3b059dc**, não c4aa1a39: o SHA indicado nas notas anteriores estava errado e foi corrigido nesta passagem. Branch `codex/shadowblade-fidelity`, alterações locais sem commit.

O checkout `C:\Projetos\koliani-master` está em b31821b8, anterior à inclusão da Shadowblade. A tentativa de aplicar o lote recusou essa divergência antes de alterar fontes. A exportação iniciada prematuramente foi interrompida e o executável anterior restaurado antes da nova exportação. As fontes desse checkout foram preservadas; não se apresenta como sincronizado com o worktree.

Executável de teste atualizado em `C:\Projetos\koliani-master\build\windows\Koliani.exe`, cópia por SHA256 idêntica ao candidato validado. Backup anterior em `build\windows\backups\shadowblade_antes_20261001\Koliani.exe`. Web local atualizado em `C:\Projetos\koliani-master\build\web`, com versão anterior guardada em `work\shadowblade_web_antes_20261001`. Ambos são candidatos locais da árvore a3b059dc com este diff; ainda não há commit comum de entrega nem publicação PWA. Não confundir o HEAD antigo do checkout principal com a origem dos binários.

Próximo: playtest humano dos arcos à esquerda/direita e da skin pela loja; validação no dispositivo. Concluir commit local validado e sincronização de fontes antes de uma entrega publicada. Combat V2.1 continua pendente no checkout original.
