# Remoção do semicírculo legado — 1 outubro 2026

Paulo identificou o semicírculo rosa e pediu removê-lo do jogo para todos os modelos e skins; restante visual aprovado nesta avaliação.

Causa: a classe interna `AssinaturaLamina` em `scripts/region1_hybrid_visual_target.gd` desenhava três arcos e uma luz diretamente à frente da personagem. A fábrica `_ligar_shadowblade` criava `HybridShadowbladeSignature` em qualquer Koliani no perfil 1, sem verificar a skin ou o modelo. Era uma camada extra sobre os VFX atuais da espada.

Foram eliminados a classe, a fábrica e a chamada diferida: 75 linhas removidas, sem outras alterações nesse ficheiro. Não foram alteradas geometria, sprites, aura premium, VFX atuais, animações, tempos, hitboxes ou gameplay. Já não há referências a esses nomes em scripts/cenas ativos; a remoção vale para todos os modelos.

Evidência:

- Renderer real 1280×720 no nível Floresta Putrefata: antes `no=true; arco atual=true`; depois `no=false; arco atual=true`. Capturas em docs/qa/arco_legado/antes.png e depois.png. Sem SCRIPT ERROR/ERROR; aviso Camera2D e 111 ObjectDB ao encerrar.
- Ataques em nove skins e três rigs anteriores no mesmo nível: 12 perfis passaram, região ativa e nó antigo ausente. Logs work/qa_sem_arco_modelos*.log. O arnés headless de ciclos acusa recursos ao encerrar (3 inicialmente, 2 após limpar caches); limitação registada, sem ocultar como PASS sem erros. Não foi alterado o runtime para resolver esse aviso.
- Dados reais isolados por tools/godot_isolado.py; três saves verificados intactos em todas as execuções.

Lote local em master, sem push/publicação. Windows principal e Web local serão exportados do mesmo commit, com backup anterior e smoke antes de concluir. Dispositivo continua DEVICE VALIDATION REQUIRED.
