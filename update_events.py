import json
import os

events_to_add = [
    {
        "id": "family_adopted_pet",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "Seus pais adotaram um Pet de surpresa! Talvez ele traga alegria, ou caos...",
        "choices": [{"text_key": "Au/Miau", "effects": {}}]
    },
    {
        "id": "family_healed_depression",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "O ambiente da casa melhorou e a depressão dos seus pais foi curada organicamente.",
        "choices": [{"text_key": "Melhorou", "effects": {}}]
    },
    {
        "id": "family_parent_promotion",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "Graças a noites bem dormidas e sorte, um dos seus pais foi promovido! [+ Dinheiro]",
        "choices": [{"text_key": "Ricos", "effects": {}}]
    },
    {
        "id": "family_miscarriage",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "MISCARRIAGE: Devido ao estresse diário, ocorreu a perda de uma gravidez. O clima desabou.",
        "choices": [{"text_key": "Luto", "effects": {}}]
    },
    {
        "id": "family_new_sibling",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "Sua mãe teve um bebê saudável. Novo irmão/irmã na família!",
        "choices": [{"text_key": "Olha o bebezinho", "effects": {}}]
    },
    {
        "id": "family_abuse_extreme_saved",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "Surtos de Violência Doméstica quase escalaram pra tragédia, mas sorte impediu algo pior. Casa quebrada.",
        "choices": [{"text_key": "Silêncio", "effects": {}}]
    },
    {
        "id": "family_abuse_extreme_arrest",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "VIOLÊNCIA DETIDA: A polícia interviu nas agressões agressivas causadas pelo estresse em casa. Destruição estrutural da família.",
        "choices": [{"text_key": "Trauma severo", "effects": {}}]
    },
    {
        "id": "family_divorce_stress",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "DIVÓRCIO: A família acabou. O peso de aturar um colapso contínuo forçou a separação. Redução drástica de riqueza e casa com apenas 1 pai/mãe.",
        "choices": [{"text_key": "Tudo desmorona", "effects": {}}]
    },
    {
        "id": "family_poverty_work",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "Para fugir de uma falência terrível, arranjaram trabalhos paralelos, esgotando sua própria saúde e estabilidade.",
        "choices": [{"text_key": "Choro baixo", "effects": {}}]
    },
    {
        "id": "baby_poor_health_colic",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "health",
        "weight": 0,
        "conditions": {},
        "text_key": "Sem dinheiro pra comida de qualidade, você teve uma dor fortíssima de cólica, diarreia e espasmos de dor.",
        "choices": [{"text_key": "Aaaaaah!", "effects": {}}]
    },
    {
        "id": "baby_rich_health_cold",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "health",
        "weight": 0,
        "conditions": {},
        "text_key": "Sua família é abastada. Você pegou virose, mas teve os melhores medicamentos antes de escalar a doença.",
        "choices": [{"text_key": "Atchim!", "effects": {}}]
    },
    {
        "id": "baby_random_accident_cured",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "health",
        "weight": 0,
        "conditions": {},
        "text_key": "ACIDENTE: Num dia de azar enorme, você despencou do berço batendo de cabeça. Como a família tinha reservas, foi pro melhor neurocirurgião sem sequelas.",
        "choices": [{"text_key": "Sorte na Riqueza", "effects": {}}]
    },
    {
        "id": "baby_random_accident_poor",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "health",
        "weight": 0,
        "conditions": {},
        "text_key": "ACIDENTE: Queda brutal da escada ou do móvel sem vigias. Pobres para um bom hospital, sua cabecinha sofreu um trauma de dano irreversível de saúde e inteligência.",
        "choices": [{"text_key": "Zumbido...", "effects": {}}]
    },
    {
        "id": "parents_paid_therapy_child",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "health",
        "weight": 0,
        "conditions": {},
        "text_key": "Sendo ricos, a família injetou rios de grana num Psiquiatra Infantil particular pro bebê, diminuindo seu Trauma consideravelmente.",
        "choices": [{"text_key": "Melhorou meu comportamento", "effects": {}}]
    },
    {
        "id": "parents_couple_therapy",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "Pra evitar matar um ao outro, o casal torrou mais de mil dólares em Terapia Intensiva Matrimonial. O estresse caiu... o dinheiro deles sumiu.",
        "choices": [{"text_key": "Trocando farpas no psicanalista", "effects": {}}]
    },
    {
        "id": "pet_mischief_mess",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "Com o ninho em chamas, o Pet doméstico surtou de ansiedade de separação, roendo e destruindo sofás e cortinas. Explodiu de vez a paz de todos.",
        "choices": [{"text_key": "Gritos pra todo lado", "effects": {}}]
    },
    {
        "id": "pet_trainer_hired",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "family",
        "weight": 0,
        "conditions": {},
        "text_key": "Ao focar em adestrar um pet enrrabichado e endiabrado, seus pais queimaram 800 doletas em profissionais cinólogos.",
        "choices": [{"text_key": "Senta... Espera...", "effects": {}}]
    },
    {
        "id": "pet_attacked_and_donated",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "health",
        "weight": 0,
        "conditions": {},
        "text_key": "O Pet te mordeu seriamente na cara por estar louco no ambiente estressante. Pais finalmente adotaram doá-lo para reaver saúde pra ti.",
        "choices": [{"text_key": "Cicatrizes e Dor", "effects": {}}]
    },
    {
        "id": "pet_attacked_retained",
        "phases": ["BABY"],
        "age_min": 0, "age_max": 3,
        "category": "health",
        "weight": 0,
        "conditions": {},
        "text_key": "O Pet te mordeu, machucando e marcando seu trauma. Mas a falta de dinheiro pra cirurgias e o apego ao animal os forçaram a perdoá-lo... menos pra sua perna.",
        "choices": [{"text_key": "Choro agonizante", "effects": {}}]
    }
]

import os
filepath = r"c:\Users\raphr\OneDrive\Documentos\GitHub\NewLife_Simulation\data\events\baby_events.json"

with open(filepath, "r", encoding="utf-8") as f:
    data = json.load(f)

existing_ids = {e["id"] for e in data["events"]}
for ev in events_to_add:
    if ev["id"] not in existing_ids:
        data["events"].append(ev)

with open(filepath, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("JSON BABY EVENTS atualizado com sucesso!")
import re

with open(r'c:\Users\raphr\OneDrive\Documentos\GitHub\NewLife_Simulation\scripts\ui\GameHUD.gd', 'r', encoding='utf-8') as f:
    text = f.read()

# ADD _show_custom_menu OVERLAY HELPER
new_helper = '''
func _show_custom_menu(title: String, subtitle: String, choices: Array) -> void:
\tvar overlay := Control.new()
\toverlay.set_anchors_preset(Control.PRESET_FULL_RECT)

\tvar bg := ColorRect.new()
\tbg.set_anchors_preset(Control.PRESET_FULL_RECT)
\tbg.color = Color(0, 0, 0, 0.5)
\toverlay.add_child(bg)

\tvar panel := PanelContainer.new()
\tpanel.anchor_left = 0.03
\tpanel.anchor_right = 0.97
\tpanel.anchor_top = 0.06
\tpanel.anchor_bottom = 0.94
\tvar panel_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD, 16, 24, 16)
\tpanel.add_theme_stylebox_override("panel", panel_style)
\toverlay.add_child(panel)

\tvar scroll := ScrollContainer.new()
\tscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\tscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
\tpanel.add_child(scroll)

\tvar vbox := VBoxContainer.new()
\tvbox.add_theme_constant_override("separation", 10)
\tvbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\tscroll.add_child(vbox)

\tvar t_lbl := Label.new()
\tt_lbl.text = title
\tt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\tt_lbl.add_theme_font_size_override("font_size", 28)
\tt_lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
\tvbox.add_child(t_lbl)

\tif subtitle != "":
\t\tvar st_lbl := Label.new()
\t\tst_lbl.text = subtitle
\t\tst_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
\t\tst_lbl.add_theme_font_size_override("font_size", 20)
\t\tst_lbl.add_theme_color_override("font_color", ThemeSetup.TEXT_SECONDARY)
\t\tvbox.add_child(st_lbl)

\tvar sep := HSeparator.new()
\tvbox.add_child(sep)

\tfor choice in choices:
\t\tvar btn := Button.new()
\t\tbtn.text = choice["label"]
\t\tbtn.custom_minimum_size = Vector2(0, 68)
\t\tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\t\tvar btn_style := ThemeSetup.make_flat_box(ThemeSetup.BG_CARD_LIGHT, 14, 16, 12)
\t\tbtn.add_theme_stylebox_override("normal", btn_style)
\t\tvar hover_style := ThemeSetup.make_flat_box(ThemeSetup.PRIMARY.darkened(0.3), 14, 16, 12)
\t\tbtn.add_theme_stylebox_override("hover", hover_style)
\t\tbtn.add_theme_font_size_override("font_size", 22)
\t\tbtn.add_theme_color_override("font_color", ThemeSetup.TEXT_PRIMARY)
\t\t
\t\tif choice.has("disabled") and choice["disabled"]:
\t\t\tbtn.disabled = true
\t\t\tbtn.add_theme_color_override("font_color", ThemeSetup.TEXT_HINT)
\t\telse:
\t\t\tvar bound_cb: Callable = choice["action"]
\t\t\tbtn.pressed.connect(func():
\t\t\t\toverlay.queue_free()
\t\t\t\tbound_cb.call()
\t\t\t)
\t\tvbox.add_child(btn)

\tvar sep2 := HSeparator.new()
\tvbox.add_child(sep2)
\t
\tvar btn_close := Button.new()
\tbtn_close.text = "? " + tr("CLOSE")
\tbtn_close.custom_minimum_size = Vector2(0, 56)
\tbtn_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\tvar close_style := ThemeSetup.make_flat_box(Color("#C62828"), 14, 16, 12)
\tbtn_close.add_theme_stylebox_override("normal", close_style)
\tbtn_close.add_theme_font_size_override("font_size", 22)
\tbtn_close.add_theme_color_override("font_color", Color.WHITE)
\tbtn_close.pressed.connect(func(): overlay.queue_free())
\tvbox.add_child(btn_close)

\tbg.gui_input.connect(func(event_input: InputEvent):
\t\tif event_input is InputEventMouseButton and event_input.pressed:
\t\t\toverlay.queue_free()
\t)

\tadd_child(overlay)

'''

text = text.replace('func _get_phase_activities(c: Character) -> Array:', new_helper + '\\nfunc _get_phase_activities(c: Character) -> Array:')

# NOW, instead of "_show_category_actions(cat)" in _show_activities_menu
# we redirect it if the "action_id" is matching a specific behavior, else "cat"

old_btn_connect = '''
\t\t\tvar cat: String = act["category"]
\t\t\tbtn.pressed.connect(func():
\t\t\t\toverlay.queue_free()
\t\t\t\t_show_category_actions(cat)
\t\t\t)
'''

new_btn_connect = '''
\t\t\tvar cat: String = act.get("category", "")
\t\t\tvar act_id: String = act.get("action_id", cat)
\t\t\tbtn.pressed.connect(func():
\t\t\t\toverlay.queue_free()
\t\t\t\t_handle_specific_activity(act_id)
\t\t\t)
'''

text = text.replace(old_btn_connect, new_btn_connect)

# ADD THE _handle_specific_activity method right above _show_category_actions
handler_method = '''
func _handle_specific_activity(act_id: String) -> void:
\tvar c := GameManager.character
\tmatch act_id:
\t\t"school":
\t\t\t_show_custom_menu("?? " + tr("ACT_SCHOOL"), tr("CHOOSE_ACTION"), [
\t\t\t\t{"label": "?? " + tr("ACT_SCHOOL_STUDY_HARD") + " (+Int, -Hap)", "action": func():
\t\t\t\t\tc.intelligence = clampi(c.intelligence + 4, 0, 100)
\t\t\t\t\tc.happiness = clampi(c.happiness - 3, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_STUDY_HARD"), "??")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "?? " + tr("ACT_SCHOOL_SLACK_OFF") + " (-Int, +Hap)", "action": func():
\t\t\t\t\tc.intelligence = clampi(c.intelligence - 3, 0, 100)
\t\t\t\t\tc.happiness = clampi(c.happiness + 4, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_SLACK_OFF"), "??")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "?? " + tr("ACT_SCHOOL_SOCIALIZE") + " (+Soc)", "action": func():
\t\t\t\t\tc.happiness = clampi(c.happiness + 2, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_SCHOOL_SOCIALIZE"), "??")
\t\t\t\t\t_update_display()
\t\t\t\t}
\t\t\t])
\t\t"crime":
\t\t\t_show_custom_menu("?? " + tr("ACT_CRIME"), tr("CHOOSE_ACTION"), [
\t\t\t\t{"label": "??? " + tr("ACT_CRIME_SHOPLIFT"), "action": func():
\t\t\t\t\tc.morality = clampi(c.morality - 5, 0, 100)
\t\t\t\t\tvar success = randf() > 0.4
\t\t\t\t\tif success:
\t\t\t\t\t\tc.money += randi_range(20, 100)
\t\t\t\t\t\t_add_log_entry(tr("LOG_SHOPLIFT_SUCCESS"), "??")
\t\t\t\t\telse:
\t\t\t\t\t\tc.happiness -= 10
\t\t\t\t\t\t_add_log_entry(tr("LOG_SHOPLIFT_CAUGHT"), "??")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "?? " + tr("ACT_CRIME_GRAND_THEFT"), "disabled": c.age < 14, "action": func():
\t\t\t\t\tc.morality = clampi(c.morality - 15, 0, 100)
\t\t\t\t\tvar success = randf() > 0.7
\t\t\t\t\tif success:
\t\t\t\t\t\tc.money += randi_range(1000, 5000)
\t\t\t\t\t\t_add_log_entry(tr("LOG_GTA_SUCCESS"), "??")
\t\t\t\t\telse:
\t\t\t\t\t\tc.happiness -= 30
\t\t\t\t\t\t_add_log_entry(tr("LOG_GTA_CAUGHT"), "??")
\t\t\t\t\t_update_display()
\t\t\t\t}
\t\t\t])
\t\t"health", "gym", "doctor":
\t\t\t_show_custom_menu("?? " + tr("HEALTH"), tr("CHOOSE_ACTION"), [
\t\t\t\t{"label": "?? " + tr("ACT_GYM_WORKOUT") + " ()", "disabled": c.money < 20, "action": func():
\t\t\t\t\tc.money -= 20
\t\t\t\t\tc.health = clampi(c.health + 3, 0, 100)
\t\t\t\t\tc.appearance = clampi(c.appearance + 2, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_GYM_WORKOUT"), "??")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "?? " + tr("ACT_MEDITATE") + " (Free)", "action": func():
\t\t\t\t\tc.health = clampi(c.health + 1, 0, 100)
\t\t\t\t\tc.happiness = clampi(c.happiness + 3, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_MEDITATE"), "??")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "????? " + tr("ACT_DOCTOR_CHECKUP") + " ()", "disabled": c.money < 100, "action": func():
\t\t\t\t\tc.money -= 100
\t\t\t\t\tc.health = clampi(c.health + 10, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_DOCTOR"), "?????")
\t\t\t\t\t_update_display()
\t\t\t\t}
\t\t\t])
\t\t_:
\t\t\t_show_category_actions(act_id)

'''

text = text.replace('func _show_category_actions(category: String) -> void:', handler_method + '\\nfunc _show_category_actions(category: String) -> void:')


# NOW update the _apply_rel_action to handle "talk" and "gift"
old_apply_rel = '''func _apply_rel_action(rel: Relationship, effect: String) -> void:
\tvar c := GameManager.character
\tmatch effect:'''

new_apply_rel = '''func _apply_rel_action(rel: Relationship, effect: String) -> void:
\tvar c := GameManager.character
\tmatch effect:
\t\t"talk":
\t\t\t_show_custom_menu("?? " + tr("REL_TALK") + " - " + rel.person_name, tr("CHOOSE_ACTION"), [
\t\t\t\t{"label": "??? " + tr("REL_TALK_CASUAL") + " (+Affection)", "action": func():
\t\t\t\t\trel.modify_affection(3)
\t\t\t\t\tc.happiness = clampi(c.happiness + 1, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_TALK_CASUAL").replace("{name}", rel.person_name), "??")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "?? " + tr("REL_TALK_DEEP") + " (+Aff, +Respect)", "action": func():
\t\t\t\t\trel.modify_affection(5)
\t\t\t\t\trel.modify_respect(3)
\t\t\t\t\tc.happiness = clampi(c.happiness + 2, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_TALK_DEEP").replace("{name}", rel.person_name), "???")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "?? " + tr("REL_TALK_GOSSIP") + " (+Aff, -Morality)", "action": func():
\t\t\t\t\trel.modify_affection(2)
\t\t\t\t\tc.morality = clampi(c.morality - 3, 0, 100)
\t\t\t\t\t_add_log_entry(tr("LOG_TALK_GOSSIP").replace("{name}", rel.person_name), "??")
\t\t\t\t\t_update_display()
\t\t\t\t}
\t\t\t])
\t\t\treturn
\t\t"gift":
\t\t\t_show_custom_menu("?? " + tr("REL_GIFT") + " - " + rel.person_name, tr("CHOOSE_GIFT"), [
\t\t\t\t{"label": "?? " + tr("GIFT_CHOCOLATE") + " ()", "disabled": c.money < 15, "action": func():
\t\t\t\t\tc.money -= 15
\t\t\t\t\trel.modify_affection(5)
\t\t\t\t\t_add_log_entry(tr("LOG_GIFT").replace("{name}", rel.person_name).replace("{item}", tr("GIFT_CHOCOLATE")), "??")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "?? " + tr("GIFT_BOOK") + " ()", "disabled": c.money < 30, "action": func():
\t\t\t\t\tc.money -= 30
\t\t\t\t\trel.modify_affection(8)
\t\t\t\t\t_add_log_entry(tr("LOG_GIFT").replace("{name}", rel.person_name).replace("{item}", tr("GIFT_BOOK")), "??")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "? " + tr("GIFT_WATCH") + " ()", "disabled": c.money < 200, "action": func():
\t\t\t\t\tc.money -= 200
\t\t\t\t\trel.modify_affection(20)
\t\t\t\t\t_add_log_entry(tr("LOG_GIFT").replace("{name}", rel.person_name).replace("{item}", tr("GIFT_WATCH")), "?")
\t\t\t\t\t_update_display()
\t\t\t\t},
\t\t\t\t{"label": "?? " + tr("GIFT_CAR") + " ()", "disabled": c.money < 25000, "action": func():
\t\t\t\t\tc.money -= 25000
\t\t\t\t\trel.modify_affection(100)
\t\t\t\t\t_add_log_entry(tr("LOG_GIFT").replace("{name}", rel.person_name).replace("{item}", tr("GIFT_CAR")), "??")
\t\t\t\t\t_update_display()
\t\t\t\t}
\t\t\t])
\t\t\treturn'''

text = text.replace(old_apply_rel, new_apply_rel)

with open(r'c:\Users\raphr\OneDrive\Documentos\GitHub\NewLife_Simulation\scripts\ui\GameHUD.gd', 'w', encoding='utf-8') as f:
    f.write(text)
