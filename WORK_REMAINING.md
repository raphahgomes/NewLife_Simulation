# NewLife Simulation — Documento de Trabalho Restante
**Última Atualização:** Sessão atual | **Commit:** `1b39d6e`

---

## ✅ CONCLUÍDO

### Código / Sistemas
- [x] 13 features/bugs originais do jogo
- [x] 140 eventos expandidos (baby:20, child:25, teen:28, adult:45, elder:22)
- [x] Localização completa EN + PT_BR (828+ chaves em texts.csv)
- [x] AudioManager autoload (música por fase, SFX, crossfade, volume persistente)
- [x] SaveManager com persistência de settings (save_setting/load_setting)
- [x] PauseMenu completo (ESC, save, settings, stats, main menu, quit)
- [x] Sistema de Achievements (25 conquistas + AchievementManager + toast no HUD)
- [x] SceneTransition autoload (fade 0.3s em todas as telas)
- [x] Animações de barras de stats (tween 0.4s) + EventPopup fade in/out
- [x] Sistema de Statistics (Character dict + counters no GameManager + tela Statistics)
- [x] 8 autoloads registrados no project.godot
- [x] Git push para GitHub (main branch)

### Ferramentas de IA
- [x] Python 3.12.6 + PyTorch 2.11.0 CUDA + diffusers 0.37.1 + transformers 5.5.4
- [x] Script `C:\IA\generate_assets.py` (Stable Diffusion 2.1 + MusicGen via transformers)
- [x] Prompts para 15 imagens + 11 áudios definidos

---

## 🔴 FASE 1 — Assets de Áudio (PRÓXIMA)
**Estimativa de esforço:** Executar script + ajuste manual

| Tarefa | Detalhes |
|--------|----------|
| ⬜ Rodar geração de música | `python C:\IA\generate_assets.py music` — gera 7 músicas + 4 SFX |
| ⬜ Copiar para o jogo | `python C:\IA\generate_assets.py copy` — copia WAVs para `assets/sounds/` |
| ⬜ Testar no Godot | Abrir projeto, verificar se AudioManager toca as músicas por fase |
| ⬜ Ajustar qualidade | Re-gerar com prompts diferentes se necessário |
| ⬜ Loop seamless | Editar pontos de loop nos WAVs (Audacity ou similar) |

**Arquivos esperados em `assets/sounds/`:**
```
music_baby.wav, music_child.wav, music_teen.wav, music_adult.wav, 
music_elder.wav, music_menu.wav, music_death.wav,
sfx_click.wav, sfx_event.wav, sfx_achievement.wav, sfx_year_advance.wav
```

---

## 🟡 FASE 2 — Assets Visuais (Ícones + Backgrounds)
**Estimativa de esforço:** Executar script + curadoria + redimensionamento

| Tarefa | Detalhes |
|--------|----------|
| ⬜ Rodar geração de imagens | `python C:\IA\generate_assets.py images` — gera 15 imagens |
| ⬜ Copiar para o jogo | `copy` move para `assets/icons/generated/` e `assets/ui/backgrounds/` |
| ⬜ Integrar backgrounds | Usar bg_main_menu.png no MainMenu.tscn, bg_game_over no LifeSummary |
| ⬜ Integrar ícones de fase | Mostrar icon_baby/child/teen/adult/elder no GameHUD |
| ⬜ Integrar ícones de categoria | Mostrar icon_health/career/crime/romance/finance no EventPopup |
| ⬜ App icon (icon.svg) | Gerar ou criar icon profissional para o jogo |
| ⬜ Splash screen | Imagem de loading ao abrir o jogo |

**Ícones faltando definir prompts:**
- Ícone de achievement (troféu/medalha)
- Ícone de estatísticas
- Ícone de save/load
- Avatares de personagem (opcional — pode usar silhuetas)

---

## 🟡 FASE 3 — UI/UX Polish
**Estimativa de esforço:** Médio

| Tarefa | Detalhes |
|--------|----------|
| ⬜ Theme atualizado | Integrar backgrounds gerados, melhorar tipografia |
| ⬜ Tutorial / Onboarding | Tela de tutorial para primeira jogada |
| ⬜ Tela de Achievements | Lista visual de conquistas desbloqueadas/trancadas |
| ⬜ Relacionamentos na UI | Painel expandido mostrando todos os relacionamentos |
| ⬜ Carreira na UI | Painel de carreira com nível, salário, opções (pedir demissão, etc.) |
| ⬜ Inventário / Propriedades | Casas, carros, itens comprados |
| ⬜ Barras coloridas por valor | Verde (bom) → Vermelho (ruim) gradient nas stat bars |
| ⬜ Animação de passagem de ano | Efeito visual ao avançar ano (contador subindo, etc.) |
| ⬜ Notificações empilháveis | Múltiplos toasts de achievement sem sobreposição |
| ⬜ ScrollContainer no EventPopup | Para eventos com muitas opções |
| ⬜ Responsive layout | Ajustar para diferentes resoluções mobile |

---

## 🟡 FASE 4 — Conteúdo Expandido
**Estimativa de esforço:** Alto

| Tarefa | Detalhes |
|--------|----------|
| ⬜ Mais eventos (meta: 300+) | Adicionar ~160 eventos novos distribuídos por fase |
| ⬜ Eventos encadeados | Followup events que criam arcos de história |
| ⬜ Mais carreiras | Expandir careers.json (meta: 30+ carreiras) |
| ⬜ Sistema de crimes | Roubo, fraude, prisão, julgamento, ficha criminal |
| ⬜ Sistema de hobbies | Atividades como esportes, música, arte, cozinha |
| ⬜ Sistema de propriedades | Compra/venda de casas, carros, investimentos |
| ⬜ Sistema de saúde detalhado | Doenças, hospitalizações, fitness, dieta |
| ⬜ Mais achievements (meta: 50+) | Conquistas para todos os novos sistemas |
| ⬜ Localização completa | Traduzir todos os novos textos para PT_BR |
| ⬜ Mais países | Adicionar nomes e contexto para outros países |
| ⬜ Minigames opcionais | Joguinhos simples durante eventos (casino, esporte, etc.) |

---

## 🟡 FASE 5 — Sistemas Avançados
**Estimativa de esforço:** Alto

| Tarefa | Detalhes |
|--------|----------|
| ⬜ Herança entre vidas | Dinheiro/propriedades passam para próxima vida |
| ⬜ Árvore genealógica | Visualização da família ao longo das gerações |
| ⬜ Sistema de fama | Celebridade, influência social, escândalos |
| ⬜ Sistema de educação avançado | Escolha de curso, notas, universidade específica |
| ⬜ Empreendedorismo | Abrir negócio, gerenciar empresa, IPO |
| ⬜ Imigração | Mudar de país, dupla cidadania |
| ⬜ Desafios/Cenários | Vidas com condições iniciais especiais |
| ⬜ Modo historia | Eventos contextuais por década (guerras, pandemia, etc.) |
| ⬜ Cloud save | Sincronizar saves entre dispositivos |

---

## 🔵 FASE 6 — Publicação
**Estimativa de esforço:** Alto (legal + técnico)

### Steam
| Tarefa | Detalhes |
|--------|----------|
| ⬜ Conta Steamworks | Pagar $100 USD, aguardar aprovação |
| ⬜ Página da loja | Screenshots, trailer, descrição, tags |
| ⬜ Steam achievements | Integrar via GodotSteam plugin (achievements.json já pronto) |
| ⬜ Steamworks SDK | Integrar plugin GodotSteam |
| ⬜ Build Windows/Linux/Mac | Export templates do Godot |
| ⬜ Controles de teclado/mouse | Adaptar UI para desktop |
| ⬜ Trading cards (opcional) | Assets visuais para Steam trading cards |
| ⬜ Workshop (opcional) | Suporte a mods (eventos adicionais, etc.) |

### Mobile (Google Play / App Store)
| Tarefa | Detalhes |
|--------|----------|
| ⬜ Conta Google Play | Pagar $25 USD (única vez) |
| ⬜ Conta Apple Developer | Pagar $99 USD/ano |
| ⬜ Export Android APK/AAB | Godot export template Android |
| ⬜ Export iOS | Requer Mac para compilar (.ipa) |
| ⬜ Monetização | Ads (AdMob), IAP (premium), ou preço fixo |
| ⬜ Ícone + Screenshots | Por loja (diferentes resoluções) |
| ⬜ Classificação etária | ESRB / PEGI / ClassInd (Brasil) |

### Epic Games Store
| Tarefa | Detalhes |
|--------|----------|
| ⬜ Epic Developer Portal | Cadastro gratuito |
| ⬜ Epic Online Services | Achievements, cloud saves |
| ⬜ Build dedicado | Sem DRM específico requerido |

---

## 📋 RESUMO POR PRIORIDADE

1. **AGORA:** Rodar geração de áudio AI (`C:\IA\generate_assets.py music`)
2. **PRÓXIMO:** Rodar geração de imagens AI (`images`) + integrar no jogo
3. **CURTO PRAZO:** UI Polish — achievements screen, career panel, tutorial
4. **MÉDIO PRAZO:** Conteúdo expandido — 300+ eventos, crimes, hobbies, propriedades  
5. **LONGO PRAZO:** Sistemas avançados — herança, genealogia, empreendedorismo
6. **PUBLICAÇÃO:** Steam ($100) → Google Play ($25) → iOS ($99/ano) → Epic (grátis)

---

## 🛠 COMANDOS RÁPIDOS

```bash
# Gerar assets de áudio
python C:\IA\generate_assets.py music

# Gerar assets de imagem  
python C:\IA\generate_assets.py images

# Copiar para o jogo
python C:\IA\generate_assets.py copy

# Gerar tudo de uma vez
python C:\IA\generate_assets.py all

# Git commit + push
cd C:\Users\raphr\Documents\NewLife_Simulation
git add -A && git commit -m "mensagem" && git push
```
