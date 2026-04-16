import json
import os
import csv

def amend_adult():
    with open('data/events/adult_events.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    new_events = [
        {
            "id": "adult_betrayal",
            "phases": ["ADULT"],
            "age_min": 20,
            "age_max": 60,
            "category": "social",
            "weight": 50,
            "conditions": {},
            "text_key": "EVENT_ADULT_BETRAYAL",
            "choices": [
                {
                    "text_key": "CHOICE_FORGIVE",
                    "effects": { "morality": 5, "happiness": -5 },
                    "relationship_effects": { "PARTNER": { "affection": 5 } }
                },
                {
                    "text_key": "CHOICE_BREAKUP",
                    "effects": { "happiness": -10, "health": -3 },
                    "relationship_effects": { "PARTNER": { "affection": -100 } }
                },
                {
                    "text_key": "CHOICE_REVENGE",
                    "effects": { "morality": -10, "happiness": 5, "charisma": 2 },
                    "relationship_effects": { "PARTNER": { "affection": -50 } }
                }
            ]
        },
        {
            "id": "adult_accident",
            "phases": ["ADULT", "ELDER"],
            "age_min": 18,
            "age_max": 90,
            "category": "health",
            "weight": 40,
            "conditions": {},
            "text_key": "EVENT_ADULT_ACCIDENT",
            "choices": [
                {
                    "text_key": "CHOICE_AMBULANCE",
                    "effects": { "health": 10, "happiness": -3 },
                    "money_effect": -1500
                },
                {
                    "text_key": "CHOICE_IGNORE_INJURY",
                    "effects": { "health": -25, "intelligence": -3 }
                }
            ]
        },
        {
            "id": "adult_memed",
            "phases": ["ADULT"],
            "age_min": 18,
            "age_max": 40,
            "category": "social",
            "weight": 30,
            "conditions": {},
            "text_key": "EVENT_ADULT_MEME",
            "choices": [
                {
                    "text_key": "CHOICE_MILK_IT",
                    "effects": { "charisma": 10, "happiness": 5 },
                    "money_effect": 2000
                },
                {
                    "text_key": "CHOICE_DELETE_APP",
                    "effects": { "health": 5, "happiness": -2 }
                }
            ]
        }
    ]
    data['events'].extend(new_events)
    with open('data/events/adult_events.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def amend_teen():
    with open('data/events/teen_events.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    new_events = [
        {
            "id": "teen_possessive",
            "phases": ["TEEN", "ADULT"],
            "age_min": 14,
            "age_max": 25,
            "category": "social",
            "weight": 45,
            "conditions": {},
            "text_key": "EVENT_TEEN_POSSESSIVE",
            "choices": [
                {
                    "text_key": "CHOICE_TALK_IT_OUT",
                    "effects": { "intelligence": 5, "happiness": -2 }
                },
                {
                    "text_key": "CHOICE_FIGHT_BACK",
                    "effects": { "health": -5, "charisma": 5, "morality": -2 }
                },
                {
                    "text_key": "CHOICE_GIVE_IN",
                    "effects": { "happiness": -10, "morality": -3 }
                }
            ]
        },
        {
            "id": "teen_school_fight",
            "phases": ["CHILD", "TEEN"],
            "age_min": 10,
            "age_max": 18,
            "category": "health",
            "weight": 50,
            "conditions": {},
            "text_key": "EVENT_TEEN_FIGHT",
            "choices": [
                {
                    "text_key": "CHOICE_DEFEND_SELF",
                    "effects": { "health": -2, "charisma": 5 },
                    "trait_chance": { "trait": "brave", "chance": 0.2 }
                },
                {
                    "text_key": "CHOICE_RUN_AWAY",
                    "effects": { "health": 2, "charisma": -5 }
                }
            ]
        }
    ]
    data['events'].extend(new_events)
    with open('data/events/teen_events.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def append_texts():
    lines = [
        '\nEVENT_ADULT_BETRAYAL,Your partner was caught kissing someone else!,Você pegou quem você ama no flagra beijando outra pessoa!',
        'EVENT_ADULT_BETRAYAL_DESC,It breaks your heart. What will you do?,Coração partido em mil pedaços. E aí, corno(a) manso(a) ou vai ter vingança?',
        'CHOICE_FORGIVE,Forgive & Reconcile,Perdoar e Reconciliar (Manso)',
        'CHOICE_BREAKUP,Break up immediately,Terminar na hora',
        'CHOICE_REVENGE,Key their car,Riscar o carro inteiro (Vingança)',
        'EVENT_ADULT_ACCIDENT,You fell down the stairs and broke an arm.,Você capotou da escada igual jaca num barranco e quebrou o braço.',
        'EVENT_ADULT_ACCIDENT_DESC,It hurts a lot. Healing system activated.,A dor é infernal. O sistema de cura requer tratamento.',
        'CHOICE_AMBULANCE,Pay for treatment,Pagar o tratamento e curar',
        'CHOICE_IGNORE_INJURY,Rub dirt on it,Passar cuspe e ignorar',
        'EVENT_ADULT_MEME,You did something stupid and became a meme.,Você fez algo estúpido na rua e virou meme no TikTok.',
        'EVENT_ADULT_MEME_DESC,People recognize you everywhere.,Vão te chamar de "Bora Bill" pra sempre.',
        'CHOICE_MILK_IT,Monetize the fame,Monetizar e ficar rico',
        'CHOICE_DELETE_APP,Delete social media,Deletar as redes chorando',
        'EVENT_TEEN_POSSESSIVE,Your date is being extremely possessive and toxic.,Seu par romântico tá agindo igual doido e super possessivo.',
        'EVENT_TEEN_POSSESSIVE_DESC,They check your phone 24/7.,Abrem teu celular enquanto você dorme. E aí?',
        'CHOICE_TALK_IT_OUT,Try to talk it out,Tentar conversar e perdoar',
        'CHOICE_FIGHT_BACK,Fight back verbally,Mandar pra aquele lugar (Brigar)',
        'CHOICE_GIVE_IN,Accept the toxicity,Aceitar a toxidade (Chorar)',
        'EVENT_TEEN_FIGHT,A tough guy challenges you to a street fight.,Um valentão te desafia pra uma briga de rua do nada.',
        'EVENT_TEEN_FIGHT_DESC,Self defense or flight?,Vai usar defesa pessoal ou meter o pé?',
        'CHOICE_DEFEND_SELF,Self Defense (Fight),Mão na cara (Defesa Pessoal)',
        'CHOICE_RUN_AWAY,Run like the wind,Correr igual o Flash',
    ]
    with open('data/localization/texts.csv', 'a', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')

amend_adult()
amend_teen()
append_texts()
