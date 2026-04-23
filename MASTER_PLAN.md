# NewLife Simulation — Master Plan

> **Última atualização:** Abril 2026
> Este documento é a fonte única de verdade para o desenvolvimento do jogo.
> Substitui: DEV_CONTEXT_SAVESTATE.md, WORK_REMAINING.md, REFACTOR_PLAN.md, EVENTS_REVIEW.md, EVENTS_CHILD_REVIEW.md

---

## ✅ O QUE ESTÁ PRONTO

### Sistemas implementados
- [x] 13 features/bugs originais corrigidos
- [x] **140 eventos** expandidos (baby:20, child:25, teen:28, adult:45, elder:22)
- [x] Localização completa EN + PT_BR (828+ chaves em `texts.csv`)
- [x] `AudioManager` autoload (música por fase, SFX, crossfade, volume persistente)
- [x] `SaveManager` com persistência de settings (`save_setting` / `load_setting`)
- [x] `PauseMenu` completo (ESC, save, settings, stats, main menu, quit)
- [x] Sistema de **Achievements** (25 conquistas + `AchievementManager` + toast no HUD)
- [x] `SceneTransition` autoload (fade 0.3s em todas as telas)
- [x] Animações de barras de stats (tween 0.4s) + `EventPopup` fade in/out
- [x] Sistema de **Statistics** (Character dict + counters no GameManager + tela Statistics)
- [x] 8 autoloads registrados no `project.godot`
- [x] Git push para GitHub (branch `main`)

### Ferramentas de IA prontas
- [x] Python 3.12.6 + PyTorch 2.11.0 CUDA + diffusers 0.37.1 + transformers 5.5.4
- [x] Script `C:\IA\generate_assets.py` (Stable Diffusion 2.1 + MusicGen via transformers)
- [x] Prompts para 15 imagens + 11 áudios definidos

### Arquitetura do Efeito Borboleta (parcialmente implementada — Fase 1 do plano)
Variáveis ocultas já definidas e parte injetada em `Character.gd`:
- `family_hidden_wealth`, `family_stress_level`, `family_sanity`
- `mother_age`, `father_age`, `mother_fertility`, `father_fertility`
- `mother_health`, `father_health`, `mother_happiness`, `father_happiness`
- `parents_depressed` (bool), `siblings_count`, `dead_siblings`
- `pets`: Array de dicionários (afinidade + tags de depressão)

---

## � SCHEMA DE EVENTO (JSON)

> **Referência canônica do schema.** Nunca invente campos — use apenas os listados abaixo.
> Arquivo de destino: `data/events/{phase}_events.json`
> Parser: `scripts/data_models/EventData.gd` → `EventData.from_dict()`

### Campos do evento (top-level)

```json
{
  "id": "child_bully_becomes_friend",
  "phases": ["CHILD"],
  "age_min": 7,
  "age_max": 12,
  "category": "social",
  "weight": 40,
  "conditions": {
    "has_trait": "brave"
  },
  "text_key": "EVENT_CHILD_BULLY_BECOMES_FRIEND",
  "log_only": false,
  "choices": []
}
```

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|----------|
| `id` | String | ✅ | snake_case único. Prefixo = fase (`child_`, `teen_`, etc.) |
| `phases` | Array\[String\] | ✅ | `["BABY"]`, `["CHILD"]`, `["TEEN"]`, `["ADULT"]`, `["ELDER"]` ou múltiplos |
| `age_min` / `age_max` | int | ✅ | Faixa de idade em que o evento pode aparecer |
| `category` | String | ✅ | `school`, `family`, `health`, `social`, `crime`, `career`, `finance`, `random` |
| `weight` | int | ✅ | Probabilidade relativa de sorteio. `0` = evento forçado por lógica (nunca sorteado) |
| `conditions` | Dictionary | — | Pré-requisitos verificados em `matches_character()`. Ver tabela abaixo |
| `text_key` | String | ✅ | Chave de localização em `texts.csv` (ex: `EVENT_CHILD_BULLY_BECOMES_FRIEND`) |
| `log_only` | bool | — | `true` = aplica a primeira choice automaticamente, sem mostrar popup |
| `choices` | Array\[Dictionary\] | ✅ | Lista de escolhas (ver schema abaixo) |

### Chaves suportadas em `conditions` (já implementadas em `EventData.gd`)

| Chave | Tipo | Exemplo |
|-------|------|---------|
| `min_health` / `max_health` | int | `"min_health": 40` |
| `min_intelligence` / `max_intelligence` | int | — |
| `min_charisma` / `max_charisma` | int | — |
| `min_appearance` / `max_appearance` | int | — |
| `min_happiness` / `max_happiness` | int | — |
| `min_morality` / `max_morality` | int | — |
| `min_money` / `max_money` | float | `"max_money": 500` |
| `has_trait` | String ou Array | `"has_trait": "brave"` ou `["brave", "athletic"]` |
| `not_trait` | String ou Array | `"not_trait": "lazy"` |
| `has_career` | bool ou String | `true` = tem emprego; `"doctor"` = carreira específica |
| `no_career` | bool | `true` = sem emprego |
| `min_education` | int | `"min_education": 2` |
| `social_class` | String | `"social_class": "poor"` |

> ⚠️ **Sprint 5** adicionará novas chaves para os campos ocultos ainda não existentes em `Character.gd`: `min_stress`, `max_stress`, `min_family_wealth`, `max_family_wealth`, `has_emotional_tag`. Não use essas chaves em eventos do Sprint 3 — elas não serão reconhecidas até o Sprint 5 ser implementado.

### Schema de cada `choice`

```json
{
  "text_key": "CHOICE_BEFRIEND_BULLY",
  "effects": {
    "charisma": 4,
    "happiness": 3,
    "health": -1
  },
  "relationship_effects": {
    "MOTHER": { "affection": 2 },
    "FATHER": { "affection": -1 }
  },
  "trait_chance": { "trait": "compassionate", "chance": 0.12 },
  "followup_event": "child_bully_escalates",
  "money_effect": -50.0,
  "morality_effect": 5,
  "log_only": false
}
```

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `text_key` | String | Chave de localização do botão/texto da escolha |
| `effects` | Dictionary | Stats afetados: `health`, `happiness`, `intelligence`, `charisma`, `appearance`, `temperament`, `mental_stability`, `luck` |
| `relationship_effects` | Dictionary | `{ "TIPO": { "affection": int } }`. TIPOs: `MOTHER`, `FATHER`, `SIBLING`, `FRIEND`, `PARTNER` |
| `trait_chance` | Dictionary | `{ "trait": String, "chance": float (0.0–1.0) }` — probabilidade de ganhar o traço |
| `followup_event` | String | ID de evento a enfileirar imediatamente após essa escolha (chain events) |
| `money_effect` | float | Valor em dinheiro adicionado/removido (positivo ou negativo) |
| `morality_effect` | int | Pontos de moralidade adicionados/removidos |

### Exemplo completo — evento encadeado

```json
{
  "id": "child_bully_becomes_friend",
  "phases": ["CHILD"],
  "age_min": 7,
  "age_max": 12,
  "category": "social",
  "weight": 0,
  "conditions": {},
  "text_key": "EVENT_CHILD_BULLY_BECOMES_FRIEND",
  "log_only": false,
  "choices": [
    {
      "text_key": "CHOICE_FORGIVE_BULLY",
      "effects": { "charisma": 3, "happiness": 5 },
      "relationship_effects": { "FRIEND": { "affection": 8 } },
      "trait_chance": { "trait": "compassionate", "chance": 0.15 },
      "morality_effect": 5
    },
    {
      "text_key": "CHOICE_REJECT_BULLY",
      "effects": { "happiness": -2 },
      "followup_event": "child_bully_escalates",
      "morality_effect": -2
    },
    {
      "text_key": "CHOICE_IGNORE_BULLY",
      "effects": { "mental_stability": 2 }
    }
  ]
}
```

> **Nota sobre `weight: 0`:** Eventos com `weight: 0` nunca são sorteados aleatoriamente. Eles só disparam via `followup_event` de outra escolha ou via código no `GameManager` (eventos forçados do sistema oculto).

---
## ✅ STATUS FINAL DOS SPRINTS

| Sprint | Descrição | Status |
|--------|-----------|--------|
| Sprint 1 | Assets (Áudio + Visual) | 🔄 Parcial |
| Sprint 2 | UI/UX Polish | ✅ COMPLETO |
| Sprint 3 | 321 Eventos | ✅ COMPLETO |
| Sprint 4 | Sistemas: Crime, Hobbies, Propriedades, Saúde | ✅ COMPLETO |
| Sprint 5 | Efeito Borboleta Completo | ✅ COMPLETO |
| Sprint 6 | Combate, Licenças, Carreiras Interativas, UI wiring | ✅ COMPLETO |
| Sprint 7 | Herança, Genealogia, Sistema de Fama | ✅ COMPLETO |
| Sprint 8 | Export configs, Google Play, Steam/PC | ✅ COMPLETO |

---
## �🗺️ ROADMAP POR SPRINT

### SPRINT 1 — Assets (Áudio + Visual)

**Prioridade: ALTA** — fecha a sensação de "jogo vivo"

#### Áudio
| Tarefa | Comando | Status |
|--------|---------|--------|
| Rodar geração de músicas | `python C:\IA\generate_assets.py music` | ⬜ |
| Copiar para `assets/sounds/` | `python C:\IA\generate_assets.py copy` | ⬜ |
| Testar AudioManager no Godot | — | ⬜ |
| Ajustar loop points (Audacity) | — | ⬜ |

**Arquivos esperados em `assets/sounds/`:**
```
music_baby.wav, music_child.wav, music_teen.wav, music_adult.wav,
music_elder.wav, music_menu.wav, music_death.wav,
sfx_click.wav, sfx_event.wav, sfx_achievement.wav, sfx_year_advance.wav
```

#### Visual
| Tarefa | Detalhes | Status |
|--------|----------|--------|
| Rodar geração de imagens | `python C:\IA\generate_assets.py images` | ⬜ |
| Integrar backgrounds | bg_main_menu no MainMenu.tscn, bg_game_over no LifeSummary | ⬜ |
| Integrar ícones de fase | icon_baby/child/teen/adult/elder no GameHUD | ⬜ |
| Integrar ícones de categoria | icon_health/career/crime/romance/finance no EventPopup | ⬜ |
| App icon final | Substituir icon.svg por arte profissional | ⬜ |
| Splash screen | Imagem de loading ao abrir o jogo | ⬜ |

---

### SPRINT 2 — UI/UX Polish

**Prioridade: MÉDIA-ALTA** — reflete profundidade do simulador

| Tarefa | Detalhes | Status |
|--------|----------|--------|
| Tutorial / Onboarding | Tour inicial explicando fases, stats, eventos, achievements | ⬜ |
| Tela de Achievements | Grade visual com lock/unlock, ícones, progresso | ⬜ |
| Painel de Relacionamentos | Lista completa (pais, irmãos, amigos, crush) + barra de afinidade | ⬜ |
| Painel de Carreira | Nível, salário, progresso, opções (pedir demissão, aumento, etc.) | ⬜ |
| Inventário / Propriedades | Casas, carros, investimentos, itens | ⬜ |
| Barras coloridas por valor | Verde (bom) → Amarelo → Vermelho (ruim) | ⬜ |
| Animação de passagem de ano | Contador subindo + fade de stats | ⬜ |
| Toasts empilháveis | Múltiplos eventos num ano sem sobreposição | ⬜ |
| ScrollContainer no EventPopup | Para eventos com muitas opções | ⬜ |
| Layout responsivo | Ajustar para diferentes resoluções mobile | ⬜ |
| Tema atualizado | Integrar backgrounds, melhorar tipografia | ⬜ |

---

### SPRINT 3 — Expansão de Conteúdo (meta: 300+ eventos)

**Prioridade: ALTA** — é o coração do "BitLife power"
**Estado atual:** 140 eventos. **Meta:** 300+ (+160 novos)

> ⚠️ **Dependência de ordem:** O campo `conditions` já existe e funciona em `EventData.gd` para as chaves padrão de stats (`min_health`, `has_trait`, `max_money`, etc.). Eventos novos do Sprint 3 **podem e devem** usar essas chaves imediatamente.
> As chaves para campos ocultos (`min_stress`, `has_emotional_tag`, `min_family_wealth`) só estarão disponíveis **após o Sprint 5**. Eventos que dependem delas devem ter `"weight": 0` e ser ativados por `followup_event` até lá.

#### Distribuição-alvo por fase
| Fase | Atual | Meta | +Delta |
|------|-------|------|--------|
| Baby | 20 | 35 | +15 |
| Child | 25 | 65 | +40 |
| Teen | 28 | 65 | +37 |
| Adult | 45 | 100 | +55 |
| Elder | 22 | 35 | +13 |
| **Total** | **140** | **300** | **+160** |

#### Novos eventos CHILD sugeridos (prioritários)

**Escola**
| ID | Descrição |
|----|-----------|
| `child_cheating_exam` | Oportunidade de colar na prova (dilema moral) |
| `child_teacher_favorite` | Professor te destaca como favorito da turma |
| `child_bad_grade_parents` | Nota baixa — como os pais vão reagir? |
| `child_school_election` | Eleição do líder de turma — você se candidata? |
| `child_school_brawl` | Briga explode na escola — você se envolve? |
| `child_class_presentation` | Apresentação oral na frente da turma |
| `child_gifted_program` | Turma especial para talentos detectados |
| `child_skip_grade` | Professor sugere pular um ano |
| `child_learning_disability` | Dificuldade de aprendizado identificada (dislexia, etc.) |
| `child_after_school_detention` | Pegou detenção por besteira |

**Social**
| ID | Descrição |
|----|-----------|
| `child_playground_rumor` | Espalharam uma mentira sobre você na escola |
| `child_first_crush` | Primeiro interesse romântico (infantil) |
| `child_friend_betrayal` | Seu melhor amigo contou seu segredo |
| `child_neighbor_friend` | Criança da vizinhança te convida para brincar |
| `child_sleepover` | Você é convidado para dormir na casa de um amigo |
| `child_bully_becomes_friend` | Chain: bully pode virar amigo ou piorar |
| `child_popular_group` | Grupo popular te convida para entrar |
| `child_social_exclusion` | Colegas te excluem de um grupo ou brincadeira |

**Saúde**
| ID | Descrição |
|----|-----------|
| `child_broken_bone` | Você quebra um osso brincando |
| `child_glasses` | Médico descobre que você precisa de óculos |
| `child_allergy_diagnosed` | Alergia severa diagnosticada |
| `child_obesity_risk` | Médico avisa sobre peso — família reage diferente conforme riqueza |
| `child_sports_injury` | Machucado durante competição |

**Família**
| ID | Descrição |
|----|-----------|
| `child_stepparent` | Pai/mãe começa a namorar alguém novo (pós-divórcio) |
| `child_parent_lost_job` | Um dos pais ficou desempregado |
| `child_moved_city` | Família muda de cidade — nova escola, amigos novos |
| `child_grandparent_ill` | Avô/avó adoece gravemente |
| `child_grandparent_dies` | Avô/avó falece — primeiro contato com a morte |
| `child_family_vacation` | Viagem de férias em família |
| `child_chores_allowance` | Pais propõem mesada em troca de tarefas |
| `child_religious_event` | Primeira comunhão, bar mitzvah, etc. |
| `child_parent_remarried` | Um dos pais se casa novamente |

**Finanças / Crime infantil**
| ID | Descrição |
|----|-----------|
| `child_first_allowance` | Recebe mesada pela 1ª vez |
| `child_lost_money` | Perdeu o dinheiro do lanche |
| `child_steal_candy` | Tentação de pegar doce sem pagar (dilema moral) |
| `child_lemonade_stand` | Montar uma banca de limonada/doces |
| `child_find_wallet` | Achou uma carteira com dinheiro — o que fazer? |

**Personalidade / Desenvolvimento**
| ID | Descrição |
|----|-----------|
| `child_nightmare_recurring` | Pesadelos recorrentes — pode gerar ansiedade ou trauma |
| `child_lying_habit` | Começa a mentir para se safar (influencia traço) |
| `child_hero_idol` | Admira um herói/ídolo (pode influenciar traço adulto) |
| `child_artistic_talent` | Talento artístico inesperado descoberto |
| `child_curiosity_fire` | Mexeu com fósforo por curiosidade |
| `child_speech_impediment` | Gagueira ou problema de fala descoberto |

#### Cadeias de eventos prioritárias (cross-age)
| Cadeia | Fases | Descrição |
|--------|-------|-----------|
| Bully → evolução | Child → Teen | Bully pode virar amigo, piorar ou desaparecer |
| Avô doente → morte | Child/Teen | Primeiro contato com morte, luto, herança |
| Mudança de cidade | Child → Teen | Perde amigos, reconstrói vida social nova |
| Mentira infantil | Child → Adult | Padrão de comportamento desonesto se desenvolve |
| Banca de limonada | Child → Teen → Adult | Semente de empreendedorismo |
| Criminalidade crescente | Child → Teen → Adult | Furto de doce → furto de loja → crime adulto |
| Trauma familiar | Baby/Child | Abuso/divórcio → ansiedade adulta oculta |

---

### SPRINT 4 — Novos Sistemas (Crimes, Hobbies, Propriedades, Saúde)

**Prioridade: ALTA** — diferencial competitivo vs BitLife

#### 4.1 Sistema de Crimes (`CrimeSystem.gd` — NOVO)
- Crimes com múltiplas abordagens (ex: roubar casa → janela vs porta)
- Cada abordagem requer itens/habilidades
- Consequências: preso, ferido, solto, ficha criminal
- Mercado paralelo: `data/items/black_market.json` (itens com função mecânica)
- Integra com `adult_events.json` e `teen_events.json`

#### 4.2 Sistema de Hobbies
- Esporte, música, arte, cozinha — começam na infância
- Cada hobby tem nível (iniciante → expert)
- Hobbies afetam stats (saúde, felicidade, inteligência)
- Eventos específicos por hobby (competições, apresentações, etc.)
- Amarra child_music_lessons → teen_band → adult_musician_career

#### 4.3 Sistema de Propriedades
- Compra/aluguel de casas e carros
- Investimentos (ações, poupança, imóveis)
- Propriedades afetam `family_hidden_wealth` e status social
- Eventos ligados (reforma, roubo, valorização/desvalorização)

#### 4.4 Sistema de Saúde Detalhado
- Doenças com diferentes gravidades (gripe → câncer)
- Hospitalização (caro vs barato conforme `family_hidden_wealth`)
- Fitness como stat separado (afetado por gym, esporte, dieta)
- Vícios com consequências progressivas (álcool, drogas, jogo)

---

### SPRINT 5 — Efeito Borboleta Completo

**Prioridade: ALTA** — coração da simulação profunda

#### Arquivos a modificar/criar

**`scripts/data_models/Character.gd`** — adicionar status ocultos
```
stress (0-100)
sanity (0-100)
hidden_wealth (int oculto, diferente do "money" exibido)
emotional_tags: Array[String] (ex: "trauma_infancia", "mentiroso_cronico")
criminal_record: bool
```

**`scripts/autoloads/GameManager.gd`** — Motor de Economia Familiar
- Roda a cada `age_up()`
- Avalia `family_stress_level` para disparar eventos forçados:
  - Stress > 80 → risco de agressão doméstica
  - `hidden_wealth < 0` → mudança de escola / perda de casa
  - Divórcio → renda familiar cai `* 0.5` se mãe não trabalha
- Avalia `parents_depressed` → eventos de negligência

**`scripts/autoloads/EventManager.gd`** — pré-requisitos ocultos
- Eventos com `conditions`: `{min_wealth: X, has_tag: "Y", min_stress: Z}`
- Exemplo: `family_poverty_work` só dispara se `family_hidden_wealth < 1000`

**`scripts/data_models/EventData.gd`** — adicionar novas chaves ao `matches_character()`
> O campo `conditions` e suas chaves de stats já existem. Sprint 5 acrescenta apenas os novos `match` cases para os campos ocultos:
```gdscript
# Novos cases a adicionar em matches_character():
"min_stress":         if character.stress < val: return false
"max_stress":         if character.stress > val: return false
"min_family_wealth":  if character.family_hidden_wealth < val: return false
"max_family_wealth":  if character.family_hidden_wealth > val: return false
"has_emotional_tag":  if not character.emotional_tags.has(val): return false
"not_emotional_tag":  if character.emotional_tags.has(val): return false
"criminal_record":    if character.criminal_record != val: return false
```

#### Mecânicas biológicas ocultas (0-3 anos)
| Mecânica | Trigger | Efeito |
|----------|---------|--------|
| Gravidez/aborto oculto | fertilidade + stress > 70 | `family_miscarriage` + depressão |
| Risco doméstico | stress > 80 | abuso → prisão do pai → queda da riqueza |
| Pet autônomo | stress > 80 + pet existente | ataque, destruição, adoção |
| Acidente de bebê | luck < 30 | 15% chance queda/engasgo; tratamento depende da riqueza |
| Micro-terapia | casamento falido + stress > 60 | $800 ocultos para terapia de casal |

---

### SPRINT 6 — Sistemas Avançados (Combate, Carreiras Interativas, Licenças)

#### 6.1 CombatSystem.gd (NOVO)
- Brigas em turnos simples: escolha onde bater (Rosto / Corpo / Extremidades)
- Dano calculado por força + agilidade do Character
- Consequências: hospital, prisão, morte
- Acionado por eventos de agressão (familiar, assalto, briga de bar)

#### 6.2 Carreiras Interativas
- Cada carreira dispara 1 evento de "dia de trabalho" por ano com dilemas éticos
- Profissões herói (médico, policial, advogado) com mini-sistemas próprios
- `MedicalCareerSystem.gd`: pacientes gerados aleatoriamente, erro médico, CRM
- `careers.json`: campo `event_prompts` por nível de carreira

#### 6.3 Sistema de Licenças / Provas Práticas
- Carteira de motorista, piloto, barco = quiz textual obrigatório
- Falha → perda de dinheiro sem receber licença, pode tentar de novo
- `data/events/adult_events.json`: array `quiz_questions` por licença

---

### SPRINT 7 — Sistemas de Longo Prazo

| Tarefa | Detalhes |
|--------|----------|
| Herança entre vidas | Dinheiro/propriedades passam para próxima vida |
| Árvore genealógica | Visualização da família ao longo das gerações |
| Sistema de fama | Celebridade, influência social, escândalos |
| Educação avançada | Escolha de curso, notas, universidade específica |
| Empreendedorismo | Abrir negócio, gerenciar empresa, IPO |
| Imigração | Mudar de país, dupla cidadania |
| Desafios/Cenários | Vidas com condições iniciais especiais |
| Modo história | Eventos contextuais por década (guerras, pandemia, etc.) |
| Cloud save | Sincronizar saves entre dispositivos |

---

### SPRINT 8 — Publicação

#### Google Play / Mobile
| Tarefa | Detalhes | Status |
|--------|----------|--------|
| Conta Google Play | $25 USD (única vez) | ⬜ |
| Export Android AAB | Godot export template Android | ⬜ |
| Monetização | AdMob ads + opção premium | ⬜ |
| Ícone + Screenshots | Resoluções de loja | ⬜ |
| Classificação etária | ClassInd (Brasil) + PEGI | ⬜ |

#### Steam / PC
| Tarefa | Detalhes | Status |
|--------|----------|--------|
| Conta Steamworks | $100 USD | ⬜ |
| GodotSteam plugin | Steam achievements integrados | ⬜ |
| Build Windows/Linux/Mac | Export templates do Godot | ⬜ |
| Controles teclado/mouse | Adaptar UI para desktop | ⬜ |
| Página da loja | Screenshots, trailer, descrição, tags | ⬜ |

#### Epic Games Store
| Tarefa | Detalhes | Status |
|--------|----------|--------|
| Epic Developer Portal | Cadastro gratuito | ⬜ |
| Epic Online Services | Achievements, cloud saves | ⬜ |

---

## 📊 COMPARATIVO BITLIFE (O QUE AINDA FALTA)

| Mecânica BitLife | Temos? | Sprint |
|-----------------|--------|--------|
| Relacionamentos individuais evoluindo | ✅ parcial | Sprint 3 |
| Bully pode piorar, melhorar ou sumir | ❌ | Sprint 3 |
| Pais reagem a notas/comportamento | ❌ | Sprint 3 |
| Morte de avós como primeira experiência com morte | ❌ | Sprint 3 |
| Mudança de cidade = perda de todos amigos | ❌ | Sprint 3 |
| Primeira renda na infância (mesada, banca) | ❌ | Sprint 3 |
| Decisões morais crescentes (mentir, roubar) | ❌ | Sprint 3 |
| Eventos de saúde que afetam autoestima | ❌ | Sprint 3 |
| Stepparent / nova configuração familiar | ❌ | Sprint 3 |
| Programa de superdotados / pular ano | ❌ | Sprint 3 |
| Crimes com múltiplas abordagens | ❌ | Sprint 4 |
| Hobbies com progressão de nível | ❌ | Sprint 4 |
| Propriedades com valor real | ❌ | Sprint 4 |
| Doenças com tratamentos diferentes por riqueza | ❌ | Sprint 4 |
| Efeito borboleta oculto (stress → eventos forçados) | ❌ | Sprint 5 |
| Combate em turnos | ❌ | Sprint 6 |
| Dilemas de trabalho por profissão | ❌ | Sprint 6 |
| Quiz para licenças (motorista, piloto) | ❌ | Sprint 6 |
| Herança entre gerações | ❌ | Sprint 7 |

---

## 🗂️ ESTRUTURA DE ARQUIVOS RELEVANTES

```
scripts/
  autoloads/
    GameManager.gd       — Motor principal + Economia Familiar (Sprint 5)
    EventManager.gd      — Disparador de eventos + condições ocultas (Sprint 5)
    AchievementManager.gd
    AudioManager.gd
    SaveManager.gd
  data_models/
    Character.gd         — Adicionar status ocultos (Sprint 5)
    EventData.gd         — Adicionar novos match cases em matches_character() (Sprint 5)
  systems/
    CrimeSystem.gd       — NOVO (Sprint 4)
    CombatSystem.gd      — NOVO (Sprint 6)
    MedicalCareerSystem.gd — NOVO (Sprint 6)
    FamilyEconomySystem.gd — Expandir (Sprint 5)
  ui/
    EventPopup.gd / .tscn
    GameHUD.gd / .tscn
    CombatHUD.gd / .tscn — NOVO (Sprint 6)

data/
  events/
    baby_events.json     — 20 eventos + sistema oculto (expandir Sprint 3)
    child_events.json    — 25 eventos (expandir +40 Sprint 3)
    teen_events.json     — 28 eventos (expandir +37 Sprint 3)
    adult_events.json    — 45 eventos (expandir +55 Sprint 3)
    elder_events.json    — 22 eventos (expandir +13 Sprint 3)
  items/
    black_market.json    — NOVO (Sprint 4)
  careers/
    careers.json         — Expandir com event_prompts (Sprint 6)
```

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
git add . ; git commit -m "feat: descrição" ; git push origin main
```

---

## 📋 PRÓXIMA AÇÃO IMEDIATA

**Sprint 1 — Áudio:** `python C:\IA\generate_assets.py music` → testar AudioManager no Godot  
**Sprint 3 — Eventos:** Implementar os 40 novos eventos child a partir da tabela acima  
**Sprint 5 — Efeito Borboleta:** Adicionar campos ocultos no `Character.gd` e lógica no `GameManager.gd`
