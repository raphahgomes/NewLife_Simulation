extends Node

## AdManager — Central de Anúncios e Compras Embutidas (IAP)

const ADMOB_APP_ID: String = "ca-app-pub-1511076292042912~8991791555"
const REWARDED_UNIT_ID: String = "ca-app-pub-1511076292042912/6581250639"

# Flags de Monetização
var is_admob_available := false
var has_premium := false # Se true, remove banners e pula videos de recompensa

signal ad_loaded
signal ad_failed
signal rewarded_ad_completed(reward_type: String)
signal rewarded_ad_closed
signal premium_purchased

func _ready() -> void:
	if OS.get_name() in ["Windows", "macOS", "Linux", "FreeBSD"]:
		# Build para PC (Steam/Epic) -> Sempre Premium!
		has_premium = true
		print("AdManager: PC Build detectado. Definindo como Premium automaticamente.")

	print("AdManager inicializado com ID: ", ADMOB_APP_ID)
	show_banner()

func show_rewarded_ad(reward_type: String) -> void:
	if has_premium:
		print("O Jogador é VIP! Pulando o anuncio e entregando a recompensa...")
		await get_tree().create_timer(0.2).timeout
		rewarded_ad_completed.emit(reward_type)
		return
		
	print("=== EXIBINDO VIDEO DE ANUNCIO ===")
	await get_tree().create_timer(1.5).timeout
	print("=== VIDEO FINALIZADO ===")
	rewarded_ad_completed.emit(reward_type)

func show_banner() -> void:
	if has_premium:
		return
	print("=== EXIBINDO BANNER NA TELA ===")

func hide_banner() -> void:
	print("=== ESCONDENDO BANNER ===")

func buy_premium() -> void:
	# Aqui no futuro chamaremos a Godot Google Play Billing API usando a chave RSA
	print("=== EFETUANDO COMPRA DO PREMIUM ===")
	has_premium = true
	hide_banner()
	premium_purchased.emit()

