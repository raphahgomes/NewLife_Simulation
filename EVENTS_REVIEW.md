# Revisão de Eventos — O que é POPUP vs LOG

Coloque na frente de cada evento:
- `POPUP` → aparece como popup interativo com botões de escolha
- `LOG` → aparece apenas como texto no feed (sem escolha)
- `REMOVER` → deletar o evento

---

## 🍼 BEBÊ (Baby)

### Eventos Principais (weight > 0 = pode sair aleatoriamente)

| ID | Texto | Tipo |
|----|-------|------|
| `baby_first_word` | Você disse sua primeira palavra! | |
| `baby_crawling` | Você começa a engatinhar pela casa | |
| `baby_ignored_cry` | Você chora alto... mas ninguém vem | |
| `baby_parent_reads` | Sua mãe te lê uma história antes de dormir | |
| `baby_sick` | Você pegou uma virose pesada | |
| `baby_playground` | Hora de ir ao parquinho! | |
| `baby_funny_face` | Alguém faz caretas pra você! | |
| `baby_first_steps` | Você dá seus primeiros passos! | |
| `baby_teething` | Seus dentes estão nascendo! | |
| `baby_night_terror` | Você acorda gritando de noite! | |
| `baby_bath_time` | Hora do banho! | |
| `baby_first_birthday` | É seu primeiro aniversário! | |
| `baby_daycare` | Você começa a ir para a creche | |
| `baby_food_allergy` | Você teve uma reação alérgica a comida! | |
| `baby_learning_colors` | Alguém está te ensinando as cores! | |
| `baby_toy_sharing` | Outra criança quer seu brinquedo | |
| `baby_nursery_rhymes` | Alguém canta cantigas de ninar pra você! | |
| `baby_first_haircut` | Hora do seu primeiro corte de cabelo! | |
| `baby_sibling_born` | Um novo irmãozinho ou irmãzinha chega! | |
| `baby_grandparent_visit` | Os avós vêm visitar! | |

### Eventos Forçados — Sistema Oculto (weight = 0, disparados por lógica)

| ID | Texto | Tipo |
|----|-------|------|
| `family_adopted_pet` | Sua família adotou um animal de estimação! | |
| `family_healed_depression` | O clima em casa melhorou, a depressão passou | |
| `family_parent_promotion` | Um dos seus pais foi promovido no trabalho! | |
| `family_miscarriage` | Sua mãe sofreu um aborto espontâneo... | |
| `family_new_sibling` | Você vai ter um irmãozinho ou irmãzinha! | |
| `family_abuse_extreme_saved` | Violência doméstica quase virou tragédia, alguém interveio | |
| `family_abuse_extreme_arrest` | Seu pai foi preso por violência doméstica | |
| `family_divorce_stress` | Seus pais estão se divorciando | |
| `family_poverty_work` | Seus pais estão trabalhando em dobro para escapar das dívidas | |
| `baby_poor_health_colic` | Cólicas terríveis! A má alimentação está te prejudicando | |
| `baby_rich_health_cold` | Você ficou gripado, mas recebeu o melhor tratamento | |
| `baby_random_accident_cured` | Você teve um acidente sério mas foi curado completamente | |
| `baby_random_accident_poor` | Você teve um acidente e não teve o melhor tratamento | |
| `parents_paid_therapy_child` | Seus pais pagaram um psicólogo infantil para você | |
| `parents_couple_therapy` | Seus pais estão fazendo terapia de casal | |
| `pet_mischief_mess` | O pet surtou de estresse e destruiu coisas em casa! | |
| `pet_trainer_hired` | Seus pais contrataram um adestrador profissional | |
| `pet_attacked_and_donated` | O pet te mordeu com força e foi doado | |
| `pet_attacked_retained` | O pet te mordeu e ficou na família mesmo assim | |

---

## 🧒 CRIANÇA (Child)

| ID | Texto | Tipo |
|----|-------|------|
| `child_school_start` | É seu primeiro dia de aula! | |
| `child_bully` | Um garoto maior começa a te intimidar na escola | |
| `child_best_friend` | Você conhece alguém que pode ser seu melhor amigo | |
| `child_test` | Uma prova importante está chegando | |
| `child_sport` | A escola oferece clubes de esporte e leitura | |
| `child_talent_show` | O show de talentos da escola está chegando! | |
| `child_stray_animal` | Você encontra um animal abandonado na rua | |
| `child_parents_fight` | Seus pais estão tendo uma grande discussão | |
| `child_money_found` | Você encontra dinheiro no chão! | |
| `child_science_fair` | A feira de ciências da escola está chegando! | |
| `child_music_lessons` | Seus pais te inscrevem em aulas de música | |
| `child_summer_camp` | Hora do acampamento de verão! | |
| `child_field_trip` | Sua turma vai fazer uma excursão! | |
| `child_homework_trouble` | Você está tendo dificuldade com a lição de casa | |
| `child_new_kid` | Um aluno novo entra na sua turma | |
| `child_dentist` | Hora de ir ao dentista! | |
| `child_birthday_party` | Seu aniversário está chegando! | |
| `child_swimming` | Aulas de natação estão disponíveis | |
| `child_video_games` | Você descobre videogames! | |
| `child_cooking` | Seu pai/mãe te convida para cozinhar junto | |
| `child_sibling_rivalry` | Você e seu irmão estão brigando de novo | |
| `child_lost_pet` | Seu animal de estimação desapareceu! | |
| `child_nature_hike` | Sua família faz uma trilha na natureza | |
| `child_art_class` | Hoje é dia de aula de artes! | |
| `child_library` | Você visita a biblioteca | |
| `neighbor_pet_attack_1` | (Evento de ataque de animal — neighbor) | |
| `pet_attack_escape` | (Evento de fuga do animal) | |
| `pet_attack_bitten` | (Evento de mordida do animal) | |
| `pet_attack_friends` | (Evento de amizade com animal) | |

---

## 🧑 ADOLESCENTE (Teen)

| ID | Texto | Tipo |
|----|-------|------|
| `teen_sneak_out` | Você quer sair de casa escondido | |
| `teen_first_crush` | Você se apaixona por alguém da escola | |
| `teen_party_invite` | Você foi convidado para uma festa | |
| `teen_job_offer` | Uma loja local te oferece trabalho de meio período | |
| `teen_exam_pressure` | As provas finais estão chegando e a pressão aumenta | |
| `teen_drugs_offer` | Alguém te oferece drogas em uma festa | |
| `teen_college_decision` | É hora de decidir seu futuro após a escola | |
| `teen_social_media` | As redes sociais estão dominando sua vida | |
| `teen_volunteer` | Uma caridade local precisa de voluntários | |
| `teen_breakup` | Seu relacionamento acabou | |
| `teen_shoplifting` | Seus amigos te desafiam a furtar uma loja | |
| `teen_driving_lessons` | Você tem idade para aprender a dirigir! | |
| `teen_prom` | A noite do baile está chegando! | |
| `teen_detention` | Você pegou detenção! | |
| `teen_sports_tryout` | As seleções do time de esporte são hoje! | |
| `teen_online_bullying` | Alguém está te fazendo cyberbullying online | |
| `teen_identity_crisis` | Você está questionando quem você realmente é | |
| `teen_gaming_addiction` | Videogames estão consumindo sua vida | |
| `teen_climate_activism` | Há um protesto sobre mudanças climáticas perto | |
| `teen_mental_health` | Você está se sentindo pra baixo há semanas | |
| `teen_tattoo_piercing` | Você quer fazer um piercing ou tatuagem | |
| `teen_internship` | Uma empresa te oferece um estágio de verão | |
| `teen_body_image` | Você está preocupado com sua aparência | |
| `teen_secret_relationship` | Você está em um relacionamento secreto | |
| `teen_graduation` | Dia da formatura do ensino médio! | |
| `teen_band` | Você e amigos querem formar uma banda | |
| `teen_peer_pressure` | Seus amigos estão te pressionando a fazer algo errado | |
| `teen_scholarship` | Você se qualifica para uma bolsa de estudos! | |
| `teen_part_time_stress` | Seu trabalho de meio período está te estressando | |
| `teen_possessive` | (Evento de relacionamento possessivo) | |
| `teen_school_fight` | (Evento de briga na escola) | |
| `teen_peer_pressure_smoking` | (Pressão dos amigos — cigarro) | |

---

## 👨 ADULTO (Adult)

| ID | Texto | Tipo |
|----|-------|------|
| `adult_job_interview` | Você tem uma entrevista de emprego! | |
| `adult_promotion` | Seu chefe te oferece uma promoção! | |
| `adult_marriage_proposal` | Você está pensando em pedir alguém em casamento | |
| `adult_have_child` | Você tem a oportunidade de ter um filho | |
| `adult_buy_house` | Você pode comprar uma casa! | |
| `adult_health_scare` | Você nota sintomas de saúde preocupantes | |
| `adult_business_idea` | Você teve uma ideia de negócio incrível! | |
| `adult_midlife_crisis` | Você está questionando suas escolhas de vida | |
| `adult_divorce` | Seu casamento está desmoronando | |
| `adult_car_accident` | Você sofreu um acidente de carro! | |
| `adult_fraud` | Você descobre um jeito de cometer fraude no trabalho | |
| `adult_charity` | Uma caridade pede sua doação | |
| `adult_apartment_rental` | (Aluguel de apartamento) | |
| `adult_career_change` | (Mudança de carreira) | |
| `adult_travel` | (Viagem) | |
| `adult_investment` | (Investimento) | |
| `adult_gym` | (Academia) | |
| `adult_pet_adoption` | (Adoção de pet) | |
| `adult_layoff` | (Demissão) | |
| `adult_burnout` | (Burnout) | |
| `adult_side_hustle` | (Renda extra) | |
| `adult_networking` | (Networking) | |
| `adult_therapy` | (Terapia) | |
| `adult_home_renovation` | (Reforma da casa) | |
| `adult_neighbor_conflict` | (Conflito com vizinho) | |
| `adult_reunion` | (Reunião de ex-colegas) | |
| `adult_marathon` | (Maratona) | |
| `adult_jury_duty` | (Júri) | |
| `adult_home_breakin` | (Arrombamento de casa) | |
| `adult_gambling` | (Jogo) | |
| `adult_mentor` | (Mentoria) | |
| `adult_addiction` | (Vício) | |
| `adult_cooking_hobby` | (Hobby de cozinha) | |
| `adult_traffic_ticket` | (Multa de trânsito) | |
| `adult_volunteer_abroad` | (Voluntariado no exterior) | |
| `adult_inheritance` | (Herança) | |
| `adult_social_media_fame` | (Fama nas redes sociais) | |
| `adult_lawsuit` | (Processo judicial) | |
| `adult_cheating_partner` | (Traição do parceiro) | |
| `adult_new_skill` | (Nova habilidade) | |
| `adult_pregnancy_scare` | (Susto de gravidez) | |
| `adult_debt_collector` | (Cobrador de dívida) | |
| `adult_natural_disaster` | (Desastre natural) | |
| `adult_wedding_planning` | (Planejamento do casamento) | |
| `adult_betrayal` | (Traição) | |
| `adult_accident` | (Acidente) | |
| `adult_memed` | (Virou meme) | |
| `adult_party_drugs` | (Drogas em festa) | |
| `adult_depression_alcohol` | (Depressão e álcool) | |

---

## 👴 IDOSO (Elder)

| ID | Texto | Tipo |
|----|-------|------|
| `elder_retirement` | É hora de se aposentar | |
| `elder_grandchild` | Você tem um neto! | |
| `elder_health_decline` | Sua saúde está piorando | |
| `elder_will` | É hora de escrever seu testamento | |
| `elder_legacy` | Pessoas perguntam sobre sua história de vida | |
| `elder_friend_dies` | Um velho amigo faleceu | |
| `elder_hobby` | Você tem tempo livre para hobbies | |
| `elder_scam` | Você recebe uma ligação suspeita | |
| `elder_bucket_list` | (Lista de desejos antes de morrer) | |
| `elder_teaching` | (Ensinar/mentorar alguém) | |
| `elder_health_screening` | (Exame de saúde preventivo) | |
| `elder_downsizing` | (Reduzir para uma casa menor) | |
| `elder_technology` | (Dificuldade com tecnologia) | |
| `elder_family_reunion` | (Reunião da família) | |
| `elder_memory_loss` | (Perda de memória) | |
| `elder_community_award` | (Prêmio da comunidade) | |
| `elder_gardening` | (Jardinagem) | |
| `elder_pet_companion` | (Pet de companhia) | |
| `elder_spiritual_journey` | (Jornada espiritual) | |
| `elder_fall_injury` | (Queda / lesão) | |
| `elder_volunteer_retire` | (Voluntariado na aposentadoria) | |
| `elder_spouse_death` | (Morte do cônjuge) | |

---

## 📝 Instruções

Para cada evento coloque na coluna **Tipo**:
- `POPUP` = aparece como popup com opções de escolha que impactam os stats
- `LOG` = aparece apenas como texto descritivo no feed (sem botões)
- `REMOVER` = excluir completamente

Após preencher, me manda de volta e aplico tudo automaticamente.
